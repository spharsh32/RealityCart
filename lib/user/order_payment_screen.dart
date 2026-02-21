import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reality_cart/providers/cart_provider.dart';
import 'package:reality_cart/user/payment_method_screen.dart';
import 'package:reality_cart/user/order_confirmation_screen.dart';
import 'package:reality_cart/services/fcm_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/cart_item.dart';

class OrderPaymentScreen extends StatefulWidget {
  final String selectedAddressId;
  final List<CartItem> items;
  final double subtotal;
  final double tax;
  final double total;
  final bool isFromCart;

  const OrderPaymentScreen({
    super.key,
    required this.selectedAddressId,
    required this.items,
    required this.subtotal,
    required this.tax,
    required this.total,
    required this.isFromCart,
  });

  @override
  State<OrderPaymentScreen> createState() => _OrderPaymentScreenState();
}

class _OrderPaymentScreenState extends State<OrderPaymentScreen> {
  String _selectedMethodType = 'UPI'; // Default method
  String? _selectedCardId;
  bool _isProcessing = false;

  Future<void> _placeOrder() async {
    if (_selectedMethodType == 'Card' && _selectedCardId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a saved card")),
      );
      return;
    }

    setState(() => _isProcessing = true);

    final user = FirebaseAuth.instance.currentUser;

    try {
      // Use a Transaction to ensure stock is available and update it atomically
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        // 1. Read all product docs first (Requirement for Firestore transactions)
        List<DocumentSnapshot> productSnapshots = [];
        for (var item in widget.items) {
          final doc = await transaction.get(FirebaseFirestore.instance.collection('products').doc(item.id));
          productSnapshots.add(doc);
        }

        // 2. Validate Stock
        for (int i = 0; i < widget.items.length; i++) {
          final item = widget.items[i];
          final snapshot = productSnapshots[i];

          if (!snapshot.exists) {
             throw Exception("Product ${item.name} no longer exists!");
          }

          final currentStock = (snapshot.data() as Map<String, dynamic>)['stock'] as int? ?? 0;
          if (currentStock < item.quantity) {
            throw Exception("Insufficient stock for ${item.name}. Only $currentStock left.");
          }
        }

        // 3. Perform Updates (Decrement Stock, Increment Sales)
        for (int i = 0; i < widget.items.length; i++) {
          final item = widget.items[i];
          final snapshot = productSnapshots[i];
          final currentStock = (snapshot.data() as Map<String, dynamic>)['stock'] as int? ?? 0;
          final currentSold = (snapshot.data() as Map<String, dynamic>)['soldCount'] as int? ?? 0;

          transaction.update(snapshot.reference, {
            'stock': currentStock - item.quantity,
            'soldCount': currentSold + item.quantity,
          });
        }

        // 4. Create Order
        final orderRef = FirebaseFirestore.instance.collection('orders').doc();
        final orderData = {
          'userId': user!.uid,
          'items': widget.items.map((item) => {
            'productId': item.id,
            'name': item.name,
            'price': item.price,
            'quantity': item.quantity,
            'size': item.size,
          }).toList(),
          'totalAmount': widget.total,
          'addressId': widget.selectedAddressId,
          'paymentMethod': _selectedMethodType,
          'paymentId': _selectedMethodType == 'Card' ? _selectedCardId : null,
          'status': 'Processing',
          'createdAt': FieldValue.serverTimestamp(),
        };

        transaction.set(orderRef, orderData);
        
        // Return order ID for post-transaction use
        return orderRef.id;
      }).then((orderId) async {
        // Transaction Successful - Post-processing
        if (mounted) {
          if (widget.isFromCart) {
            Provider.of<CartProvider>(context, listen: false).clearCart();
          }
          
          await FCMService.showLocalNotification(
            "Order Placed Successfully!",
            "Your order for ₹${widget.total.toStringAsFixed(2)} has been placed.",
          );

          await FCMService.saveLocalNotificationToFirestore(
            "Order Placed Successfully!",
            "Your order for ₹${widget.total.toStringAsFixed(2)} has been placed.",
            "order",
          );

          await FCMService.sendNotificationToAdmin(
            "New Order Received",
            "Order #${orderId.toString().substring(0, 8)} has been placed by ${user?.displayName ?? 'a user'}.",
            "order",
          );

          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => OrderConfirmationScreen(
                orderId: orderId.toString(),
                totalAmount: widget.total,
              ),
            ),
          );
        }
      });

    } catch (e) {
      if (mounted) {
        String errorMessage = "Error placing order";
        if (e.toString().contains("Insufficient stock")) {
          // Extract specific message
          errorMessage = e.toString().replaceAll("Exception:", "").trim();
        } else {
           errorMessage = "Error: ${e.toString()}";
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Payment Options", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: _isProcessing
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  _buildPaymentOptions(user),
                  const Divider(thickness: 8, height: 8),
                  _buildPriceDetails(),
                ],
              ),
            ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildPaymentOptions(User? user) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Text("Select Payment Method", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          
          // UPI
          _buildMethodTile(
            title: "UPI",
            subtitle: "Google Pay, PhonePe, Paytm",
            icon: Icons.account_balance_wallet_outlined,
            value: "UPI",
          ),
          
          // Cards (Saved Cards Section)
          _buildCardSection(user),

          // Net Banking
          _buildMethodTile(
            title: "Net Banking",
            subtitle: "All Indian Banks",
            icon: Icons.account_balance_outlined,
            value: "NetBanking",
          ),

          // Cash on Delivery
          _buildMethodTile(
            title: "Cash on Delivery",
            subtitle: "Pay when you receive",
            icon: Icons.money_outlined,
            value: "COD",
          ),
        ],
      ),
    );
  }

  Widget _buildMethodTile({required String title, required String subtitle, required IconData icon, required String value}) {
    return RadioListTile<String>(
      value: value,
      groupValue: _selectedMethodType,
      onChanged: (val) => setState(() {
        _selectedMethodType = val!;
        _selectedCardId = null; // Clear card selection if switching method
      }),
      activeColor: const Color(0xFFFB8C00),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle),
      secondary: Icon(icon, color: const Color(0xFFFB8C00)),
    );
  }

  Widget _buildCardSection(User? user) {
    final theme = Theme.of(context);
    final isCardSelected = _selectedMethodType == 'Card';

    return Column(
      children: [
        RadioListTile<String>(
          value: 'Card',
          groupValue: _selectedMethodType,
          onChanged: (val) => setState(() => _selectedMethodType = val!),
          activeColor: const Color(0xFFFB8C00),
          title: const Text("Credit / Debit / ATM Card", style: TextStyle(fontWeight: FontWeight.bold)),
          subtitle: const Text("Add or use saved cards"),
          secondary: const Icon(Icons.credit_card, color: Color(0xFFFB8C00)),
        ),
        if (isCardSelected)
          Padding(
            padding: const EdgeInsets.only(left: 50, right: 16),
            child: Column(
              children: [
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('users').doc(user!.uid).collection('payment_methods').snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return TextButton.icon(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PaymentMethodScreen())),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text("Add New Card"),
                        style: TextButton.styleFrom(foregroundColor: const Color(0xFFFB8C00)),
                      );
                    }
                    
                    final methods = snapshot.data!.docs;
                    if (_selectedCardId == null && methods.isNotEmpty) {
                      _selectedCardId = methods.first.id;
                    }

                    return Column(
                      children: [
                        ...methods.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          return RadioListTile<String>(
                            value: doc.id,
                            groupValue: _selectedCardId,
                            onChanged: (val) => setState(() {
                              _selectedCardId = val;
                              _selectedMethodType = 'Card';
                            }),
                            contentPadding: EdgeInsets.zero,
                            title: Text(data['type'] ?? 'Visa', style: const TextStyle(fontSize: 14)),
                            subtitle: Text(data['number'] ?? '**** 1234', style: const TextStyle(fontSize: 12)),
                            activeColor: const Color(0xFFFB8C00),
                          );
                        }).toList(),
                        TextButton.icon(
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PaymentMethodScreen())),
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text("Add Another Card"),
                          style: TextButton.styleFrom(foregroundColor: const Color(0xFFFB8C00)),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildPriceDetails() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Price Details", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _priceRow("Price (${widget.items.length} items)", "₹${widget.subtotal.toStringAsFixed(2)}"),
          _priceRow("Delivery Fee", "FREE", color: Colors.green),
          _priceRow("Tax (5%)", "₹${widget.tax.toStringAsFixed(2)}"),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(thickness: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Total Amount", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text("₹${widget.total.toStringAsFixed(2)}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _priceRow(String label, String value, {Color? color}) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 14, color: theme.textTheme.bodyMedium?.color)),
          Text(value, style: TextStyle(fontSize: 14, color: color ?? theme.textTheme.bodyMedium?.color, fontWeight: color != null ? FontWeight.bold : null)),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border(top: BorderSide(color: theme.dividerColor.withOpacity(0.1))),
      ),
      child: Row(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("₹${widget.total.toStringAsFixed(2)}", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.textTheme.titleLarge?.color)),
              const Text("View Details", style: TextStyle(color: Color(0xFFFB8C00), fontSize: 12, fontWeight: FontWeight.w500)),
            ],
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: _placeOrder,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFB8C00),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              elevation: 0,
            ),
            child: const Text("PLACE ORDER", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

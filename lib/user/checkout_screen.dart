import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reality_cart/providers/cart_provider.dart';
import 'package:reality_cart/user/shipping_address_screen.dart';
import 'package:reality_cart/services/fcm_service.dart';
import 'package:reality_cart/user/order_payment_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/cart_item.dart';
import 'package:reality_cart/l10n/app_localizations.dart';
import 'package:reality_cart/widgets/translated_text.dart';

class CheckoutScreen extends StatefulWidget {
  final List<CartItem>? checkoutItems;
  const CheckoutScreen({super.key, this.checkoutItems});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  String? _selectedAddressId;

  List<CartItem> get _items {
    if (widget.checkoutItems != null) return widget.checkoutItems!;
    return Provider.of<CartProvider>(context, listen: false).cartItems;
  }

  double get _subtotal {
    double total = 0.0;
    for (var item in _items) {
      total += item.price * item.quantity;
    }
    return total;
  }

  double get _tax => _subtotal * 0.05;
  double get _total => _subtotal + _tax;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.orderSummary, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. Order Items Section
            _buildItemsSection(),
            const Divider(thickness: 8, height: 8),

            // 2. Delivery Address Section
            _buildAddressSection(user),
            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildItemsSection() {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("${_items.length} ${AppLocalizations.of(context)!.items}", style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ..._items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Container(
                  width: 60, height: 60,
                  decoration: BoxDecoration(
                    color: theme.disabledColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.shopping_bag_outlined, color: Colors.grey),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TranslatedText(item.name, style: const TextStyle(fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text("${AppLocalizations.of(context)!.qty}: ${item.quantity} | ${AppLocalizations.of(context)!.size}: ${item.size}", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      Text("₹${item.price.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildAddressSection(User? user) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(user!.uid).collection('addresses').snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        final hasAddress = docs.isNotEmpty;

        if (hasAddress && _selectedAddressId == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            setState(() => _selectedAddressId = docs.first.id);
          });
        }

        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(AppLocalizations.of(context)!.deliverTo, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  TextButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ShippingAddressScreen())),
                    child: Text(hasAddress ? AppLocalizations.of(context)!.change : AppLocalizations.of(context)!.addAddress, style: const TextStyle(color: Color(0xFFFB8C00))),
                  ),
                ],
              ),
              if (!hasAddress)
                Text(AppLocalizations.of(context)!.noAddressSaved, style: const TextStyle(color: Colors.grey))
              else
                ...docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return RadioListTile<String>(
                    value: doc.id,
                    groupValue: _selectedAddressId,
                    onChanged: (val) => setState(() => _selectedAddressId = val),
                    contentPadding: EdgeInsets.zero,
                    title: Text(data['name'] ?? 'Home', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text("${data['address']}, ${data['city']}, ${data['state']} - ${data['zip']}"),
                    activeColor: const Color(0xFFFB8C00),
                  );
                }).toList(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBottomBar() {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border(top: BorderSide(color: theme.dividerColor)),
      ),
      child: Row(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("₹${_total.toStringAsFixed(2)}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text(AppLocalizations.of(context)!.orderSummary, style: const TextStyle(color: Color(0xFFFB8C00), fontSize: 12, fontWeight: FontWeight.w500)),
            ],
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: () {
              if (_selectedAddressId == null) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select an address")));
                return;
              }
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => OrderPaymentScreen(
                    selectedAddressId: _selectedAddressId!,
                    items: _items,
                    subtotal: _subtotal,
                    tax: _tax,
                    total: _total,
                    isFromCart: widget.checkoutItems == null,
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFB8C00),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              elevation: 0,
            ),
            child: Text(AppLocalizations.of(context)!.continueText, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

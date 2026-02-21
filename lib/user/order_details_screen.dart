import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class OrderDetailsScreen extends StatelessWidget {
  final String orderId;
  final Map<String, dynamic> orderData;

  const OrderDetailsScreen({
    super.key,
    required this.orderId,
    required this.orderData,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = orderData['status'] ?? 'Processing';
    final items = (orderData['items'] as List<dynamic>?) ?? [];
    final totalAmount = orderData['totalAmount'] ?? 0.0;
    
    String formattedDate = "N/A";
    if (orderData['createdAt'] != null) {
      DateTime date = (orderData['createdAt'] as Timestamp).toDate();
      formattedDate = DateFormat('MMM dd, yyyy - hh:mm a').format(date);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Order Details", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              color: _getStatusColor(status).withOpacity(0.1),
              child: Column(
                children: [
                  Text(
                    "Status: $status",
                    style: TextStyle(
                      color: _getStatusColor(status),
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Order ID: #${orderId.toUpperCase()}",
                    style: TextStyle(color: theme.textTheme.bodySmall?.color),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle(context, "Order Information"),
                  _buildInfoRow(context, "Date", formattedDate),
                  _buildInfoRow(context, "Payment", orderData['paymentMethod'] ?? "N/A"),
                  
                  const Divider(height: 40),
                  
                  _buildSectionTitle(context, "Shipping Address"),
                  FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('users')
                        .doc(orderData['userId'])
                        .collection('addresses')
                        .doc(orderData['addressId'])
                        .get(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Text("Loading address...");
                      }
                      if (!snapshot.hasData || !snapshot.data!.exists) {
                        return const Text("Address not found");
                      }
                      final addr = snapshot.data!.data() as Map<String, dynamic>;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(addr['name'] ?? "", style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text("${addr['address']}, ${addr['city']}"),
                          Text("${addr['state']} - ${addr['zip']}"),
                          Text("Phone: ${addr['phone']}"),
                        ],
                      );
                    },
                  ),

                  const Divider(height: 40),

                  _buildSectionTitle(context, "Items"),
                  ...items.map((item) {
                    final data = item as Map<String, dynamic>;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          Container(
                            width: 50, height: 50,
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
                                Text(data['name'] ?? "", style: const TextStyle(fontWeight: FontWeight.w500)),
                                Text("Qty: ${data['quantity']} | Size: ${data['size']}", style: TextStyle(color: theme.hintColor, fontSize: 12)),
                              ],
                            ),
                          ),
                          Text("₹${(data['price'] * data['quantity']).toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    );
                  }).toList(),

                  const Divider(height: 40),

                  _buildSectionTitle(context, "Price Details"),
                  _buildPriceRow("Price Summary", "₹${(totalAmount / 1.05).toStringAsFixed(2)}"),
                  _buildPriceRow("Tax (5%)", "₹${(totalAmount - (totalAmount / 1.05)).toStringAsFixed(2)}"),
                  _buildPriceRow("Delivery Fee", "FREE", isFree: true),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Total Amount", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      Text("₹${totalAmount.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFFFB8C00))),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Theme.of(context).hintColor)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, String value, {bool isFree = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: TextStyle(color: isFree ? Colors.green : null, fontWeight: isFree ? FontWeight.bold : null)),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Processing': return Colors.orange;
      case 'Shipped': return Colors.blue;
      case 'Delivered': return Colors.green;
      case 'Cancelled': return Colors.red;
      default: return Colors.grey;
    }
  }
}

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:reality_cart/widgets/translated_text.dart';
import 'package:reality_cart/l10n/app_localizations.dart';

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
        title: Text(AppLocalizations.of(context)!.orderDetails, style: const TextStyle(fontWeight: FontWeight.bold)),
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
                    "${AppLocalizations.of(context)!.status}: $status",
                    style: TextStyle(
                      color: _getStatusColor(status),
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${AppLocalizations.of(context)!.orderId}: #${orderId.toUpperCase()}",
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
                  _buildSectionTitle(context, AppLocalizations.of(context)!.orderInformation),
                  _buildInfoRow(context, AppLocalizations.of(context)!.date, formattedDate),
                  _buildInfoRow(context, AppLocalizations.of(context)!.payment, orderData['paymentMethod'] ?? "N/A"),
                  
                  const Divider(height: 40),
                  
                  _buildSectionTitle(context, AppLocalizations.of(context)!.shippingAddress),
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
                          Text("${AppLocalizations.of(context)!.phone}: ${addr['phone']}"),
                        ],
                      );
                    },
                  ),

                  const Divider(height: 40),

                  _buildSectionTitle(context, AppLocalizations.of(context)!.items),
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
                                TranslatedText(data['name'] ?? "", style: const TextStyle(fontWeight: FontWeight.w500)),
                                Text("${AppLocalizations.of(context)!.qty}: ${data['quantity']} | ${AppLocalizations.of(context)!.size}: ${data['size']}", style: TextStyle(color: theme.hintColor, fontSize: 12)),
                              ],
                            ),
                          ),
                          Text("₹${(data['price'] * data['quantity']).toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    );
                  }).toList(),

                  const Divider(height: 40),

                  _buildSectionTitle(context, AppLocalizations.of(context)!.priceDetails),
                  _buildPriceRow(AppLocalizations.of(context)!.priceSummary, "₹${(totalAmount / 1.05).toStringAsFixed(2)}"),
                  _buildPriceRow("${AppLocalizations.of(context)!.tax} (5%)", "₹${(totalAmount - (totalAmount / 1.05)).toStringAsFixed(2)}"),
                  _buildPriceRow(AppLocalizations.of(context)!.deliveryFee, AppLocalizations.of(context)!.freeDelivery, isFree: true),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(AppLocalizations.of(context)!.totalAmount, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
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

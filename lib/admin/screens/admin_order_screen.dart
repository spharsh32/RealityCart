import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:reality_cart/admin/screens/admin_home_screen.dart';
import 'package:reality_cart/widgets/translated_text.dart';
import 'package:reality_cart/services/fcm_service.dart';
import 'package:intl/intl.dart';
import 'package:reality_cart/l10n/app_localizations.dart';

class AdminOrderScreen extends StatelessWidget {
  const AdminOrderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.manageOrders, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          backgroundColor: const Color(0xFFFB8C00),
          iconTheme: const IconThemeData(color: Colors.white),
          elevation: 0,
          bottom: TabBar(
            isScrollable: true,
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(text: AppLocalizations.of(context)!.all),
              Tab(text: AppLocalizations.of(context)!.pending),
              Tab(text: AppLocalizations.of(context)!.shipped),
              Tab(text: AppLocalizations.of(context)!.delivered),
              Tab(text: AppLocalizations.of(context)!.cancelled),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            OrderList(status: 'All'),
            OrderList(status: 'Pending'),
            OrderList(status: 'Shipped'),
            OrderList(status: 'Delivered'),
            OrderList(status: 'Cancelled'),
          ],
        ),
      ),
    );
  }
}

class OrderList extends StatelessWidget {
  final String status;
  const OrderList({super.key, required this.status});

  String _getLocalizedStatus(BuildContext context, String statusKey) {
    switch (statusKey) {
      case 'Pending': return AppLocalizations.of(context)!.pending;
      case 'Processing': return AppLocalizations.of(context)!.processing;
      case 'Shipped': return AppLocalizations.of(context)!.shipped;
      case 'Delivered': return AppLocalizations.of(context)!.delivered;
      case 'Cancelled': return AppLocalizations.of(context)!.cancelled;
      default: return statusKey;
    }
  }

  Future<void> _updateOrderStatus(BuildContext context, String orderId, String currentStatus) async {
    final theme = Theme.of(context);
    String? newStatus = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.cardColor,
        title: Text(AppLocalizations.of(context)!.updateOrderStatus),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['Processing', 'Shipped', 'Delivered', 'Cancelled'].map((status) {
            return ListTile(
              title: Text(_getLocalizedStatus(context, status)),
              onTap: () => Navigator.pop(context, status),
              selected: status == currentStatus,
              selectedColor: const Color(0xFFFB8C00),
            );
          }).toList(),
        ),
      ),
    );

    if (newStatus != null && newStatus != currentStatus) {
      try {
        final orderDoc = await FirebaseFirestore.instance.collection('orders').doc(orderId).get();
        final userId = orderDoc.data()?['userId'];

        await FirebaseFirestore.instance.collection('orders').doc(orderId).update({
          'status': newStatus,
        });

        if (userId != null) {
          await FCMService.sendNotificationToUser(
            userId,
            "Order Status Updated",
            "Your order #${orderId.substring(0, 8)} status is now '$newStatus'.",
            "order",
          );
        }
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("${AppLocalizations.of(context)!.orderStatusUpdated}${_getLocalizedStatus(context, newStatus)}")),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("${AppLocalizations.of(context)!.errorUpdatingStatus}$e")),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    Query query = FirebaseFirestore.instance.collection('orders').orderBy('createdAt', descending: true);
    
    if (status != 'All') {
      if (status == 'Pending') {
         // Maybe include Processing in Pending tab?
         // strict filtering for now
         query = query.where('status', whereIn: ['Pending', 'Processing']);
      } else {
         query = query.where('status', isEqualTo: status);
      }
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final orders = snapshot.data?.docs ?? [];

        if (orders.isEmpty) {
          return Center(
            child: Text(
              AppLocalizations.of(context)!.noOrdersFoundStatus,
              style: TextStyle(color: theme.hintColor),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(15),
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final orderDoc = orders[index];
            final orderData = orderDoc.data() as Map<String, dynamic>;
            final orderId = orderDoc.id;
            final statusCtx = orderData['status'] ?? 'Pending';
            final totalAmount = orderData['totalAmount'] ?? 0.0;
            final items = (orderData['items'] as List<dynamic>?) ?? [];
            final Timestamp? createdAt = orderData['createdAt'];
            final dateStr = createdAt != null ? DateFormat('MMM dd, yyyy').format(createdAt.toDate()) : 'N/A';

            return Card(
              elevation: 0,
              margin: const EdgeInsets.only(bottom: 15),
              color: theme.cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
                side: BorderSide(color: theme.dividerColor.withOpacity(0.1)),
              ),
              child: Theme(
                data: theme.copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFFFB8C00).withOpacity(0.1),
                    child: const Icon(Icons.shopping_bag, color: Color(0xFFFB8C00)),
                  ),
                  title: Text(
                    "${AppLocalizations.of(context)!.order} #${orderId.substring(0, 5)}",
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(dateStr, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      Text(
                        _getLocalizedStatus(context, statusCtx),
                        style: TextStyle(
                          color: _getStatusColor(statusCtx),
                          fontWeight: FontWeight.w500,
                          fontSize: 12
                        ),
                      ),
                    ],
                  ),
                  iconColor: const Color(0xFFFB8C00),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(15),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Divider(color: theme.dividerColor.withOpacity(0.2)),
                          Text(
                            AppLocalizations.of(context)!.itemsLabel,
                            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          ...items.map((item) {
                            final data = item as Map<String, dynamic>;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Row(
                                      children: [
                                        Text("${data['quantity']}x ", style: const TextStyle(fontSize: 13)),
                                        Expanded(
                                          child: TranslatedText(
                                            data['name'] ?? 'Unknown',
                                            style: const TextStyle(fontSize: 13),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Text(" (${data['size'] ?? 'std'})", style: const TextStyle(fontSize: 13)),
                                      ],
                                    ),
                                  ),
                                  Text("₹${data['price']}", style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            );
                          }).toList(),
                          const SizedBox(height: 15),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                AppLocalizations.of(context)!.totalAmountLabel,
                                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                "₹${totalAmount.toStringAsFixed(2)}",
                                style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 18),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () => _updateOrderStatus(context, orderId, statusCtx),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  child: Text(AppLocalizations.of(context)!.updateStatusBtn),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () {
                                     // TODO: Navigate to Order Detail Screen if complex logic is needed
                                     // For now, this expansion tile serves as detail
                                     ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.invoiceComingSoon)));
                                  },
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: Color(0xFFFB8C00)),
                                    foregroundColor: const Color(0xFFFB8C00),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  child: Text(AppLocalizations.of(context)!.invoiceBtn),
                                ),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
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

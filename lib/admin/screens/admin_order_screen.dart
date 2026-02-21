import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:reality_cart/services/fcm_service.dart';
import 'package:intl/intl.dart';

class AdminOrderScreen extends StatelessWidget {
  const AdminOrderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Manage Orders", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          backgroundColor: const Color(0xFFFB8C00),
          iconTheme: const IconThemeData(color: Colors.white),
          elevation: 0,
          bottom: const TabBar(
            isScrollable: true,
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(text: "All"),
              Tab(text: "Pending"),
              Tab(text: "Shipped"),
              Tab(text: "Delivered"),
              Tab(text: "Cancelled"),
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

  Future<void> _updateOrderStatus(BuildContext context, String orderId, String currentStatus) async {
    final theme = Theme.of(context);
    String? newStatus = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.cardColor,
        title: const Text("Update Order Status"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['Processing', 'Shipped', 'Delivered', 'Cancelled'].map((status) {
            return ListTile(
              title: Text(status),
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
            SnackBar(content: Text("Order status updated to $newStatus")),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error updating status: $e")),
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
              "No $status orders found",
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
                    "Order #${orderId.substring(0, 5)}",
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(dateStr, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      Text(
                        statusCtx,
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
                            "Items:",
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
                                  Expanded(child: Text("${data['quantity']}x ${data['name']} (${data['size'] ?? 'std'})", style: const TextStyle(fontSize: 13))),
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
                                "Total Amount:",
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
                                  child: const Text("Update Status"),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () {
                                     // TODO: Navigate to Order Detail Screen if complex logic is needed
                                     // For now, this expansion tile serves as detail
                                     ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Invoice generation coming soon!")));
                                  },
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: Color(0xFFFB8C00)),
                                    foregroundColor: const Color(0xFFFB8C00),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  child: const Text("Invoice"),
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

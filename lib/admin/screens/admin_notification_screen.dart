import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reality_cart/providers/admin_notification_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:reality_cart/l10n/app_localizations.dart';

class AdminNotificationScreen extends StatefulWidget {
  const AdminNotificationScreen({super.key});

  @override
  State<AdminNotificationScreen> createState() => _AdminNotificationScreenState();
}

class _AdminNotificationScreenState extends State<AdminNotificationScreen> {
  @override
  void initState() {
    super.initState();
    // Mark all as read when user opens the screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AdminNotificationProvider>(context, listen: false).markAllAsRead();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    const brandOrange = Color(0xFFFB8C00);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.notificationsTitle, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: brandOrange,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('admin_notifications')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text("${AppLocalizations.of(context)!.errorMsg}${snapshot.error}"));
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_off_outlined,
                    size: 80,
                    color: theme.disabledColor.withOpacity(0.3),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    AppLocalizations.of(context)!.noNotifications,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.textTheme.bodySmall?.color,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final bool isRead = data['isRead'] ?? false;

              return Dismissible(
                key: Key(doc.id),
                direction: DismissDirection.endToStart,
                onDismissed: (direction) {
                  doc.reference.delete();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(AppLocalizations.of(context)!.notificationDismissed)),
                  );
                },
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                child: Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  elevation: 0,
                  color: isRead ? theme.cardColor : brandOrange.withOpacity(0.05),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: isRead ? theme.dividerColor.withOpacity(0.1) : brandOrange.withOpacity(0.2),
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(15),
                    leading: CircleAvatar(
                      backgroundColor: _getIconColor(data['type']).withOpacity(0.2),
                      child: Icon(
                        _getIcon(data['type']),
                        color: _getIconColor(data['type']),
                      ),
                    ),
                    title: Text(
                      data['title'] ?? '',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 5),
                        Text(
                          data['body'] ?? '',
                          style: theme.textTheme.bodyMedium,
                        ),
                        // Timestamp could be added here if needed
                      ],
                    ),
                    onTap: () {
                         if (!isRead) doc.reference.update({'isRead': true});
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  IconData _getIcon(String? type) {
    switch (type) {
      case 'order':
        return Icons.shopping_bag;
      case 'stock':
        return Icons.inventory;
      case 'user':
        return Icons.person_add;
      case 'system':
        return Icons.settings;
      default:
        return Icons.notifications;
    }
  }

  Color _getIconColor(String? type) {
    switch (type) {
      case 'order':
        return Colors.blue;
      case 'stock':
        return Colors.red;
      case 'user':
        return Colors.green;
      case 'system':
        return Colors.grey;
      default:
        return const Color(0xFFFB8C00);
    }
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reality_cart/providers/notification_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:reality_cart/l10n/app_localizations.dart';
import 'package:reality_cart/widgets/translated_text.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final _user = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const brandOrange = Color(0xFFFB8C00);

    if (_user == null) {
      return Scaffold(body: Center(child: Text(AppLocalizations.of(context)!.pleaseLoginToSeeNotifications)));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.notifications, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: brandOrange,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all, color: Colors.white),
            tooltip: AppLocalizations.of(context)!.markAllAsRead,
            onPressed: () async {
              final batch = FirebaseFirestore.instance.batch();
              final snapshots = await FirebaseFirestore.instance
                  .collection('users')
                  .doc(_user!.uid)
                  .collection('notifications')
                  .where('isRead', isEqualTo: false)
                  .get();
              
              for (var doc in snapshots.docs) {
                batch.update(doc.reference, {'isRead': true});
              }
              await batch.commit();
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('global_notifications')
            .orderBy('createdAt', descending: true)
            .limit(20) // Limit global to recent
            .snapshots(),
        builder: (context, globalSnapshot) {
          if (globalSnapshot.hasError) return Center(child: Text("Error: ${globalSnapshot.error}"));
          
          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(_user!.uid)
                .collection('notifications')
                .orderBy('createdAt', descending: true)
                .limit(50)
                .snapshots(),
            builder: (context, userSnapshot) {
              if (userSnapshot.hasError) return Center(child: Text("Error: ${userSnapshot.error}"));
              
              if (globalSnapshot.connectionState == ConnectionState.waiting && 
                  userSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final globalDocs = globalSnapshot.data?.docs ?? [];
              final userDocs = userSnapshot.data?.docs ?? [];

              // Combine and sort
              List<QueryDocumentSnapshot> allDocs = [...globalDocs, ...userDocs];
              
              allDocs.sort((a, b) {
                Timestamp t1 = a['createdAt'] ?? Timestamp.now();
                Timestamp t2 = b['createdAt'] ?? Timestamp.now();
                return t2.compareTo(t1); // Descending
              });

              if (allDocs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_off_outlined, size: 80, color: theme.disabledColor.withOpacity(0.2)),
                      const SizedBox(height: 10),
                      Text(AppLocalizations.of(context)!.noNotifications, style: TextStyle(color: theme.hintColor, fontSize: 18)),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(10),
                itemCount: allDocs.length,
                itemBuilder: (context, index) {
                  final doc = allDocs[index];
                  final data = doc.data() as Map<String, dynamic>;
                  // Global notifications might not have 'isRead' per user easily without subcollection. 
                  // For now, global notifications are always "unread" or just normal.
                  // Or we can check if it's in user docs directly.
                   // Logic: If doc is from user collection, use its isRead. 
                   // If global, maybe we don't track read state per user yet (simplification).
                  
                  bool isRead = false;
                  bool isGlobal = doc.reference.parent.id == 'global_notifications';

                  if (!isGlobal) {
                    isRead = data['isRead'] ?? false;
                  } else {
                     // For global, we could assume read if clicked? 
                     // For now, let's just make them appear as unread or read based on simple local state? 
                     // Or just always show them.
                     // Let's assume global are always "highlighted" or just standard.
                     isRead = true; // Treating global as read to avoid complexity of tracking read state for every user on global doc.
                  }

                  return Dismissible(
                    key: Key(doc.id),
                    direction: DismissDirection.endToStart,
                    onDismissed: (direction) {
                       if (!isGlobal) {
                         doc.reference.delete();
                       } else {
                         // Can't delete global notification for everyone.
                         // Just hide it locally? 
                         // For now, disable dismissal for global or just show snackbar "Can't delete global".
                       }
                    },
                    confirmDismiss: (direction) async {
                      if (isGlobal) {
                         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.cannotDeleteGlobalAnnouncements)));
                         return false;
                      }
                      return true;
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
                        side: BorderSide(color: isRead ? theme.dividerColor.withOpacity(0.1) : brandOrange.withOpacity(0.2)),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(15),
                        leading: CircleAvatar(
                          backgroundColor: _getIconColor(data['type']).withOpacity(0.2),
                          child: Icon(_getIcon(data['type']), color: _getIconColor(data['type'])),
                        ),
                        title: Text(
                          data['title'] ?? "",
                          style: TextStyle(fontWeight: isRead ? FontWeight.normal : FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 5),
                            TranslatedText(data['body'] ?? ""),
                            const SizedBox(height: 5),
                            Text(
                              data['createdAt'] != null 
                                ? _formatTimestamp(data['createdAt'] as Timestamp)
                                : "",
                              style: TextStyle(fontSize: 12, color: theme.hintColor),
                            ),
                          ],
                        ),
                        onTap: () {
                          if (!isGlobal && !isRead) doc.reference.update({'isRead': true});
                        },
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  String _formatTimestamp(Timestamp timestamp) {
    final now = DateTime.now();
    final date = timestamp.toDate();
    final diff = now.difference(date);
    if (diff.inMinutes < 60) return "${diff.inMinutes} mins ago";
    if (diff.inHours < 24) return "${diff.inHours} hours ago";
    return "${diff.inDays} days ago";
  }

  IconData _getIcon(String? type) {
    switch (type) {
      case 'order': return Icons.local_shipping;
      case 'promo': return Icons.local_offer;
      case 'alert': return Icons.notifications_active;
      default: return Icons.notifications;
    }
  }

  Color _getIconColor(String? type) {
    switch (type) {
      case 'order': return Colors.blue;
      case 'promo': return Colors.green;
      case 'alert': return Colors.red;
      default: return const Color(0xFFFB8C00);
    }
  }
}

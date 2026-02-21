import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';

class AdminUserScreen extends StatelessWidget {
  const AdminUserScreen({super.key});

  Future<void> _toggleBlockUser(BuildContext context, String userId, bool currentStatus) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'isBlocked': !currentStatus,
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(currentStatus ? "User unblocked" : "User blocked")),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  Future<void> _deleteUser(BuildContext context, String userId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete User"),
        content: const Text("Are you sure? This cannot be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Delete", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(userId).delete();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("User deleted")));
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Manage Users", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFAB47BC), // Different color for User section
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

          final users = snapshot.data?.docs ?? [];

          if (users.isEmpty) return const Center(child: Text("No users found"));

          return ListView.builder(
            padding: const EdgeInsets.all(15),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final userDoc = users[index];
              final userData = userDoc.data() as Map<String, dynamic>;
              final userId = userDoc.id;
              final email = userData['email'] ?? 'No Email';
              final name = userData['name'] ?? 'No Name';
              final isBlocked = userData['isBlocked'] ?? false;
              final createdAt = userData['createdAt'] as Timestamp?;
              final dateStr = createdAt != null ? DateFormat('MMM dd, yyyy').format(createdAt.toDate()) : 'N/A';

              return Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 10),
                color: theme.cardColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                  side: BorderSide(color: theme.dividerColor.withOpacity(0.1)),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFFAB47BC).withOpacity(0.1),
                    child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?', style: const TextStyle(color: Color(0xFFAB47BC), fontWeight: FontWeight.bold)),
                  ),
                  title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(email, style: const TextStyle(fontSize: 12)),
                      Text("Joined: $dateStr", style: const TextStyle(fontSize: 10, color: Colors.grey)),
                    ],
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'block') _toggleBlockUser(context, userId, isBlocked);
                      if (value == 'delete') _deleteUser(context, userId);
                      if (value == 'history') {
                         // Simplify: Show snackbar or implement history view later
                         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Order History View Coming Soon")));
                      }
                    },
                    itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                      PopupMenuItem<String>(
                        value: 'history',
                        child: Row(children: const [Icon(Icons.history, size: 18), SizedBox(width: 10), Text('Order History')]),
                      ),
                       PopupMenuItem<String>(
                        value: 'block',
                        child: Row(children: [
                          Icon(isBlocked ? Icons.check_circle : Icons.block, color: isBlocked ? Colors.green : Colors.orange, size: 18), 
                          const SizedBox(width: 10), 
                          Text(isBlocked ? 'Unblock User' : 'Block User')
                        ]),
                      ),
                      const PopupMenuItem<String>(
                        value: 'delete',
                        child: Row(children: [Icon(Icons.delete, color: Colors.red, size: 18), SizedBox(width: 10), Text('Delete Account', style: TextStyle(color: Colors.red))]),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

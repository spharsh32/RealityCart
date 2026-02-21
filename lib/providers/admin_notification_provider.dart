import 'package:flutter/material.dart';

class AdminNotificationItem {
  final int id;
  final String title;
  final String body;
  final String time;
  final String type;
  bool isRead;

  AdminNotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.time,
    required this.type,
    this.isRead = false,
  });
}

class AdminNotificationProvider with ChangeNotifier {
  final List<AdminNotificationItem> _notifications = [
    AdminNotificationItem(
      id: 1,
      title: "New Order Received",
      body: "Order #1005 has been placed by User 123.",
      time: "2 mins ago",
      type: "order",
      isRead: false,
    ),
    AdminNotificationItem(
      id: 2,
      title: "Low Stock Alert",
      body: "Wireless Headphones stock is running low (Only 2 left).",
      time: "1 hour ago",
      type: "stock",
      isRead: false,
    ),
    AdminNotificationItem(
      id: 3,
      title: "New User Registered",
      body: "Welcome 'John Doe' to Reality Cart.",
      time: "3 hours ago",
      type: "user",
      isRead: true,
    ),
    AdminNotificationItem(
      id: 4,
      title: "System Update",
      body: "Server maintenance scheduled for tonight at 12:00 AM.",
      time: "1 day ago",
      type: "system",
      isRead: true,
    ),
  ];

  List<AdminNotificationItem> get notifications => _notifications;

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  void markAsRead(int index) {
    _notifications[index].isRead = true;
    notifyListeners();
  }

  void markAllAsRead() {
    for (var n in _notifications) {
      n.isRead = true;
    }
    notifyListeners();
  }

  void deleteNotification(int index) {
    _notifications.removeAt(index);
    notifyListeners();
  }
}

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class AdminProvider with ChangeNotifier {
  double _totalSales = 0;
  int _totalOrders = 0;
  int _totalProducts = 0;
  int _totalUsers = 0;
  
  List<FlSpot> _weeklyRevenueData = [];
  bool _isLoading = false;

  double get totalSales => _totalSales;
  int get totalOrders => _totalOrders;
  int get totalProducts => _totalProducts;
  int get totalUsers => _totalUsers;
  List<FlSpot> get weeklyRevenueData => _weeklyRevenueData;
  bool get isLoading => _isLoading;

  Future<void> fetchDashboardData() async {
    _isLoading = true;
    notifyListeners();

    try {
      debugPrint("AdminProvider: Starting fetchDashboardData");
      // Fetch Orders
      final orderSnapshot = await FirebaseFirestore.instance.collection('orders').get();
      _totalOrders = orderSnapshot.docs.length;
      debugPrint("AdminProvider: Fetched $_totalOrders orders");
      
      _totalSales = 0;
      Map<int, double> dailyRevenue = {};
      
      final now = DateTime.now();
      final lastWeek = now.subtract(const Duration(days: 7));

      for (var doc in orderSnapshot.docs) {
        final data = doc.data();
        final amount = (data['totalAmount'] ?? 0).toDouble();
        
        // Calculate total sales
        _totalSales += amount;

        // Calculate weekly revenue for graph
        final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
        if (createdAt != null && createdAt.isAfter(lastWeek)) {
           int dayDiff = 6 - now.difference(createdAt).inDays; // 6 is today, 0 is 7 days ago
           if (dayDiff >= 0 && dayDiff <= 6) {
             dailyRevenue[dayDiff] = (dailyRevenue[dayDiff] ?? 0) + amount;
           }
        }
      }

      _weeklyRevenueData = List.generate(7, (index) {
        return FlSpot(index.toDouble(), dailyRevenue[index] ?? 0);
      });


      // Fetch Products Count
      final productSnapshot = await FirebaseFirestore.instance.collection('products').count().get();
      _totalProducts = productSnapshot.count ?? 0;
      debugPrint("AdminProvider: Fetched $_totalProducts products");

      // Fetch Users Count
      final userSnapshot = await FirebaseFirestore.instance.collection('users').count().get();
      _totalUsers = userSnapshot.count ?? 0;
      debugPrint("AdminProvider: Fetched $_totalUsers users");
      
      debugPrint("AdminProvider: Data fetch complete");

    } catch (e, stackTrace) {
      debugPrint("Error fetching admin dashboard data: $e");
      debugPrint("Stack trace: $stackTrace");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

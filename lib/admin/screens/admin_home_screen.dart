import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:reality_cart/admin/screens/add_product_screen.dart';
import 'package:reality_cart/admin/screens/admin_product_screen.dart';
import 'package:reality_cart/admin/screens/admin_order_screen.dart';
import 'package:reality_cart/admin/screens/admin_ar_manager_screen.dart';
import 'package:reality_cart/admin/screens/admin_settings_screen.dart';
import 'package:reality_cart/admin/screens/admin_notification_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:reality_cart/admin/screens/admin_user_screen.dart';
import 'package:reality_cart/admin/screens/admin_coupon_screen.dart';
import 'package:reality_cart/admin/screens/admin_analytics_screen.dart';
import 'package:reality_cart/providers/admin_notification_provider.dart';
import 'package:reality_cart/admin/providers/admin_provider.dart';
import 'package:fl_chart/fl_chart.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch dashboard data on init
    Future.microtask(() => 
      Provider.of<AdminProvider>(context, listen: false).fetchDashboardData()
    );
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("Building AdminHomeScreen");
    final theme = Theme.of(context);
    final adminProvider = Provider.of<AdminProvider>(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          "Admin Dashboard",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFFB8C00), Color(0xFFFFA726)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          Consumer<AdminNotificationProvider>(
            builder: (context, provider, child) {
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications, color: Colors.white),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AdminNotificationScreen()),
                      );
                    },
                  ),
                  if (provider.unreadCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '${provider.unreadCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      drawer: _buildAdminDrawer(),
      body: RefreshIndicator(
        onRefresh: () async {
          await adminProvider.fetchDashboardData();
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Overview",
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              // Stats Grid
              _buildStatsGrid(adminProvider),
              const SizedBox(height: 30),
               Text(
                "Revenue Analysis (Last 7 Days)",
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 15),
              _buildRevenueChart(adminProvider),
              const SizedBox(height: 30),
              Text(
                "Recent Activity",
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 15),
              _buildRecentActivityList(),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddProductScreen()),
          );
        },
        backgroundColor: const Color(0xFFFB8C00),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Add Product", style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildStatsGrid(AdminProvider provider) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 15,
      mainAxisSpacing: 15,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildStatCard("Total Sales", "₹${provider.totalSales.toStringAsFixed(0)}", Icons.currency_rupee, const [Color(0xFF66BB6A), Color(0xFF43A047)]),
        _buildStatCard("Total Orders", "${provider.totalOrders}", Icons.shopping_bag, const [Color(0xFF42A5F5), Color(0xFF1E88E5)]),
        _buildStatCard("Products", "${provider.totalProducts}", FontAwesomeIcons.box, const [Color(0xFFFFA726), Color(0xFFFB8C00)]),
        _buildStatCard("Total Users", "${provider.totalUsers}", FontAwesomeIcons.users, const [Color(0xFFAB47BC), Color(0xFF8E24AA)]),
      ],
    );
  }

  Widget _buildRevenueChart(AdminProvider provider) {
     if (provider.isLoading) {
      return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));
    }
    
    if (provider.weeklyRevenueData.isEmpty) {
       return const SizedBox(height: 200, child: Center(child: Text("No Data Available")));
    }

    return Container(
      height: 250,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                  if (value.toInt() >= 0 && value.toInt() < 7) {
                     // This simple mapping assumes 0 is Monday, which might not match exact dates
                     // For a real app, map index to actual day name based on data
                     return Text(days[value.toInt()], style: const TextStyle(fontSize: 10));
                  }
                  return const Text('');
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: 6,
          minY: 0,
          lineBarsData: [
            LineChartBarData(
              spots: provider.weeklyRevenueData,
              isCurved: true,
              color: const Color(0xFFFB8C00),
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: const Color(0xFFFB8C00).withOpacity(0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminDrawer() {
    final theme = Theme.of(context);
    
    return Drawer(
      backgroundColor: theme.scaffoldBackgroundColor,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFFB8C00), Color(0xFFFFA726)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: const [
                CircleAvatar(
                  backgroundColor: Colors.white,
                  radius: 30,
                  child: Icon(Icons.admin_panel_settings, color: Color(0xFFFB8C00), size: 30),
                ),
                SizedBox(height: 10),
                Text(
                  "Admin Panel",
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Text(
                  "admin@realitycart.com",
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text('Dashboard'),
            selected: true,
            selectedColor: const Color(0xFFFB8C00),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(FontAwesomeIcons.box),
            title: const Text('Products'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminProductScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.shopping_cart),
            title: const Text('Orders'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminOrderScreen()));
            },
          ),
           ListTile(
            leading: const Icon(FontAwesomeIcons.users),
            title: const Text('Users'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminUserScreen()));
            },
          ),
          ListTile(
            leading: const Icon(FontAwesomeIcons.ticket),
            title: const Text('Coupons'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminCouponScreen()));
            },
          ),
           ListTile(
            leading: const Icon(Icons.analytics),
            title: const Text('Reports'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminAnalyticsScreen()));
            },
          ),
          ListTile(
            leading: const Icon(FontAwesomeIcons.cube),
            title: const Text('AR Assets'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminARManagerScreen()));
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminSettingsScreen()));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, List<Color> colors) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colors.first.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: Colors.white, size: 30),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
              Text(
                title,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivityList() {
    final theme = Theme.of(context);
    
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('orders').orderBy('createdAt', descending: true).limit(5).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("No recent activity"));
        }

        final orders = snapshot.data!.docs;

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final order = orders[index].data() as Map<String, dynamic>;
            final orderId = orders[index].id.substring(0, 5);
            final totalAmount = order['totalAmount'] ?? 0;
            final status = order['status'] ?? 'Pending';

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
                  backgroundColor: const Color(0xFFFB8C00).withOpacity(0.1),
                  child: const Icon(Icons.shopping_bag, color: Color(0xFFFB8C00), size: 20),
                ),
                title: Text(
                  "Order #$orderId", 
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)
                ),
                subtitle: Text(
                  "Status: $status",
                  style: theme.textTheme.bodySmall,
                ),
                trailing: Text(
                  "₹${totalAmount.toStringAsFixed(2)}", 
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)
                ),
              ),
            );
          },
        );
      },
    );
  }
}

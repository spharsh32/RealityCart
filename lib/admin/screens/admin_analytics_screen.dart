import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class AdminAnalyticsScreen extends StatelessWidget {
  const AdminAnalyticsScreen({super.key});

  Future<void> _downloadSalesReport(BuildContext context) async {
    // Mock download
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Downloading Sales_Report_2024.csv...")),
    );
    await Future.delayed(const Duration(seconds: 2));
    if (context.mounted) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Download Complete (Mock)")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Analytics & Reports", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.indigo,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildActionCard(
              context, 
              "Export Sales Report", 
              "Download CSV of all orders", 
              Icons.download, 
              Colors.green, 
              _downloadSalesReport
            ),
            const SizedBox(height: 30),
            Text(
              "Low Stock Alerts",
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            _buildLowStockList(theme),
            const SizedBox(height: 30),
            Text(
              "Most Sold Products",
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            _buildMostSoldList(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(BuildContext context, String title, String subtitle, IconData icon, Color color, Function(BuildContext) onTap) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(20),
        leading: containerIcon(icon, color),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () => onTap(context),
      ),
    );
  }

  Widget containerIcon(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: color, size: 28),
    );
  }

  Widget _buildLowStockList(ThemeData theme) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('products').where('stock', isLessThan: 10).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Card(child: Padding(padding: EdgeInsets.all(20), child: Center(child: Text("No low stock items. Good job!"))));
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final data = doc.data() as Map<String, dynamic>;
            final stock = data['stock'] ?? 0;

            return Card(
              color: Colors.red.withOpacity(0.05),
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: const Icon(Icons.warning, color: Colors.red),
                title: Text(data['name'] ?? 'Uknown', style: const TextStyle(fontWeight: FontWeight.bold)),
                trailing: Text("$stock left", style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMostSoldList(ThemeData theme) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('products')
          .orderBy('soldCount', descending: true)
          .limit(5)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
           return const Card(
             child: Padding(
               padding: EdgeInsets.all(20), 
               child: Center(child: Text("No sales data available yet."))
             )
           );
        }

        return Column(
          children: snapshot.data!.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final soldCount = data['soldCount'] ?? 0;
            
            // Only show if at least one item sold, or if you want to show top even with 0
            if (soldCount == 0 && snapshot.data!.docs.length > 5) return const SizedBox.shrink();

            return Card(
              color: Colors.amber.withOpacity(0.05),
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: const Icon(FontAwesomeIcons.crown, color: Colors.amber),
                title: Text(data['name'] ?? 'Unknown Product', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text("Sold: $soldCount units"),
                trailing: const Icon(Icons.trending_up, color: Colors.green),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

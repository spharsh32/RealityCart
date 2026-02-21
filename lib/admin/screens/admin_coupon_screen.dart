import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AdminCouponScreen extends StatefulWidget {
  const AdminCouponScreen({super.key});

  @override
  State<AdminCouponScreen> createState() => _AdminCouponScreenState();
}

class _AdminCouponScreenState extends State<AdminCouponScreen> {
  
  void _showAddEditCouponDialog({String? docId, Map<String, dynamic>? initialData}) {
    final formKey = GlobalKey<FormState>();
    final codeController = TextEditingController(text: initialData?['code'] ?? '');
    final discountController = TextEditingController(text: initialData?['discountAmount']?.toString() ?? '');
    final minOrderController = TextEditingController(text: initialData?['minOrderAmount']?.toString() ?? '');
    String type = initialData?['type'] ?? 'fixed'; // fixed or percentage
    DateTime? expiryDate = initialData?['expiryDate']?.toDate();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: Theme.of(context).cardColor,
            title: Text(docId == null ? "Add Coupon" : "Edit Coupon"),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: codeController,
                      decoration: const InputDecoration(labelText: "Coupon Code"),
                      validator: (val) => val!.isEmpty ? "Required" : null,
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: discountController,
                            decoration: const InputDecoration(labelText: "Discount"),
                            keyboardType: TextInputType.number,
                            validator: (val) => val!.isEmpty ? "Required" : null,
                          ),
                        ),
                        const SizedBox(width: 10),
                        DropdownButton<String>(
                          value: type,
                          items: const [
                            DropdownMenuItem(value: 'fixed', child: Text("₹")),
                            DropdownMenuItem(value: 'percentage', child: Text("%")),
                          ],
                          onChanged: (val) => setState(() => type = val!),
                        ),
                      ],
                    ),
                    TextFormField(
                      controller: minOrderController,
                      decoration: const InputDecoration(labelText: "Min Order Amount"),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 10),
                    ListTile(
                      title: Text(expiryDate == null ? "Select Expiry Date" : "Expires: ${DateFormat('MMM dd, yyyy').format(expiryDate!)}"),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: expiryDate ?? DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null) setState(() => expiryDate = picked);
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
              ElevatedButton(
                onPressed: () async {
                  if (formKey.currentState!.validate()) {
                    final data = {
                      'code': codeController.text.trim().toUpperCase(),
                      'discountAmount': double.parse(discountController.text),
                      'type': type,
                      'minOrderAmount': double.tryParse(minOrderController.text) ?? 0,
                      'expiryDate': expiryDate,
                      'isActive': true,
                      'createdAt': FieldValue.serverTimestamp(),
                    };

                    if (docId == null) {
                      await FirebaseFirestore.instance.collection('coupons').add(data);
                    } else {
                      await FirebaseFirestore.instance.collection('coupons').doc(docId).update(data);
                    }
                    if (mounted) Navigator.pop(context);
                  }
                },
                child: const Text("Save"),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _deleteCoupon(String docId) async {
    await FirebaseFirestore.instance.collection('coupons').doc(docId).delete();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Manage Coupons", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.teal,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () => _showAddEditCouponDialog(),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('coupons').orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

          final coupons = snapshot.data?.docs ?? [];

          if (coupons.isEmpty) return const Center(child: Text("No coupons found"));

          return ListView.builder(
            padding: const EdgeInsets.all(15),
            itemCount: coupons.length,
            itemBuilder: (context, index) {
              final doc = coupons[index];
              final data = doc.data() as Map<String, dynamic>;
              final isActive = data['isActive'] ?? true;
              final expiry = data['expiryDate'] as Timestamp?;
              final isExpired = expiry != null && expiry.toDate().isBefore(DateTime.now());

              return Card(
                color: theme.cardColor,
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.teal.withOpacity(0.1),
                    child: const Icon(Icons.local_offer, color: Colors.teal),
                  ),
                  title: Text(data['code'] ?? 'CODE', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("${data['type'] == 'percentage' ? '${data['discountAmount']}%' : '₹${data['discountAmount']}'} off • Min Order: ₹${data['minOrderAmount']}"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                       if (isExpired) 
                         const Chip(label: Text("Expired", style: TextStyle(fontSize: 10, color: Colors.white)), backgroundColor: Colors.red)
                       else 
                         Switch(
                           value: isActive, 
                           onChanged: (val) => FirebaseFirestore.instance.collection('coupons').doc(doc.id).update({'isActive': val}),
                           activeColor: Colors.teal,
                         ),
                       IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _showAddEditCouponDialog(docId: doc.id, initialData: data)),
                       IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteCoupon(doc.id)),
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

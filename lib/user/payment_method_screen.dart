import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PaymentMethodScreen extends StatefulWidget {
  const PaymentMethodScreen({super.key});

  @override
  State<PaymentMethodScreen> createState() => _PaymentMethodScreenState();
}

class _PaymentMethodScreenState extends State<PaymentMethodScreen> {
  final User? _user = FirebaseAuth.instance.currentUser;

  Future<void> _deletePaymentMethod(String methodId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Remove Card"),
        content: const Text("Are you sure you want to remove this payment method?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Remove", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && _user != null) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(_user!.uid)
            .collection('payment_methods')
            .doc(methodId)
            .delete();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Payment method removed")),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error: $e")),
          );
        }
      }
    }
  }

  void _showCardDialog({String? methodId, Map<String, dynamic>? method}) {
    final isEditing = methodId != null;
    final numberController = TextEditingController(text: isEditing ? method!['number'] : '');
    final expiryController = TextEditingController(text: isEditing ? method!['expiry'] : '');
    final cvvController = TextEditingController();
    final nameController = TextEditingController(text: isEditing ? method!['holder'] : '');
    final formKey = GlobalKey<FormState>();
    bool isLoading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final theme = Theme.of(context);
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              color: theme.scaffoldBackgroundColor,
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        isEditing ? "Edit Card" : "Add New Card",
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: theme.textTheme.titleLarge?.color),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: numberController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(16),
                        ],
                        decoration: InputDecoration(
                          labelText: "Card Number",
                          prefixIcon: const Icon(Icons.credit_card),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Required';
                          if (!isEditing && value.length != 16) return 'Enter the 16 digit Card No';
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: expiryController,
                              keyboardType: TextInputType.number,
                              textInputAction: TextInputAction.next,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                CardExpiryInputFormatter(),
                              ],
                              decoration: InputDecoration(
                                labelText: "Expiry (MM/YY)",
                                hintText: "MM/YY",
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Required';
                                }

                                if (value.length != 5 || !value.contains('/')) {
                                  return 'Invalid format';
                                }

                                final parts = value.split('/');
                                if (parts.length != 2) return 'Invalid format';
                                
                                final month = int.tryParse(parts[0]);
                                final year = int.tryParse(parts[1]);

                                if (month == null || year == null) {
                                  return 'Invalid expiry';
                                }

                                if (month < 1 || month > 12) {
                                  return 'Invalid month';
                                }

                                // Expiry Check
                                final now = DateTime.now();
                                final fourDigitYear = 2000 + year;
                                final expiryDate = DateTime(fourDigitYear, month + 1, 0);

                                if (expiryDate.isBefore(now)) {
                                  return 'Card expired';
                                }

                                return null;
                              },
                              onChanged: (value) {
                                if (value.length == 5) {
                                  FocusScope.of(context).nextFocus();
                                }
                              },
                            ),
                          ),

                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: cvvController,
                              keyboardType: TextInputType.number,
                              obscureText: true,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(3),
                              ],
                              decoration: InputDecoration(
                                labelText: "CVV",
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              validator: (value) {
                                if (!isEditing && (value == null || value.isEmpty)) return 'Required';
                                if (value != null && value.isNotEmpty && value.length != 3) return 'Invalid CVV';
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: nameController,
                        decoration: InputDecoration(
                          labelText: "Cardholder Name",
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Required';
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: isLoading ? null : () async {
                          if (formKey.currentState!.validate() && _user != null) {
                            setModalState(() => isLoading = true);
                            
                            String type = "Visa";
                            if (numberController.text.startsWith('5')) type = "MasterCard";

                            final cardData = {
                              "type": type,
                              "number": isEditing ? numberController.text : "**** **** **** ${numberController.text.substring(numberController.text.length - 4)}",
                              "expiry": expiryController.text,
                              "holder": nameController.text,
                              "updatedAt": FieldValue.serverTimestamp(),
                            };

                            try {
                              final collection = FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(_user!.uid)
                                  .collection('payment_methods');

                              if (isEditing) {
                                await collection.doc(methodId).update(cardData);
                              } else {
                                await collection.add(cardData);
                              }

                              if (mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(isEditing ? "Card updated" : "Card saved")),
                                );
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text("Error: $e")),
                                );
                              }
                            } finally {
                              setModalState(() => isLoading = false);
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFB8C00),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: isLoading 
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text(isEditing ? "Update Card" : "Save Card", style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            );
          }
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_user == null) {
      return const Scaffold(body: Center(child: Text("Please login to manage payment methods")));
    }

    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Payment Methods", style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(_user!.uid)
            .collection('payment_methods')
            .orderBy('updatedAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(child: Text("No payment methods found"));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: docs.length,
            separatorBuilder: (context, index) => const SizedBox(height: 15),
            itemBuilder: (context, index) {
              final methodDoc = docs[index];
              final method = methodDoc.data() as Map<String, dynamic>;
              final methodId = methodDoc.id;

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.credit_card, color: Color(0xFFFB8C00), size: 30),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            method['type'] ?? 'Card',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: theme.textTheme.titleMedium?.color),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            method['number'] ?? '**** **** **** ****',
                            style: TextStyle(color: theme.textTheme.bodySmall?.color, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                      onPressed: () => _showCardDialog(methodId: methodId, method: method),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () => _deletePaymentMethod(methodId),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCardDialog(),
        backgroundColor: const Color(0xFFFB8C00),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class CardExpiryInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {

    String digitsOnly = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    if (digitsOnly.length > 4) {
      digitsOnly = digitsOnly.substring(0, 4);
    }

    // Auto month correction
    if (digitsOnly.length >= 1) {
      int firstDigit = int.parse(digitsOnly[0]);
      if (digitsOnly.length == 1 && firstDigit > 1) {
        digitsOnly = '0$digitsOnly';
      }
    }

    if (digitsOnly.length >= 2) {
      int month = int.parse(digitsOnly.substring(0, 2));

      if (month == 0) {
        digitsOnly = '01${digitsOnly.substring(2)}';
      } else if (month > 12) {
        digitsOnly = '12${digitsOnly.substring(2)}';
      }
    }

    String formatted = '';
    if (digitsOnly.length >= 3) {
      formatted =
          '${digitsOnly.substring(0, 2)}/${digitsOnly.substring(2)}';
    } else {
      formatted = digitsOnly;
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

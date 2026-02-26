import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reality_cart/providers/cart_provider.dart';
import 'package:reality_cart/user/checkout_screen.dart';
import 'package:reality_cart/user/home_screen.dart';
import 'package:reality_cart/l10n/app_localizations.dart';
import 'package:reality_cart/widgets/translated_text.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cartProvider = Provider.of<CartProvider>(context);
    const brandOrange = Color(0xFFFB8C00);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.myCart, style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: cartProvider.cartItems.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart_outlined, size: 80, color: theme.disabledColor.withOpacity(0.2)),
                  const SizedBox(height: 16),
                  Text(AppLocalizations.of(context)!.yourCartIsEmpty, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(AppLocalizations.of(context)!.addItemsNow, style: TextStyle(color: theme.hintColor)),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (context) => const HomeScreen()),
                        (route) => false,
                      );
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: brandOrange, foregroundColor: Colors.white),
                    child: Text(AppLocalizations.of(context)!.shopNow),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: cartProvider.cartItems.length,
                    itemBuilder: (context, index) {
                      final item = cartProvider.cartItems[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(color: theme.dividerColor.withOpacity(0.1)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Product Image
                              Container(
                                width: 90,
                                height: 90,
                                decoration: BoxDecoration(
                                  color: theme.disabledColor.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: item.imageUrl != null
                                    ? Image.network(item.imageUrl!, fit: BoxFit.contain)
                                    : const Icon(Icons.image, color: Colors.grey),
                              ),
                              const SizedBox(width: 12),
                              // Details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    TranslatedText(item.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15), maxLines: 2, overflow: TextOverflow.ellipsis),
                                    const SizedBox(height: 4),
                                    Text("${AppLocalizations.of(context)!.size}: ${item.size}", style: TextStyle(color: theme.hintColor, fontSize: 13)),
                                    const SizedBox(height: 8),
                                    Text("₹${item.price.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                                    const SizedBox(height: 12),
                                    // Quantity Selector
                                    Row(
                                      children: [
                                        _qtyBtn(Icons.remove, () => cartProvider.decrementQuantity(item)),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 15),
                                          child: Text("${item.quantity}", style: const TextStyle(fontWeight: FontWeight.bold)),
                                        ),
                                        _qtyBtn(Icons.add, () => cartProvider.incrementQuantity(item)),
                                        const Spacer(),
                                        TextButton(
                                          onPressed: () => cartProvider.removeFromCart(item),
                                          child: Text(AppLocalizations.of(context)!.remove, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                // Bottom Price Summary
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    border: Border(top: BorderSide(color: theme.dividerColor.withOpacity(0.1))),
                  ),
                  child: SafeArea(
                    child: Row(
                      children: [
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("₹${cartProvider.total.toStringAsFixed(2)}", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                            Text(AppLocalizations.of(context)!.viewDetails, style: const TextStyle(color: brandOrange, fontSize: 12, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const Spacer(),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => const CheckoutScreen()));
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: brandOrange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                            elevation: 0,
                          ),
                          child: Text(AppLocalizations.of(context)!.placeOrder, style: const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _qtyBtn(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Icon(icon, size: 16),
      ),
    );
  }
}

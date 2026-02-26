import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reality_cart/providers/wishlist_provider.dart';
import 'package:reality_cart/user/product_detail_screen.dart';
import 'package:reality_cart/user/home_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:reality_cart/l10n/app_localizations.dart';
import 'package:reality_cart/widgets/translated_text.dart';

class WishlistScreen extends StatelessWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final wishlistProvider = Provider.of<WishlistProvider>(context);
    final theme = Theme.of(context);
    const brandOrange = Color(0xFFFB8C00);

    final wishlistItems = wishlistProvider.wishlistItems;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.myWishlist, style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: wishlistItems.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border, size: 80, color: theme.disabledColor.withOpacity(0.2)),
                  const SizedBox(height: 16),
                  Text(AppLocalizations.of(context)!.yourWishlistIsEmpty, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(AppLocalizations.of(context)!.saveItemsForLater, style: TextStyle(color: theme.hintColor)),
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
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: wishlistItems.length,
              itemBuilder: (context, index) {
                final productId = wishlistItems[index];
                return WishlistItem(productId: productId);
              },
            ),
    );
  }
}

class WishlistItem extends StatelessWidget {
  final String productId;

  const WishlistItem({super.key, required this.productId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const brandOrange = Color(0xFFFB8C00);

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('products').doc(productId).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: theme.dividerColor.withOpacity(0.1)),
            ),
            child: const SizedBox(height: 100, child: Center(child: CircularProgressIndicator())),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const SizedBox(); // Hide if product not found
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final name = data['name'] ?? AppLocalizations.of(context)!.unknownProduct;
        final price = (data['price'] ?? 0).toDouble();
        final imageUrls = data['imageUrls'] as List<dynamic>?;
        final firstImage = (imageUrls != null && imageUrls.isNotEmpty) ? imageUrls[0] : null;

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
                  child: firstImage != null
                      ? Image.network(firstImage, fit: BoxFit.contain)
                      : const Icon(Icons.image, color: Colors.grey),
                ),
                const SizedBox(width: 12),
                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TranslatedText(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15), maxLines: 2, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 8),
                      Text("₹${price.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      const SizedBox(height: 12),
                      
                      // Actions
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () {
                               Provider.of<WishlistProvider>(context, listen: false).toggleWishlist(productId);
                            },
                             style: TextButton.styleFrom(
                              foregroundColor: Colors.red,
                              padding: const EdgeInsets.symmetric(horizontal: 0),
                              visualDensity: VisualDensity.compact,
                            ),
                            child: Text(AppLocalizations.of(context)!.remove, style: const TextStyle(fontWeight: FontWeight.bold)),
                          ),
                          const Spacer(),
                           ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => ProductDetailScreen(productId: productId)),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: brandOrange,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                elevation: 0,
                                visualDensity: VisualDensity.compact, // Make it smaller
                              ),
                              child: Text(AppLocalizations.of(context)!.viewDetails, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
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
    );
  }
}

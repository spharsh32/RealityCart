import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:reality_cart/providers/wishlist_provider.dart';
import 'package:reality_cart/providers/cart_provider.dart';
import 'package:reality_cart/user/checkout_screen.dart';
import 'package:reality_cart/user/cart_screen.dart';
// import 'package:reality_cart/user/ar_view_screen.dart';
import 'package:reality_cart/user/wishlist_screen.dart';
import 'package:reality_cart/models/cart_item.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProductDetailScreen extends StatefulWidget {
  final String productId;
  const ProductDetailScreen({super.key, required this.productId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _selectedColor = 0;
  int _selectedSize = 1;
  int _currentImageIndex = 0;
  late Future<DocumentSnapshot> _productFuture;

  final List<Color> _colors = [
    Colors.black,
    Colors.blue,
    Colors.red,
  ];

  final List<String> _sizes = ["S", "M", "L", "XL"];

  @override
  void initState() {
    super.initState();
    _productFuture = FirebaseFirestore.instance.collection('products').doc(widget.productId).get();
    _recordView();
  }

  // Update viewedAt timestamp so it moves to top of Recent View
  Future<void> _recordView() async {
    try {
      await FirebaseFirestore.instance.collection('products').doc(widget.productId).update({
        'viewedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint("Error recording view: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return FutureBuilder<DocumentSnapshot>(
      future: _productFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(body: Center(child: Text("Something went wrong", style: TextStyle(color: theme.textTheme.bodyMedium?.color))));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Scaffold(body: Center(child: Text("Product not found", style: TextStyle(color: theme.textTheme.bodyMedium?.color))));
        }

        Map<String, dynamic> data = snapshot.data!.data() as Map<String, dynamic>;
        List<dynamic> imageUrls = data['imageUrls'] ?? [];
        String name = data['name'] ?? "No Name";
        double price = (data['price'] ?? 0).toDouble();
        String description = data['description'] ?? "No description available.";
        String? arModelUrl = data['arModelUrl'];
        String? firstImage = imageUrls.isNotEmpty ? imageUrls[0] : null;

        return Scaffold(
          appBar: AppBar(
            backgroundColor: theme.scaffoldBackgroundColor,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: theme.iconTheme.color),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.share_outlined, color: theme.iconTheme.color),
                onPressed: () {},
              ),
              Consumer<WishlistProvider>(
                builder: (context, wishlistProvider, child) {
                  final isInWishlist = wishlistProvider.isInWishlist(widget.productId);
                  return IconButton(
                    icon: Icon(
                      isInWishlist ? Icons.favorite : Icons.favorite_border,
                      color: isInWishlist ? Colors.red : theme.iconTheme.color,
                    ),
                    onPressed: () => wishlistProvider.toggleWishlist(widget.productId),
                  );
                },
              ),
              IconButton(
                icon: Icon(Icons.list_alt, color: theme.iconTheme.color),
                tooltip: 'My Wishlist',
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const WishlistScreen()));
                },
              ),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- Image Carousel ---
                      Stack(
                        children: [
                          Container(
                            height: 350,
                            width: double.infinity,
                            color: theme.disabledColor.withOpacity(0.05),
                            child: imageUrls.isNotEmpty
                                ? PageView.builder(
                                    itemCount: imageUrls.length,
                                    onPageChanged: (index) => setState(() => _currentImageIndex = index),
                                    itemBuilder: (context, index) {
                                      return Hero(
                                        tag: index == 0 ? widget.productId : 'img_${widget.productId}_$index',
                                        child: Image.network(imageUrls[index], fit: BoxFit.contain),
                                      );
                                    },
                                  )
                                : const Icon(Icons.image_not_supported, size: 100, color: Colors.grey),
                          ),
/*
                          if (arModelUrl != null && arModelUrl.isNotEmpty)
                            Positioned(
                              bottom: 20,
                              right: 20,
                              child: FloatingActionButton.small(
                                backgroundColor: const Color(0xFFFB8C00),
                                child: const Icon(FontAwesomeIcons.cube, color: Colors.white, size: 18),
                                onPressed: () {
                                  // Navigator.push(context, MaterialPageRoute(builder: (context) => ARViewScreen(modelUrl: arModelUrl)));
                                },
                              ),
                            ),
*/
                        ],
                      ),
                      
                      // Indicators
                      if (imageUrls.length > 1)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              imageUrls.length,
                              (index) => AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                width: _currentImageIndex == index ? 20 : 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: _currentImageIndex == index ? const Color(0xFFFB8C00) : theme.disabledColor.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                          ),
                        ),

                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Text(
                                  "₹${price.toStringAsFixed(2)}",
                                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(width: 10),
                                const Text(
                                  "Inclusive of all taxes",
                                  style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(height: 15),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Row(
                                    children: [
                                      Text("4.8", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                                      SizedBox(width: 4),
                                      Icon(Icons.star, color: Colors.white, size: 12),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text("2,543 ratings", style: TextStyle(color: theme.textTheme.bodySmall?.color)),
                              ],
                            ),
                            const Divider(height: 40),
                            
                            // --- Delivery Info ---
                            const Row(
                              children: [
                                Icon(Icons.local_shipping_outlined, color: Colors.grey, size: 20),
                                SizedBox(width: 10),
                                Text("FREE Delivery", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                                Text(" by "),
                                Text("Tomorrow, 10 AM", style: TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const Divider(height: 40),

                            // --- Variants ---
                            Text("Select Size", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: theme.textTheme.titleMedium?.color)),
                            const SizedBox(height: 12),
                            Row(
                              children: List.generate(_sizes.length, (index) {
                                final isSelected = _selectedSize == index;
                                return GestureDetector(
                                  onTap: () => setState(() => _selectedSize = index),
                                  child: Container(
                                    margin: const EdgeInsets.only(right: 12),
                                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: isSelected ? const Color(0xFFFB8C00).withOpacity(0.1) : theme.cardColor,
                                      border: Border.all(color: isSelected ? const Color(0xFFFB8C00) : theme.dividerColor),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      _sizes[index],
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: isSelected ? const Color(0xFFFB8C00) : theme.textTheme.bodyMedium?.color,
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ),
                            const SizedBox(height: 25),

                            Text("Description", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: theme.textTheme.titleMedium?.color)),
                            const SizedBox(height: 10),
                            Text(
                              description,
                              style: TextStyle(color: theme.textTheme.bodyMedium?.color?.withOpacity(0.8), height: 1.5),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // --- Sticky Bottom Bar (Flipkart Style) ---
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
                ),
                child: SafeArea(
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Provider.of<CartProvider>(context, listen: false).addToCart(
                              widget.productId, 
                              name, 
                              price, 
                              _sizes[_selectedSize], 
                              _selectedColor,
                              imageUrl: firstImage,
                            );
                            Navigator.push(context, MaterialPageRoute(builder: (context) => const CartScreen()));
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            side: const BorderSide(color: Color(0xFFFB8C00)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                          ),
                          child: const Text("ADD TO CART", style: TextStyle(color: Color(0xFFFB8C00), fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            final item = CartItem(
                              id: widget.productId,
                              name: name,
                              price: price,
                              size: _sizes[_selectedSize],
                              color: _selectedColor,
                              quantity: 1,
                              imageUrl: firstImage,
                            );

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CheckoutScreen(checkoutItems: [item]),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFB8C00),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                            elevation: 0,
                          ),
                          child: const Text("BUY NOW", style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

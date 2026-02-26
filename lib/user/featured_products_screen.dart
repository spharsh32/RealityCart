import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:reality_cart/user/product_detail_screen.dart';
import 'package:provider/provider.dart';
import 'package:reality_cart/providers/wishlist_provider.dart';
import 'package:reality_cart/l10n/app_localizations.dart';
import 'package:reality_cart/widgets/translated_text.dart';

class FeaturedProductsScreen extends StatefulWidget {
  const FeaturedProductsScreen({super.key});

  @override
  State<FeaturedProductsScreen> createState() => _FeaturedProductsScreenState();
}

class _FeaturedProductsScreenState extends State<FeaturedProductsScreen> {
  String _selectedSort = 'Newest';
  String _selectedCategory = 'All';
  final List<String> _categories = ['All', 'Electronics', 'Fashion', 'Home', 'Books', 'Toys'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.featuredProducts, style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.sort),
            onPressed: _showSortDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Category Filter Bar
          Container(
            height: 50,
            margin: const EdgeInsets.symmetric(vertical: 10),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 15),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = _selectedCategory == category;
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: ChoiceChip(
                    label: Text(_getTranslatedCategory(context, category)),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) setState(() => _selectedCategory = category);
                    },
                    selectedColor: const Color(0xFFFB8C00),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : theme.textTheme.bodyMedium?.color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              },
            ),
          ),
          
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _buildQuery().snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return Center(child: Text(AppLocalizations.of(context)!.somethingWentWrong));
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) return Center(child: Text(AppLocalizations.of(context)!.noProductsMatchFilters));

                return GridView.builder(
                  padding: const EdgeInsets.all(15),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.7,
                    crossAxisSpacing: 15,
                    mainAxisSpacing: 15,
                  ),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final productId = docs[index].id;
                    final productData = docs[index].data() as Map<String, dynamic>;
                    return _buildProductCard(context, productId, productData);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Query _buildQuery() {
    Query query = FirebaseFirestore.instance.collection('products');

    // Apply Category Filter
    if (_selectedCategory != 'All') {
      query = query.where('category', isEqualTo: _selectedCategory);
    }

    // Apply Sorting
    switch (_selectedSort) {
      case 'Price: Low to High':
        query = query.orderBy('price', descending: false);
        break;
      case 'Price: High to Low':
        query = query.orderBy('price', descending: true);
        break;
      case 'Newest':
      default:
        query = query.orderBy('createdAt', descending: true);
        break;
    }

    return query;
  }

  String _getTranslatedCategory(BuildContext context, String category) {
    switch (category) {
      case 'Electronics': return AppLocalizations.of(context)!.electronics;
      case 'Fashion': return AppLocalizations.of(context)!.fashion;
      case 'Home': return AppLocalizations.of(context)!.home;
      case 'Books': return AppLocalizations.of(context)!.books;
      case 'Toys': return AppLocalizations.of(context)!.toys;
      case 'Beauty': return AppLocalizations.of(context)!.beauty;
      case 'Sports': return AppLocalizations.of(context)!.sports;
      case 'Grocery': return AppLocalizations.of(context)!.grocery;
      case 'Automotive': return AppLocalizations.of(context)!.automotive;
      default: return AppLocalizations.of(context)!.all;
    }
  }

  void _showSortDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppLocalizations.of(context)!.sortBy, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              _sortTile('Newest', AppLocalizations.of(context)!.newest),
              _sortTile('Price: Low to High', AppLocalizations.of(context)!.priceLowToHigh),
              _sortTile('Price: High to Low', AppLocalizations.of(context)!.priceHighToLow),
            ],
          ),
        );
      },
    );
  }

  Widget _sortTile(String value, String title) {
    return ListTile(
      title: Text(title),
      trailing: _selectedSort == value ? const Icon(Icons.check, color: Color(0xFFFB8C00)) : null,
      onTap: () {
        setState(() => _selectedSort = value);
        Navigator.pop(context);
      },
    );
  }

  Widget _buildProductCard(BuildContext context, String productId, Map<String, dynamic> data) {
    final theme = Theme.of(context);
    final imageUrls = data['imageUrls'] as List<dynamic>?;
    final firstImage = (imageUrls != null && imageUrls.isNotEmpty) ? imageUrls[0] : null;

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ProductDetailScreen(productId: productId),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: theme.disabledColor.withOpacity(0.1),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                    ),
                    child: firstImage != null
                        ? ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                            child: Image.network(firstImage, fit: BoxFit.cover),
                          )
                        : const Center(
                            child: Icon(Icons.image_not_supported, color: Colors.grey, size: 40),
                          ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Consumer<WishlistProvider>(
                      builder: (context, wishlistProvider, child) {
                        final isInWishlist = wishlistProvider.isInWishlist(productId);
                        return GestureDetector(
                          onTap: () => wishlistProvider.toggleWishlist(productId),
                          child: CircleAvatar(
                            radius: 14,
                            backgroundColor: theme.cardColor,
                            child: Icon(
                              isInWishlist ? Icons.favorite : Icons.favorite_border,
                              color: isInWishlist ? Colors.red : Colors.grey,
                              size: 16,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TranslatedText(
                          data['name'] ?? AppLocalizations.of(context)!.productName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: theme.textTheme.titleMedium?.color),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "₹${data['price'] ?? '0.00'}",
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.textTheme.bodySmall?.color,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const Icon(Icons.star, size: 12, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text("4.5", style: TextStyle(fontSize: 11, color: theme.textTheme.bodySmall?.color)),
                      ],
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:reality_cart/user/cart_screen.dart';
import 'package:reality_cart/user/wishlist_screen.dart';
import 'package:reality_cart/user/ai_screen.dart';
import 'package:reality_cart/user/profile_screen.dart';
import 'package:reality_cart/user/product_detail_screen.dart';
import 'package:provider/provider.dart';
import 'package:reality_cart/providers/wishlist_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:reality_cart/user/notification_screen.dart';
import 'package:reality_cart/providers/notification_provider.dart';
import 'package:reality_cart/user/search_screen.dart';
import 'package:reality_cart/user/all_categories_screen.dart';
import 'package:reality_cart/user/recently_viewed_screen.dart';
import 'package:reality_cart/user/featured_products_screen.dart';
import 'package:reality_cart/l10n/app_localizations.dart';
import 'package:reality_cart/providers/language_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  String _userName = "User";

  @override
  void initState() {
    super.initState();
    _fetchUserName();
  }

  Future<void> _fetchUserName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists && mounted) {
        setState(() {
          _userName = doc.data()?['name'] ?? "User";
        });
      }
    }
  }

  final List<Widget> _pages = [
    const HomeContent(), 
    const WishlistScreen(),
    const AIScreen(),
    const CartScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: _currentIndex == 0 ? _buildHomeContent() : _pages[_currentIndex],
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          boxShadow: [
             BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(Icons.home, "Home", 0),
            _buildNavItem(Icons.favorite_border, "Wishlist", 1),
            _buildNavItem(FontAwesomeIcons.wandMagicSparkles, "AI", 2),
            _buildNavItem(Icons.shopping_cart_outlined, "Cart", 3),
            _buildNavItem(Icons.person_outline, "Profile", 4),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeContent() {
    final theme = Theme.of(context);
    return SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                // --- Header ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.welcomeMessage,
                          style: TextStyle(
                            fontSize: 14,
                            color: theme.textTheme.bodySmall?.color,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _userName,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: theme.textTheme.titleLarge?.color,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Consumer<LanguageProvider>(
                          builder: (context, languageProvider, child) {
                            return PopupMenuButton<Locale>(
                              onSelected: (Locale locale) {
                                languageProvider.changeLanguage(locale);
                              },
                              icon: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: theme.cardColor,
                                  border: Border.all(color: theme.dividerColor.withOpacity(0.5)),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.language, size: 20),
                              ),
                              itemBuilder: (BuildContext context) => <PopupMenuEntry<Locale>>[
                                const PopupMenuItem<Locale>(
                                  value: Locale('en'),
                                  child: Text('English'),
                                ),
                                const PopupMenuItem<Locale>(
                                  value: Locale('hi'),
                                  child: Text('हिंदी'),
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(width: 10),
                        Consumer<NotificationProvider>(
                          builder: (context, notificationProvider, child) {
                            final unreadCount = notificationProvider.unreadCount;
                            return Stack(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFB8C00).withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: IconButton(
                                    icon: const Icon(Icons.notifications_none, color: Color(0xFFFB8C00), size: 30),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (context) => const NotificationScreen()),
                                      );
                                    },
                                  ),
                                ),
                                if (unreadCount > 0)
                                  Positioned(
                                    right: 8,
                                    top: 8,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                      constraints: const BoxConstraints(
                                        minWidth: 16,
                                        minHeight: 16,
                                      ),
                                      child: Text(
                                        unreadCount > 9 ? '9+' : unreadCount.toString(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
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
                  ],
                ),
                const SizedBox(height: 20),

                // --- Search Bar ---
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SearchScreen()),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                      border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
                    ),
                    child: IgnorePointer(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: AppLocalizations.of(context)!.search,
                          hintStyle: TextStyle(color: theme.hintColor),
                          icon: Icon(Icons.search, color: theme.hintColor),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 25),

                // --- Categories ---
                _buildSectionHeader("Categories", () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AllCategoriesScreen()),
                  );
                }),
                const SizedBox(height: 15),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildCategoryItem("Electronics", Icons.phone_android),
                      _buildCategoryItem("Fashion", FontAwesomeIcons.shirt),
                      _buildCategoryItem("Home", Icons.home_outlined),
                      _buildCategoryItem("Books", FontAwesomeIcons.bookOpen),
                      _buildCategoryItem("Toys", FontAwesomeIcons.car),
                    ],
                  ),
                ),
                const SizedBox(height: 25),

                 // --- Recently Viewed ---
                _buildSectionHeader("Recently Viewed", () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const RecentlyViewedScreen()),
                  );
                }),
                 const SizedBox(height: 15),
                 _buildRecentlyViewedList(),

                const SizedBox(height: 25),

                // --- Featured Products ---
                _buildSectionHeader("Featured Products", () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const FeaturedProductsScreen()),
                  );
                }),
                const SizedBox(height: 15),
                _buildFeaturedProductsGrid(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      );
  }

  Widget _buildRecentlyViewedList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('products').orderBy('viewedAt', descending: true).limit(5).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox(height: 220);
        final docs = snapshot.data!.docs;
        return SizedBox(
          height: 220,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: docs.length,
            separatorBuilder: (context, index) => const SizedBox(width: 15),
            itemBuilder: (context, index) {
              final productData = docs[index].data() as Map<String, dynamic>;
              return _buildProductCard(docs[index].id, productData, width: 150, isFeatured: false);
            },
          ),
        );
      },
    );
  }

  Widget _buildFeaturedProductsGrid() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('products').limit(6).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const Center(child: Text("Something went wrong"));
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

        final docs = snapshot.data?.docs ?? [];
        return GridView.builder(
          padding: EdgeInsets.zero,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.65,
            crossAxisSpacing: 15,
            mainAxisSpacing: 15,
          ),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final productData = docs[index].data() as Map<String, dynamic>;
            return _buildProductCard(docs[index].id, productData, isFeatured: true);
          },
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, VoidCallback onSeeAll) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.titleLarge?.color,
          ),
        ),
        TextButton(
          onPressed: onSeeAll,
          child: const Text(
            "See All",
            style: TextStyle(
              color: Color(0xFFFB8C00),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryItem(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(right: 25.0),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFFFB8C00), size: 28),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(String productId, Map<String, dynamic> data, {double? width, required bool isFeatured}) {
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
        width: width,
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(12),
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
              flex: 5,
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.disabledColor.withOpacity(0.05),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    ),
                    child: firstImage != null
                        ? Image.network(
                            firstImage,
                            fit: BoxFit.contain,
                          )
                        : Icon(Icons.image_not_supported, color: theme.disabledColor, size: 40),
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
                            backgroundColor: theme.cardColor.withOpacity(0.8),
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
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data['name'] ?? 'Product Name',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: theme.textTheme.titleMedium?.color,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "₹${data['price'] ?? '0.00'}",
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFFFB8C00),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Row(
                            children: [
                              Text("4.5", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                              SizedBox(width: 2),
                              Icon(Icons.star, size: 10, color: Colors.white),
                            ],
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text("(120)", style: TextStyle(fontSize: 10, color: theme.hintColor)),
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

  Widget _buildNavItem(IconData icon, String label, int index) {
    bool isSelected = _currentIndex == index;
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected ? const Color(0xFFFB8C00) : Colors.grey,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: isSelected ? const Color(0xFFFB8C00) : Colors.grey,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

class HomeContent extends StatelessWidget {
  const HomeContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(); // Placeholder as logic handled in main class due to extraction method
  }
}

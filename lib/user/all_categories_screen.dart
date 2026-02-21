import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:reality_cart/user/search_screen.dart';

class AllCategoriesScreen extends StatelessWidget {
  const AllCategoriesScreen({super.key});

  final List<Map<String, dynamic>> _categories = const [
    {"name": "Electronics", "icon": Icons.phone_android, "color": Colors.blue},
    {"name": "Fashion", "icon": FontAwesomeIcons.shirt, "color": Colors.pink},
    {"name": "Home", "icon": Icons.home_outlined, "color": Colors.brown},
    {"name": "Books", "icon": FontAwesomeIcons.bookOpen, "color": Colors.green},
    {"name": "Toys", "icon": FontAwesomeIcons.car, "color": Colors.red},
    {"name": "Beauty", "icon": Icons.face_retouching_natural, "color": Colors.purple},
    {"name": "Sports", "icon": Icons.sports_basketball, "color": Colors.orange},
    {"name": "Grocery", "icon": Icons.local_grocery_store, "color": Colors.teal},
    {"name": "Automotive", "icon": Icons.directions_car, "color": Colors.blueGrey},
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const brandOrange = Color(0xFFFB8C00);

    return Scaffold(
      appBar: AppBar(
        title: const Text("All Categories", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(20),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 0.8,
          crossAxisSpacing: 15,
          mainAxisSpacing: 15,
        ),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          return GestureDetector(
            onTap: () {
              // Navigate to search/category results
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SearchScreen(), // You can pass category filter here later
                ),
              );
            },
            child: Column(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: (category['color'] as Color).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(
                        category['icon'] as IconData,
                        color: category['color'] as Color,
                        size: 30,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  category['name'],
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: theme.textTheme.bodyMedium?.color,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

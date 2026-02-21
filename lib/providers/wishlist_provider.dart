import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WishlistProvider extends ChangeNotifier {
  List<String> _wishlistItems = [];

  List<String> get wishlistItems => _wishlistItems;

  WishlistProvider() {
    _loadWishlist();
  }

  Future<void> _loadWishlist() async {
    final prefs = await SharedPreferences.getInstance();
    _wishlistItems = prefs.getStringList('wishlist') ?? [];
    notifyListeners();
  }

  Future<void> toggleWishlist(String productId) async {
    final prefs = await SharedPreferences.getInstance();
    if (_wishlistItems.contains(productId)) {
      _wishlistItems.remove(productId);
    } else {
      _wishlistItems.add(productId);
    }
    await prefs.setStringList('wishlist', _wishlistItems);
    notifyListeners();
  }

  bool isInWishlist(String productId) {
    return _wishlistItems.contains(productId);
  }
}

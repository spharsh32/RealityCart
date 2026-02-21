import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/cart_item.dart';

class CartProvider with ChangeNotifier {
  List<CartItem> _cartItems = [];
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  StreamSubscription? _cartSubscription;

  List<CartItem> get cartItems => _cartItems;

  CartProvider() {
    _initCartListener();
  }

  void _initCartListener() {
    _auth.authStateChanges().listen((user) {
      _cartSubscription?.cancel();
      if (user != null) {
        _cartSubscription = _db
            .collection('users')
            .doc(user.uid)
            .collection('cart')
            .snapshots()
            .listen((snapshot) {
          _cartItems = snapshot.docs.map((doc) => CartItem.fromMap(doc.data())).toList();
          notifyListeners();
        });
      } else {
        _cartItems = [];
        notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    _cartSubscription?.cancel();
    super.dispose();
  }

  Future<void> addToCart(String productId, String name, double price, String size, int color, {String? imageUrl}) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final cartDocId = "${productId}_${size}_$color";
    final docRef = _db.collection('users').doc(user.uid).collection('cart').doc(cartDocId);

    final doc = await docRef.get();
    if (doc.exists) {
      await docRef.update({'quantity': FieldValue.increment(1)});
    } else {
      final newItem = CartItem(
        id: productId,
        name: name,
        price: price,
        size: size,
        color: color,
        imageUrl: imageUrl,
        quantity: 1,
      );
      await docRef.set(newItem.toMap());
    }
  }

  Future<void> removeFromCart(CartItem item) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _db
        .collection('users')
        .doc(user.uid)
        .collection('cart')
        .doc("${item.id}_${item.size}_${item.color}")
        .delete();
  }

  Future<void> incrementQuantity(CartItem item) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _db
        .collection('users')
        .doc(user.uid)
        .collection('cart')
        .doc("${item.id}_${item.size}_${item.color}")
        .update({'quantity': FieldValue.increment(1)});
  }

  Future<void> decrementQuantity(CartItem item) async {
    final user = _auth.currentUser;
    if (user == null) return;

    if (item.quantity > 1) {
      await _db
          .collection('users')
          .doc(user.uid)
          .collection('cart')
          .doc("${item.id}_${item.size}_${item.color}")
          .update({'quantity': FieldValue.increment(-1)});
    } else {
      await removeFromCart(item);
    }
  }

  double get subtotal => _cartItems.fold(0.0, (sum, item) => sum + (item.price * item.quantity));
  double get tax => subtotal * 0.05;
  double get total => subtotal + tax;

  Future<void> clearCart() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final snapshots = await _db.collection('users').doc(user.uid).collection('cart').get();
    final batch = _db.batch();
    for (var doc in snapshots.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}

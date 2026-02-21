class CartItem {
  final String id;
  final String name;
  final double price;
  final String size;
  final int color; 
  final String? imageUrl;
  int quantity;

  CartItem({
    required this.id,
    required this.name,
    required this.price,
    required this.size,
    required this.color,
    this.imageUrl,
    this.quantity = 1,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'size': size,
      'color': color,
      'imageUrl': imageUrl,
      'quantity': quantity,
    };
  }

  factory CartItem.fromMap(Map<String, dynamic> map) {
    return CartItem(
      id: map['id'],
      name: map['name'],
      price: map['price'],
      size: map['size'],
      color: map['color'],
      imageUrl: map['imageUrl'],
      quantity: map['quantity'],
    );
  }
}

import 'package:flutter/foundation.dart';
import 'product.dart';

class CartItem {
  final Product product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});

  double get total => product.price * quantity;
}

class CartModel extends ChangeNotifier {
  CartModel._();
  static final instance = CartModel._();

  final List<CartItem> _items = [];

  List<CartItem> get items => _items;
  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);
  double get totalPrice => _items.fold(0.0, (sum, item) => sum + item.total);

  void addProduct(Product product) {
    final existing = _items
        .where((i) => i.product.id == product.id)
        .firstOrNull;
    if (existing != null) {
      existing.quantity++;
    } else {
      _items.add(CartItem(product: product));
    }
    notifyListeners();
  }

  void updateQuantity(int productId, int delta) {
    final item = _items.where((i) => i.product.id == productId).firstOrNull;
    if (item == null) return;
    item.quantity += delta;
    if (item.quantity <= 0) {
      _items.removeWhere((i) => i.product.id == productId);
    }
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}

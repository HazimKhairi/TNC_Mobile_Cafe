import 'package:flutter/material.dart';
import '../models/cart_item.dart';
import '../models/drink.dart';

class CartProvider extends ChangeNotifier {
  final List<CartItem> _items = [];

  List<CartItem> get items => List.unmodifiable(_items);
  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);
  double get totalAmount => _items.fold(0, (sum, item) => sum + item.totalPrice);

  bool get isEmpty => _items.isEmpty;

  void addItem({
    required Drink drink,
    required DrinkSize size,
    List<DrinkAddon> addons = const [],
    String sugarLevel = '100%',
    String iceLevel = 'Normal',
    String? specialInstructions,
    int quantity = 1,
  }) {
    _items.add(CartItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      drink: drink,
      selectedSize: size,
      selectedAddons: addons,
      sugarLevel: sugarLevel,
      iceLevel: iceLevel,
      specialInstructions: specialInstructions,
      quantity: quantity,
    ));
    notifyListeners();
  }

  void removeItem(String itemId) {
    _items.removeWhere((item) => item.id == itemId);
    notifyListeners();
  }

  void updateQuantity(String itemId, int newQuantity) {
    final index = _items.indexWhere((item) => item.id == itemId);
    if (index != -1) {
      if (newQuantity <= 0) {
        _items.removeAt(index);
      } else {
        _items[index].quantity = newQuantity;
      }
      notifyListeners();
    }
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}

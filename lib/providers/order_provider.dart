import 'dart:async';
import 'package:flutter/material.dart';
import '../models/cart_item.dart';
import '../models/order.dart';
import '../services/firestore_service.dart';

class OrderProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  List<Order> _orders = [];
  StreamSubscription? _subscription;
  String? _userId;
  bool _isAdmin = false;

  List<Order> get orders => List.unmodifiable(_orders);

  List<Order> get activeOrders => _orders
      .where((o) =>
          o.status == OrderStatus.preparing || o.status == OrderStatus.ready)
      .toList();

  List<Order> get completedOrders => _orders
      .where((o) =>
          o.status == OrderStatus.completed ||
          o.status == OrderStatus.cancelled)
      .toList();

  double get todayRevenue {
    final today = DateTime.now();
    return _orders
        .where((o) =>
            o.createdAt.year == today.year &&
            o.createdAt.month == today.month &&
            o.createdAt.day == today.day &&
            o.status == OrderStatus.completed)
        .fold(0, (sum, o) => sum + o.totalAmount);
  }

  int get todayOrderCount {
    final today = DateTime.now();
    return _orders
        .where((o) =>
            o.createdAt.year == today.year &&
            o.createdAt.month == today.month &&
            o.createdAt.day == today.day)
        .length;
  }

  Map<String, double> get weeklySales {
    final now = DateTime.now();
    final Map<String, double> sales = {};
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dayName = days[date.weekday - 1];
      sales[dayName] = _orders
          .where((o) =>
              o.createdAt.year == date.year &&
              o.createdAt.month == date.month &&
              o.createdAt.day == date.day &&
              o.status == OrderStatus.completed)
          .fold(0, (sum, o) => sum + o.totalAmount);
    }
    return sales;
  }

  Map<String, int> get topSellingItems {
    final Map<String, int> itemCounts = {};
    for (final order
        in _orders.where((o) => o.status == OrderStatus.completed)) {
      for (final item in order.items) {
        itemCounts[item.drink.name] =
            (itemCounts[item.drink.name] ?? 0) + item.quantity;
      }
    }
    final sorted = itemCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Map.fromEntries(sorted.take(5));
  }

  void updateAuth(String? userId, bool isAdmin) {
    if (userId == _userId && isAdmin == _isAdmin) return;

    _userId = userId;
    _isAdmin = isAdmin;
    _subscription?.cancel();

    if (userId == null) {
      _orders = [];
      notifyListeners();
      return;
    }

    final stream = isAdmin
        ? _firestoreService.getOrdersStream()
        : _firestoreService.getUserOrdersStream(userId);

    _subscription = stream.listen((orders) {
      _orders = orders;
      notifyListeners();
    });
  }

  Future<Order> placeOrder(
    List<CartItem> items,
    double totalAmount, {
    String? customerName,
    String? userId,
    String orderType = 'dine_in',
    int? tableNumber,
  }) async {
    final orderNumber = await _firestoreService.getNextOrderNumber();

    final order = Order(
      id: '',
      items: List.from(items),
      totalAmount: totalAmount,
      createdAt: DateTime.now(),
      orderNumber: orderNumber,
      customerName: customerName,
      userId: userId,
      orderType: orderType,
      tableNumber: tableNumber,
    );

    final docId = await _firestoreService.createOrder(order);

    return Order(
      id: docId,
      items: order.items,
      totalAmount: order.totalAmount,
      createdAt: order.createdAt,
      orderNumber: order.orderNumber,
      customerName: order.customerName,
      userId: order.userId,
      orderType: order.orderType,
      tableNumber: order.tableNumber,
    );
  }

  Future<void> updateOrderStatus(String orderId, OrderStatus status) async {
    await _firestoreService.updateOrderStatus(orderId, status);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

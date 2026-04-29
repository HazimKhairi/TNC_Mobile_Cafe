import 'dart:async';
import 'package:flutter/material.dart';
import '../models/cart_item.dart';
import '../models/notification_model.dart';
import '../models/order.dart';
import '../services/firestore_service.dart';

class OrderProvider extends ChangeNotifier {
  static const Duration paymentVerificationWindow = Duration(hours: 1);

  final FirestoreService _firestoreService = FirestoreService();
  List<Order> _orders = [];
  StreamSubscription? _subscription;
  String? _userId;
  bool _isAdmin = false;

  List<Order> get orders => List.unmodifiable(_orders);

  /// Active = preparing or ready, AND payment must be approved.
  List<Order> get activeOrders => _orders
      .where((o) =>
          o.isPaymentApproved &&
          (o.status == OrderStatus.preparing ||
              o.status == OrderStatus.ready))
      .toList();

  List<Order> get completedOrders => _orders
      .where((o) =>
          o.status == OrderStatus.completed ||
          o.status == OrderStatus.cancelled)
      .toList();

  /// Orders awaiting payment verification (admin view).
  List<Order> get pendingVerificationOrders => _orders
      .where((o) => o.isPaymentPending)
      .toList();

  int get pendingVerificationCount => pendingVerificationOrders.length;

  /// Customer-facing: orders that need re-upload (rejected) or are pending.
  List<Order> get awaitingPaymentOrders => _orders
      .where((o) => o.isPaymentPending || o.isPaymentRejected)
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

    _subscription = stream.listen(
      (orders) {
        _orders = orders;
        _autoExpireStaleOrders();
        notifyListeners();
      },
      onError: (_) {
        // Firestore permission error — keep existing orders in memory
      },
    );
  }

  /// Sweeps for any pending-verification order whose window has elapsed.
  void _autoExpireStaleOrders() {
    final now = DateTime.now();
    for (final order in _orders) {
      if (!order.isPaymentPending) continue;
      final expiresAt = order.paymentExpiresAt;
      if (expiresAt == null) continue;
      if (now.isBefore(expiresAt)) continue;

      // Fire and forget — best-effort expiry
      _firestoreService.expirePayment(order.id).catchError((_) {});
      if (order.userId != null) {
        _firestoreService
            .createNotification(AppNotification(
              id: '',
              userId: order.userId!,
              title:
                  'Order #${order.orderNumber.toString().padLeft(3, '0')} Cancelled',
              body: 'Payment verification window expired. Please reorder.',
              type: NotificationType.orderUpdate,
              createdAt: DateTime.now(),
              orderId: order.id,
              orderNumber: order.orderNumber,
            ))
            .catchError((_) {});
      }
    }
  }

  Future<Order> placeOrder(
    List<CartItem> items,
    double totalAmount, {
    String? customerName,
    String? userId,
    String orderType = 'dine_in',
    int? tableNumber,
    String? receiptUrl,
    String? receiptType,
  }) async {
    int orderNumber;
    try {
      orderNumber = await _firestoreService.getNextOrderNumber();
    } catch (_) {
      // Firestore read failed — derive from local orders
      orderNumber = _orders.isEmpty
          ? 1
          : _orders.map((o) => o.orderNumber).reduce((a, b) => a > b ? a : b) + 1;
    }

    final now = DateTime.now();
    final order = Order(
      id: '',
      items: List.from(items),
      totalAmount: totalAmount,
      createdAt: now,
      orderNumber: orderNumber,
      customerName: customerName,
      userId: userId,
      orderType: orderType,
      tableNumber: tableNumber,
      receiptUrl: receiptUrl,
      receiptType: receiptType,
      paymentStatus: PaymentStatus.pendingVerification,
      paymentExpiresAt: now.add(paymentVerificationWindow),
    );

    String docId = '';
    try {
      docId = await _firestoreService.createOrder(order);
    } catch (_) {
      // Firestore write failed — keep order locally with a generated id
      docId = 'local_${DateTime.now().millisecondsSinceEpoch}';
    }

    final placedOrder = Order(
      id: docId,
      items: order.items,
      totalAmount: order.totalAmount,
      createdAt: order.createdAt,
      orderNumber: order.orderNumber,
      customerName: order.customerName,
      userId: order.userId,
      orderType: order.orderType,
      tableNumber: order.tableNumber,
      receiptUrl: order.receiptUrl,
      receiptType: order.receiptType,
      paymentStatus: order.paymentStatus,
      paymentExpiresAt: order.paymentExpiresAt,
    );

    // Add to local list so it shows immediately in Order History
    _orders = [placedOrder, ..._orders];
    notifyListeners();

    return placedOrder;
  }

  Future<void> updateOrderStatus(String orderId, OrderStatus status) async {
    await _firestoreService.updateOrderStatus(orderId, status);

    // Create notification for the order owner
    final order = _orders.where((o) => o.id == orderId).firstOrNull;
    if (order != null && order.userId != null) {
      final statusLabel = Order(
        id: '',
        items: [],
        totalAmount: 0,
        createdAt: DateTime.now(),
        orderNumber: 0,
        status: status,
      ).statusLabel;

      try {
        await _firestoreService.createNotification(AppNotification(
          id: '',
          userId: order.userId!,
          title: 'Order #${order.orderNumber.toString().padLeft(3, '0')} Updated',
          body: 'Your order is now $statusLabel',
          type: NotificationType.orderUpdate,
          createdAt: DateTime.now(),
          orderId: order.id,
          orderNumber: order.orderNumber,
        ));
      } catch (_) {}
    }
  }

  // ── Payment verification ──

  Future<void> approvePayment(String orderId, String adminUid) async {
    await _firestoreService.approvePayment(orderId, adminUid);

    final order = _orders.where((o) => o.id == orderId).firstOrNull;
    if (order != null && order.userId != null) {
      try {
        await _firestoreService.createNotification(AppNotification(
          id: '',
          userId: order.userId!,
          title:
              'Payment Approved — Order #${order.orderNumber.toString().padLeft(3, '0')}',
          body: 'Your payment has been verified. We are preparing your order.',
          type: NotificationType.orderUpdate,
          createdAt: DateTime.now(),
          orderId: order.id,
          orderNumber: order.orderNumber,
        ));
      } catch (_) {}
    }
  }

  Future<void> rejectPayment(String orderId, String reason) async {
    await _firestoreService.rejectPayment(orderId, reason);

    final order = _orders.where((o) => o.id == orderId).firstOrNull;
    if (order != null && order.userId != null) {
      try {
        await _firestoreService.createNotification(AppNotification(
          id: '',
          userId: order.userId!,
          title:
              'Payment Rejected — Order #${order.orderNumber.toString().padLeft(3, '0')}',
          body: 'Reason: $reason. Please re-upload a valid receipt.',
          type: NotificationType.orderUpdate,
          createdAt: DateTime.now(),
          orderId: order.id,
          orderNumber: order.orderNumber,
        ));
      } catch (_) {}
    }
  }

  Future<void> reuploadReceipt(
    String orderId, {
    required String receiptUrl,
    required String receiptType,
  }) async {
    final newExpiry = DateTime.now().add(paymentVerificationWindow);
    await _firestoreService.reuploadReceipt(
      orderId,
      receiptUrl: receiptUrl,
      receiptType: receiptType,
      paymentExpiresAt: newExpiry,
    );
  }

  Future<void> deleteOrder(String orderId) async {
    await _firestoreService.deleteOrder(orderId);
    _orders = _orders.where((o) => o.id != orderId).toList();
    notifyListeners();
  }

  Future<void> cancelOrder(String orderId) async {
    await updateOrderStatus(orderId, OrderStatus.cancelled);
  }

  Future<void> updateOrderItems(
    String orderId,
    List<CartItem> newItems,
    double newTotal, {
    String? orderType,
    int? tableNumber,
  }) async {
    final data = <String, dynamic>{
      'items': newItems.map((i) => i.toMap()).toList(),
      'totalAmount': newTotal,
    };
    if (orderType != null) data['orderType'] = orderType;
    if (tableNumber != null) data['tableNumber'] = tableNumber;

    await _firestoreService.updateOrder(orderId, data);

    final index = _orders.indexWhere((o) => o.id == orderId);
    if (index != -1) {
      final old = _orders[index];
      _orders[index] = Order(
        id: old.id,
        items: List.from(newItems),
        totalAmount: newTotal,
        createdAt: old.createdAt,
        status: old.status,
        customerName: old.customerName,
        orderNumber: old.orderNumber,
        userId: old.userId,
        orderType: orderType ?? old.orderType,
        tableNumber: tableNumber ?? old.tableNumber,
        receiptUrl: old.receiptUrl,
        receiptType: old.receiptType,
        paymentStatus: old.paymentStatus,
        rejectionReason: old.rejectionReason,
        paymentExpiresAt: old.paymentExpiresAt,
        approvedBy: old.approvedBy,
        approvedAt: old.approvedAt,
      );
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

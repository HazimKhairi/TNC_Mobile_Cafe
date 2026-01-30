import 'package:cloud_firestore/cloud_firestore.dart';
import 'cart_item.dart';

enum OrderStatus { preparing, ready, completed, cancelled }

class Order {
  final String id;
  final List<CartItem> items;
  final double totalAmount;
  final DateTime createdAt;
  OrderStatus status;
  final String? customerName;
  final int orderNumber;
  final String? userId;
  final String orderType; // "dine_in" or "takeaway"
  final int? tableNumber;

  Order({
    required this.id,
    required this.items,
    required this.totalAmount,
    required this.createdAt,
    this.status = OrderStatus.preparing,
    this.customerName,
    required this.orderNumber,
    this.userId,
    this.orderType = 'dine_in',
    this.tableNumber,
  });

  String get statusLabel {
    switch (status) {
      case OrderStatus.preparing:
        return 'Preparing';
      case OrderStatus.ready:
        return 'Ready for Pickup';
      case OrderStatus.completed:
        return 'Completed';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'customerName': customerName,
        'orderNumber': orderNumber,
        'totalAmount': totalAmount,
        'status': status.name,
        'orderType': orderType,
        'tableNumber': tableNumber,
        'createdAt': Timestamp.fromDate(createdAt),
        'items': items.map((i) => i.toMap()).toList(),
      };

  factory Order.fromMap(Map<String, dynamic> map) {
    final itemsList = (map['items'] as List<dynamic>?)
            ?.map((i) => CartItem.fromMap(Map<String, dynamic>.from(i)))
            .toList() ??
        [];

    return Order(
      id: map['id'] as String? ?? '',
      items: itemsList,
      totalAmount: (map['totalAmount'] as num).toDouble(),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      status: OrderStatus.values.firstWhere(
        (s) => s.name == (map['status'] as String?),
        orElse: () => OrderStatus.preparing,
      ),
      customerName: map['customerName'] as String?,
      orderNumber: (map['orderNumber'] as num?)?.toInt() ?? 0,
      userId: map['userId'] as String?,
      orderType: map['orderType'] as String? ?? 'dine_in',
      tableNumber: (map['tableNumber'] as num?)?.toInt(),
    );
  }
}

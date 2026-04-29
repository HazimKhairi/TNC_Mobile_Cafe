import 'package:cloud_firestore/cloud_firestore.dart';
import 'cart_item.dart';

enum OrderStatus { preparing, ready, completed, cancelled }

enum PaymentStatus { pendingVerification, approved, rejected, expired }

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

  // Payment fields
  final String? receiptUrl;
  final String? receiptType; // "image" or "pdf"
  final PaymentStatus paymentStatus;
  final String? rejectionReason;
  final DateTime? paymentExpiresAt;
  final String? approvedBy;
  final DateTime? approvedAt;

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
    this.receiptUrl,
    this.receiptType,
    this.paymentStatus = PaymentStatus.pendingVerification,
    this.rejectionReason,
    this.paymentExpiresAt,
    this.approvedBy,
    this.approvedAt,
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

  String get paymentStatusLabel {
    switch (paymentStatus) {
      case PaymentStatus.pendingVerification:
        return 'Pending Verification';
      case PaymentStatus.approved:
        return 'Payment Approved';
      case PaymentStatus.rejected:
        return 'Payment Rejected';
      case PaymentStatus.expired:
        return 'Payment Expired';
    }
  }

  bool get isPaymentApproved => paymentStatus == PaymentStatus.approved;
  bool get isPaymentRejected => paymentStatus == PaymentStatus.rejected;
  bool get isPaymentPending =>
      paymentStatus == PaymentStatus.pendingVerification;
  bool get isPaymentExpired => paymentStatus == PaymentStatus.expired;

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
        'receiptUrl': receiptUrl,
        'receiptType': receiptType,
        'paymentStatus': paymentStatus.name,
        'rejectionReason': rejectionReason,
        'paymentExpiresAt': paymentExpiresAt != null
            ? Timestamp.fromDate(paymentExpiresAt!)
            : null,
        'approvedBy': approvedBy,
        'approvedAt':
            approvedAt != null ? Timestamp.fromDate(approvedAt!) : null,
      };

  factory Order.fromMap(Map<String, dynamic> map) {
    final itemsList = (map['items'] as List<dynamic>?)
            ?.map((i) => CartItem.fromMap(Map<String, dynamic>.from(i)))
            .toList() ??
        [];

    DateTime? toDate(dynamic value) {
      if (value == null) return null;
      if (value is Timestamp) return value.toDate();
      return null;
    }

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
      receiptUrl: map['receiptUrl'] as String?,
      receiptType: map['receiptType'] as String?,
      paymentStatus: PaymentStatus.values.firstWhere(
        (p) => p.name == (map['paymentStatus'] as String?),
        orElse: () => PaymentStatus.pendingVerification,
      ),
      rejectionReason: map['rejectionReason'] as String?,
      paymentExpiresAt: toDate(map['paymentExpiresAt']),
      approvedBy: map['approvedBy'] as String?,
      approvedAt: toDate(map['approvedAt']),
    );
  }
}

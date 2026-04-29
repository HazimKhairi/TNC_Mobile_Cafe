import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import '../models/app_user.dart';
import '../models/drink.dart';
import '../models/notification_model.dart';
import '../models/order.dart';
import '../data/mock_data.dart';

class FirestoreService {
  final _db = FirebaseFirestore.instance;

  // ── Users ──

  Future<void> createUser(AppUser user) =>
      _db.collection('users').doc(user.uid).set(user.toMap());

  Future<void> updateUserDisplayName(String uid, String displayName) =>
      _db.collection('users').doc(uid).update({'displayName': displayName});

  Future<AppUser?> getUser(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists || doc.data() == null) return null;
    return AppUser.fromMap(doc.data()!);
  }

  Future<void> deleteUser(String uid) =>
      _db.collection('users').doc(uid).delete();

  // ── Orders ──

  Future<String> createOrder(Order order) async {
    final ref = await _db.collection('orders').add(order.toMap());
    return ref.id;
  }

  Future<void> updateOrderStatus(String orderId, OrderStatus status) =>
      _db.collection('orders').doc(orderId).update({'status': status.name});

  Future<void> deleteOrder(String orderId) =>
      _db.collection('orders').doc(orderId).delete();

  Future<void> updateOrder(String orderId, Map<String, dynamic> data) =>
      _db.collection('orders').doc(orderId).update(data);

  // ── Payment Verification ──

  Future<void> approvePayment(String orderId, String adminUid) =>
      _db.collection('orders').doc(orderId).update({
        'paymentStatus': PaymentStatus.approved.name,
        'approvedBy': adminUid,
        'approvedAt': Timestamp.now(),
        'rejectionReason': null,
      });

  Future<void> rejectPayment(String orderId, String reason) =>
      _db.collection('orders').doc(orderId).update({
        'paymentStatus': PaymentStatus.rejected.name,
        'rejectionReason': reason,
      });

  Future<void> reuploadReceipt(
    String orderId, {
    required String receiptUrl,
    required String receiptType,
    required DateTime paymentExpiresAt,
  }) =>
      _db.collection('orders').doc(orderId).update({
        'receiptUrl': receiptUrl,
        'receiptType': receiptType,
        'paymentStatus': PaymentStatus.pendingVerification.name,
        'rejectionReason': null,
        'paymentExpiresAt': Timestamp.fromDate(paymentExpiresAt),
      });

  Future<void> expirePayment(String orderId) =>
      _db.collection('orders').doc(orderId).update({
        'paymentStatus': PaymentStatus.expired.name,
        'status': OrderStatus.cancelled.name,
      });

  Stream<List<Order>> getPendingVerificationOrdersStream() => _db
      .collection('orders')
      .where('paymentStatus',
          isEqualTo: PaymentStatus.pendingVerification.name)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snap) => snap.docs
          .map((d) => Order.fromMap({...d.data(), 'id': d.id}))
          .toList());

  Stream<List<Order>> getOrdersStream() => _db
      .collection('orders')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snap) => snap.docs
          .map((d) => Order.fromMap({...d.data(), 'id': d.id}))
          .toList());

  Stream<List<Order>> getUserOrdersStream(String userId) => _db
      .collection('orders')
      .where('userId', isEqualTo: userId)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snap) => snap.docs
          .map((d) => Order.fromMap({...d.data(), 'id': d.id}))
          .toList());

  Future<int> getNextOrderNumber() async {
    final snap = await _db
        .collection('orders')
        .orderBy('orderNumber', descending: true)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return 1;
    return ((snap.docs.first.data()['orderNumber'] as num?)?.toInt() ?? 0) + 1;
  }

  // ── Categories ──

  Stream<List<DrinkCategory>> getCategoriesStream() => _db
      .collection('categories')
      .orderBy('name')
      .snapshots()
      .map((snap) => snap.docs
          .map((d) => DrinkCategory.fromMap({...d.data(), 'id': d.id}))
          .toList());

  Future<String> addCategory(DrinkCategory category) async {
    final ref = await _db.collection('categories').add({
      'name': category.name,
      'icon': category.icon,
    });
    return ref.id;
  }

  Future<void> updateCategory(DrinkCategory category) => _db
      .collection('categories')
      .doc(category.id)
      .update({'name': category.name, 'icon': category.icon});

  Future<void> deleteCategory(String categoryId) =>
      _db.collection('categories').doc(categoryId).delete();

  // ── Drinks ──

  Stream<List<Drink>> getDrinksStream() => _db
      .collection('drinks')
      .orderBy('name')
      .snapshots()
      .map((snap) => snap.docs
          .map((d) => Drink.fromMap({...d.data(), 'id': d.id}))
          .toList());

  Future<String> addDrink(Drink drink) async {
    final ref = await _db.collection('drinks').add(drink.toMap());
    return ref.id;
  }

  Future<void> updateDrink(String drinkId, Map<String, dynamic> data) =>
      _db.collection('drinks').doc(drinkId).update(data);

  Future<void> deleteDrink(String drinkId) =>
      _db.collection('drinks').doc(drinkId).delete();

  // ── Notifications ──

  Stream<List<AppNotification>> getUserNotifications(String userId) => _db
      .collection('notifications')
      .where('userId', whereIn: [userId, 'all'])
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snap) => snap.docs
          .map((d) => AppNotification.fromMap({...d.data(), 'id': d.id}))
          .toList());

  Future<void> createNotification(AppNotification notification) =>
      _db.collection('notifications').add(notification.toMap());

  Future<void> markNotificationRead(String notificationId) =>
      _db.collection('notifications').doc(notificationId).update({'isRead': true});

  Future<void> markAllNotificationsRead(String userId) async {
    final snap = await _db
        .collection('notifications')
        .where('userId', whereIn: [userId, 'all'])
        .where('isRead', isEqualTo: false)
        .get();
    final batch = _db.batch();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  // ── Seed Data ──

  Future<void> seedMenuData() async {
    final batch = _db.batch();

    // Seed categories (skip 'all')
    for (final cat in MockData.categories) {
      if (cat.id == 'all') continue;
      final ref = _db.collection('categories').doc(cat.id);
      batch.set(ref, {'name': cat.name, 'icon': cat.icon});
    }

    // Seed drinks
    for (final drink in MockData.drinks) {
      final ref = _db.collection('drinks').doc(drink.id);
      batch.set(ref, drink.toMap());
    }

    await batch.commit();
  }
}

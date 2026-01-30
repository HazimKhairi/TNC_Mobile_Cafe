import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import '../models/app_user.dart';
import '../models/order.dart';

class FirestoreService {
  final _db = FirebaseFirestore.instance;

  // ── Users ──

  Future<void> createUser(AppUser user) =>
      _db.collection('users').doc(user.uid).set(user.toMap());

  Future<AppUser?> getUser(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists || doc.data() == null) return null;
    return AppUser.fromMap(doc.data()!);
  }

  // ── Orders ──

  Future<String> createOrder(Order order) async {
    final ref = await _db.collection('orders').add(order.toMap());
    return ref.id;
  }

  Future<void> updateOrderStatus(String orderId, OrderStatus status) =>
      _db.collection('orders').doc(orderId).update({'status': status.name});

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
}

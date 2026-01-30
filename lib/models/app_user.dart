import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String uid;
  final String email;
  final String displayName;
  final String role;
  final DateTime createdAt;

  AppUser({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.role,
    required this.createdAt,
  });

  bool get isAdmin => role == 'admin';

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'email': email,
        'displayName': displayName,
        'role': role,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  factory AppUser.fromMap(Map<String, dynamic> map) => AppUser(
        uid: map['uid'] as String,
        email: map['email'] as String,
        displayName: map['displayName'] as String,
        role: (map['role'] as String?) ?? 'user',
        createdAt: (map['createdAt'] as Timestamp).toDate(),
      );
}

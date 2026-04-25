import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/app_user.dart';

/// Pre-seeded test accounts for quick login during development & demo.
///
/// These accounts are auto-created on first use via [ensureAndLogin].
class TestAccounts {
  static const adminEmail = 'admin@tnccafe.my';
  static const adminPassword = 'admin1234';
  static const adminName = 'TNC Admin';

  static const customerEmail = 'customer@tnccafe.my';
  static const customerPassword = 'customer1234';
  static const customerName = 'Demo Customer';

  /// Login as the given role. If the account doesn't exist yet, creates it
  /// in Firebase Auth + Firestore (with correct role) before logging in.
  ///
  /// [role] must be `'admin'` or `'user'`.
  static Future<void> ensureAndLogin(String role) async {
    final auth = FirebaseAuth.instance;
    final db = FirebaseFirestore.instance;

    final isAdmin = role == 'admin';
    final email = isAdmin ? adminEmail : customerEmail;
    final password = isAdmin ? adminPassword : customerPassword;
    final name = isAdmin ? adminName : customerName;

    // Try login first
    try {
      await auth.signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' ||
          e.code == 'invalid-credential' ||
          e.code == 'invalid-login-credentials') {
        // Account doesn't exist — create it
        final cred = await auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        final user = AppUser(
          uid: cred.user!.uid,
          email: email,
          displayName: name,
          role: role,
          createdAt: DateTime.now(),
        );
        try {
          await db.collection('users').doc(user.uid).set(user.toMap());
        } catch (_) {
          // Firestore write may fail (rules) — Auth account still works
        }
        return;
      }
      rethrow;
    }

    // Already logged in — make sure the Firestore doc reflects the role.
    // (Useful when an old account exists with role='user' and we want admin.)
    final uid = auth.currentUser?.uid;
    if (uid != null) {
      try {
        final doc = await db.collection('users').doc(uid).get();
        if (!doc.exists) {
          await db.collection('users').doc(uid).set(AppUser(
                uid: uid,
                email: email,
                displayName: name,
                role: role,
                createdAt: DateTime.now(),
              ).toMap());
        } else if ((doc.data()?['role'] as String?) != role) {
          await db.collection('users').doc(uid).update({'role': role});
        }
      } catch (_) {
        // Ignore Firestore failures
      }
    }
  }
}

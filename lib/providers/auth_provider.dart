import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/app_user.dart';
import '../services/firestore_service.dart';

enum AuthState { loading, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestoreService = FirestoreService();

  AuthState _state = AuthState.loading;
  AppUser? _currentUser;
  StreamSubscription<User?>? _authSubscription;

  AuthProvider() {
    _authSubscription = _auth.authStateChanges().listen(_onAuthChanged);
  }

  AuthState get state => _state;
  AppUser? get currentUser => _currentUser;
  bool get isAdmin => _currentUser?.isAdmin ?? false;
  bool get isLoggedIn => _state == AuthState.authenticated;

  Future<void> _onAuthChanged(User? firebaseUser) async {
    if (firebaseUser == null) {
      _currentUser = null;
      _state = AuthState.unauthenticated;
    } else {
      final appUser = await _firestoreService.getUser(firebaseUser.uid);
      _currentUser = appUser;
      _state = appUser != null
          ? AuthState.authenticated
          : AuthState.unauthenticated;
    }
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> register(String name, String email, String password) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final user = AppUser(
      uid: credential.user!.uid,
      email: email.trim(),
      displayName: name.trim(),
      role: 'user',
      createdAt: DateTime.now(),
    );

    await _firestoreService.createUser(user);
    _currentUser = user;
    _state = AuthState.authenticated;
    notifyListeners();
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}

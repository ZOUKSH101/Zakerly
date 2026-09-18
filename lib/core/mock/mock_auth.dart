import 'package:flutter/foundation.dart';

import '../models.dart';
import '../services.dart';

/// Stand-in for Firebase Auth. Accepts any credentials.
class MockAuth implements AuthService {
  final _user = ValueNotifier<AppUser?>(null);

  @override
  ValueListenable<AppUser?> get user => _user;

  @override
  Future<void> signInWithEmail(String email, String password) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    final name = email.contains('@') ? email.split('@').first : 'Student';
    _user.value = AppUser(uid: 'demo', name: name, email: email);
  }

  @override
  Future<void> signInWithGoogle() async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    _user.value = const AppUser(uid: 'demo', name: 'Demo Student', email: 'student@eui.edu.eg');
  }

  @override
  Future<void> signOut() async => _user.value = null;
}

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';

final storageServiceProvider = Provider<StorageService>((ref) {
  if (Firebase.apps.isNotEmpty) {
    try {
      return StorageService(storage: FirebaseStorage.instance);
    } catch (_) {}
  }
  return StorageService();
});

final authServiceProvider = Provider<AuthService>((ref) {
  final storage = ref.watch(storageServiceProvider);
  if (Firebase.apps.isNotEmpty) {
    try {
      return AuthService(
        auth: FirebaseAuth.instance,
        firestore: FirebaseFirestore.instance,
        storageService: storage,
      );
    } catch (_) {}
  }
  return AuthService(storageService: storage);
});

class AuthNotifier extends StateNotifier<UserModel?> {
  final AuthService _authService;

  AuthNotifier(this._authService) : super(_authService.currentUser) {
    _authService.authStateChanges.listen((user) {
      state = user;
    });
  }

  Future<void> signUp({
    required String name,
    required String email,
    required String password,
    required String phone,
    required UserRole role,
    XFile? profileImageFile,
  }) async {
    final user = await _authService.registerUser(
      name: name,
      email: email,
      password: password,
      phone: phone,
      role: role,
      profileImageFile: profileImageFile,
    );
    state = user;
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    final user = await _authService.signIn(
      email: email,
      password: password,
    );
    state = user;
  }

  void loginAsDemo(UserRole role) {
    _authService.signInAsDemo(role);
    state = _authService.currentUser;
  }

  void switchRole(UserRole newRole) {
    _authService.switchRole(newRole);
    state = _authService.currentUser;
  }

  Future<void> signOut() async {
    await _authService.signOut();
    state = null;
  }
}

final authNotifierProvider = StateNotifierProvider<AuthNotifier, UserModel?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return AuthNotifier(authService);
});

final currentUserProvider = Provider<UserModel?>((ref) {
  return ref.watch(authNotifierProvider);
});

final userRoleProvider = Provider<UserRole?>((ref) {
  return ref.watch(currentUserProvider)?.role;
});

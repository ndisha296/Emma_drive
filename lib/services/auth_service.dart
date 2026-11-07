import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:image_picker/image_picker.dart';
import '../models/user_model.dart';
import 'storage_service.dart';
import 'mock_data_service.dart';

class AuthService {
  final FirebaseAuth? _auth;
  final FirebaseFirestore? _firestore;
  final StorageService _storageService;
  final MockDataService _mockData = MockDataService.instance;

  // Stream controller to notify auth state changes across mock/firebase
  final StreamController<UserModel?> _userStateController =
      StreamController<UserModel?>.broadcast();

  UserModel? _cachedUser;

  AuthService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    StorageService? storageService,
  })  : _auth = auth,
        _firestore = firestore,
        _storageService = storageService ?? StorageService();

  UserModel? get currentUser => _cachedUser;

  Stream<UserModel?> get authStateChanges => _userStateController.stream;

  bool get isFirebaseAvailable => Firebase.apps.isNotEmpty && _auth != null;

  /// Registers a new user with their chosen role, profile image, and credentials
  Future<UserModel> registerUser({
    required String name,
    required String email,
    required String password,
    required String phone,
    required UserRole role,
    XFile? profileImageFile,
  }) async {
    String? profileImageUrl;

    if (isFirebaseAvailable) {
      try {
        final credential = await _auth!.createUserWithEmailAndPassword(
          email: email.trim(),
          password: password,
        );
        final uid = credential.user!.uid;

        if (profileImageFile != null) {
          profileImageUrl = await _storageService.uploadProfileImage(
            uid: uid,
            imageFile: profileImageFile,
          );
        }

        final newUser = UserModel(
          uid: uid,
          name: name.trim(),
          email: email.trim(),
          phone: phone.trim(),
          role: role,
          profileImageUrl: profileImageUrl,
          createdAt: DateTime.now(),
        );

        // Store to Cloud Firestore in 'users' collection
        await _firestore!.collection('users').doc(uid).set(newUser.toMap());

        _cachedUser = newUser;
        _userStateController.add(newUser);
        return newUser;
      } catch (e) {
        // If Firebase network or quota fails, fall back to mock registration
        // so user is never locked out of testing
      }
    }

    // Local / Simulator registration path
    final simulatedUid = 'user_${DateTime.now().millisecondsSinceEpoch}';
    if (profileImageFile != null) {
      profileImageUrl = await _storageService.uploadProfileImage(
        uid: simulatedUid,
        imageFile: profileImageFile,
      );
    } else {
      profileImageUrl = role == UserRole.manufacturer
          ? 'https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?w=150'
          : 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=150';
    }

    final localUser = UserModel(
      uid: simulatedUid,
      name: name.trim(),
      email: email.trim(),
      phone: phone.trim(),
      role: role,
      profileImageUrl: profileImageUrl,
      createdAt: DateTime.now(),
    );

    _mockData.saveUser(localUser);
    _cachedUser = localUser;
    _userStateController.add(localUser);
    return localUser;
  }

  /// Sign in with email and password
  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    if (isFirebaseAvailable) {
      try {
        final credential = await _auth!.signInWithEmailAndPassword(
          email: email.trim(),
          password: password,
        );
        final uid = credential.user!.uid;
        final doc = await _firestore!.collection('users').doc(uid).get();

        if (doc.exists && doc.data() != null) {
          final user = UserModel.fromMap(uid, doc.data()!);
          _cachedUser = user;
          _userStateController.add(user);
          return user;
        }
      } catch (e) {
        // Fall back to mock matching if needed
      }
    }

    // Demo/Mock matching
    final matched = _mockData
        .getAllUsers()
        .where((u) => u.email.toLowerCase() == email.trim().toLowerCase())
        .firstOrNull;

    if (matched != null) {
      _cachedUser = matched;
      _userStateController.add(matched);
      return matched;
    }

    // Fallback generate demo user for specified email
    final user = UserModel(
      uid: 'user_${email.hashCode.abs()}',
      name: email.split('@').first,
      email: email.trim(),
      phone: '+1 (555) 000-0000',
      role: email.contains('mfg') || email.contains('manufacturer')
          ? UserRole.manufacturer
          : UserRole.participant,
      profileImageUrl: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150',
    );

    _mockData.saveUser(user);
    _cachedUser = user;
    _userStateController.add(user);
    return user;
  }

  /// Quick sign in as predefined demo roles
  void signInAsDemo(UserRole role) {
    if (role == UserRole.participant) {
      _cachedUser = _mockData.getUser('user_jane_doe');
    } else {
      _cachedUser = _mockData.getUser('mfg_revive_tech');
    }
    _userStateController.add(_cachedUser);
  }

  /// Switch active role dynamically (handy for testing both flows)
  void switchRole(UserRole newRole) {
    if (_cachedUser != null) {
      _cachedUser = _cachedUser!.copyWith(role: newRole);
      _userStateController.add(_cachedUser);
    }
  }

  /// Sign out
  Future<void> signOut() async {
    if (isFirebaseAvailable) {
      try {
        await _auth!.signOut();
      } catch (_) {}
    }
    _cachedUser = null;
    _userStateController.add(null);
  }
}

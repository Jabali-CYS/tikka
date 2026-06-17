import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/config.dart';
import '../models/user_model.dart';

abstract class AuthRepository {
  Future<UserModel?> getCurrentUser();
  Future<void> sendOtp(String phone);
  Future<UserModel?> verifyOtp(String phone, String code);
  Future<void> logOut();
  Future<void> updatePoints(int newPoints);
}

class FirebaseAuthRepositoryImpl implements AuthRepository {
  final fb_auth.FirebaseAuth _auth = fb_auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<UserModel?> getCurrentUser() async {
    final fbUser = _auth.currentUser;
    if (fbUser == null) return null;

    final userDoc = await _firestore.collection('users').doc(fbUser.uid).get();
    if (userDoc.exists) {
      return UserModel.fromMap(userDoc.data()!, fbUser.uid);
    } else {
      final newUser = UserModel(
        uid: fbUser.uid,
        phone: fbUser.phoneNumber ?? "",
        name: "Loyal Customer",
        createdAt: DateTime.now(),
      );
      await _firestore.collection('users').doc(fbUser.uid).set(newUser.toMap());
      return newUser;
    }
  }

  String? _verificationId;

  @override
  Future<void> sendOtp(String phone) async {
    if (AppConfig.isProduction) {
      // Secure, production-only real path
      await _auth.verifyPhoneNumber(
        phoneNumber: phone,
        verificationCompleted: (fb_auth.PhoneAuthCredential credential) async {
          await _auth.signInWithCredential(credential);
        },
        verificationFailed: (fb_auth.FirebaseAuthException e) {
          throw Exception(e.message ?? "Phone verification failed");
        },
        codeSent: (String verificationId, int? resendToken) {
          _verificationId = verificationId;
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
      );
    } else {
      // Testing branch
      await Future.delayed(const Duration(milliseconds: 500));
    }
  }

  @override
  Future<UserModel?> verifyOtp(String phone, String code) async {
    if (AppConfig.isProduction) {
      if (_verificationId == null) {
        throw Exception("Verification ID is missing. Send OTP first.");
      }
      final credential = fb_auth.PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: code,
      );
      final userCredential = await _auth.signInWithCredential(credential);
      final fbUser = userCredential.user;
      if (fbUser == null) return null;
      return getCurrentUser();
    } else {
      // For development OTP bypass sandbox
      if (code == AppConfig.sandboxOtp) {
        return getCurrentUser();
      }
      throw Exception("Invalid OTP in development mode.");
    }
  }

  @override
  Future<void> logOut() async {
    await _auth.signOut();
  }

  @override
  Future<void> updatePoints(int newPoints) async {
    final fbUser = _auth.currentUser;
    if (fbUser == null) return;
    await _firestore.collection('users').doc(fbUser.uid).update({
      'points': newPoints,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}

class FakeAuthRepositoryImpl implements AuthRepository {
  UserModel? _currentUser;

  @override
  Future<UserModel?> getCurrentUser() async {
    if (AppConfig.isProduction) {
      throw StateError("FakeAuthRepositoryImpl must never be accessed in Production Mode.");
    }
    return _currentUser;
  }

  @override
  Future<void> sendOtp(String phone) async {
    if (AppConfig.isProduction) {
      throw StateError("FakeAuthRepositoryImpl must never be accessed in Production Mode.");
    }
    await Future.delayed(const Duration(milliseconds: 600));
  }

  @override
  Future<UserModel?> verifyOtp(String phone, String code) async {
    if (AppConfig.isProduction) {
      throw StateError("FakeAuthRepositoryImpl must never be accessed in Production Mode.");
    }
    await Future.delayed(const Duration(milliseconds: 600));
    _currentUser = UserModel(
      uid: "uid-user-hamza-99",
      phone: phone,
      name: "Hamza Al-Farsi",
      memberStatus: MemberStatus.gold,
      points: 45000,
      isAdmin: false,
      createdAt: DateTime.now(),
    );
    return _currentUser;
  }

  @override
  Future<void> logOut() async {
    _currentUser = null;
  }

  @override
  Future<void> updatePoints(int newPoints) async {
    if (_currentUser != null) {
      _currentUser = UserModel(
        uid: _currentUser!.uid,
        phone: _currentUser!.phone,
        name: _currentUser!.name,
        memberStatus: _currentUser!.memberStatus,
        points: newPoints,
        isAdmin: _currentUser!.isAdmin,
        createdAt: _currentUser!.createdAt,
      );
    }
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  if (AppConfig.isProduction) {
    return FirebaseAuthRepositoryImpl();
  } else {
    return FakeAuthRepositoryImpl();
  }
});

class AuthStateNotifier extends StateNotifier<UserModel?> {
  final AuthRepository _repository;

  AuthStateNotifier(this._repository) : super(null) {
    _init();
  }

  void _init() async {
    state = await _repository.getCurrentUser();
  }

  Future<bool> sendOtpCode(String phone) async {
    try {
      await _repository.sendOtp(phone);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> verifyOtpCode(String phone, String code) async {
    try {
      final user = await _repository.verifyOtp(phone, code);
      state = user;
      return user != null;
    } catch (_) {
      return false;
    }
  }

  Future<void> logOut() async {
    await _repository.logOut();
    state = null;
  }

  void addPoints(int delta) async {
    if (state != null) {
      final newPoints = state!.points + delta;
      await _repository.updatePoints(newPoints);
      state = UserModel(
        uid: state!.uid,
        phone: state!.phone,
        name: state!.name,
        memberStatus: state!.memberStatus,
        points: newPoints,
        isAdmin: state!.isAdmin,
        createdAt: state!.createdAt,
      );
    }
  }

  void redeemPoints(int cost) async {
    if (state != null) {
      final newPoints = state!.points - cost >= 0 ? state!.points - cost : 0;
      await _repository.updatePoints(newPoints);
      state = UserModel(
        uid: state!.uid,
        phone: state!.phone,
        name: state!.name,
        memberStatus: state!.memberStatus,
        points: newPoints,
        isAdmin: state!.isAdmin,
        createdAt: state!.createdAt,
      );
    }
  }
}

final authStateProvider = StateNotifierProvider<AuthStateNotifier, UserModel?>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return AuthStateNotifier(repository);
});

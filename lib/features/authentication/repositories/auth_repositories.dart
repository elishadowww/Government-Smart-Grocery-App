import 'package:firebase_auth/firebase_auth.dart';

import '../services/auth_service.dart';

class AuthRepository {
  Future<void> login({
    required String email,
    required String password,
  }) async {
    await AuthService.login(
      email: email,
      password: password,
    );
  }

  Future<void> register({
    required String email,
    required String password,
  }) async {
    await AuthService.register(
      email: email,
      password: password,
    );
  }

  Future<void> forgotPassword(
      String email,
      ) async {
    await AuthService.sendPasswordReset(email);
  }

  Future<UserCredential> googleLogin() async {
    return await AuthService.signInWithGoogle();
  }

  Future<void> logout() async {
    await AuthService.logout();
  }
}
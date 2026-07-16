import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  AuthService._();

  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static Stream<User?> authStateChanges() {
    return _auth.authStateChanges();
  }

  static User? get currentUser => _auth.currentUser;

  static Future<UserCredential> login({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  static Future<UserCredential> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    if (_auth.currentUser?.isAnonymous ?? false) {
      final credential = EmailAuthProvider.credential(
        email: email.trim(),
        password: password,
      );

      final userCredential =
      await _auth.currentUser!.linkWithCredential(
        credential,
      );

      await userCredential.user!.updateDisplayName(
        fullName.trim(),
      );

      try {
        await userCredential.user!.sendEmailVerification();

        debugPrint(
          "Verification email requested for ${userCredential.user!.email}",
        );
      } catch (e) {
        debugPrint(
          "Failed to send verification email: $e",
        );
      }

      return userCredential;
    }

    final userCredential =
    await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    await userCredential.user!.updateDisplayName(
      fullName.trim(),
    );

    try {
      await userCredential.user!.sendEmailVerification();

      debugPrint(
        "Verification email requested for ${userCredential.user!.email}",
      );
    } catch (e) {
      debugPrint(
        "Failed to send verification email: $e",
      );
    }

    return userCredential;
  }

  static Future<void> sendPasswordReset(
      String email,
      ) {
    return _auth.sendPasswordResetEmail(
      email: email.trim(),
    );
  }

  static Future<UserCredential> signInWithGoogle() async {
    final googleSignIn = GoogleSignIn();

    final googleUser = await googleSignIn.signIn();

    if (googleUser == null) {
      throw FirebaseAuthException(
        code: "cancelled",
        message: "Google sign in cancelled.",
      );
    }

    final googleAuth = await googleUser.authentication;

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    return await _auth.signInWithCredential(
      credential,
    );
  }

  static Future<void> logout() async {
    final googleSignIn = GoogleSignIn();

    try {
      await googleSignIn.disconnect();
    } catch (_) {}

    await googleSignIn.signOut();

    await _auth.signOut();
  }

  static Future<UserCredential> signInAnonymously() {
    return _auth.signInAnonymously();
  }

  static Future<bool> isEmailVerified() async {
    await _auth.currentUser?.reload();

    return _auth.currentUser?.emailVerified ?? false;
  }

  static Future<void> resendVerificationEmail() async {
    await _auth.currentUser?.sendEmailVerification();
  }

  static bool get requiresEmailVerification {
    final user = _auth.currentUser;

    if (user == null) return false;

    if (user.isAnonymous) return false;

    for (final provider in user.providerData) {
      if (provider.providerId == "google.com") {
        return false;
      }
    }

    return !user.emailVerified;
  }



}
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Live Firebase Auth state. Guests are signed in anonymously (see
/// IntroScreen's "Continue as Guest"), so [User] is non-null for both guests
/// and registered users once past the intro screen — the distinguishing
/// factor is [User.isAnonymous].
final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

/// Firebase uid of the current session (guest or registered), or null before
/// any session exists.
final currentUidProvider = Provider<String?>((ref) {
  final user = ref.watch(authStateProvider).value;
  return user?.uid;
});

/// True once a registered (non-anonymous) user is signed in. Registered-only
/// actions (save product, price alerts, saved shopping list — spec §4) are
/// gated on this rather than on `uid != null`, since guests have a uid too.
final isRegisteredProvider = Provider<bool>((ref) {
  final user = ref.watch(authStateProvider).value;
  return user != null && !user.isAnonymous;
});

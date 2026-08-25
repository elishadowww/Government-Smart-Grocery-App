import 'dart:io';

import 'package:flutter/painting.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repositories/profile_photo_repository.dart';
import 'current_user_provider.dart';

final profilePhotoRepositoryProvider = Provider<ProfilePhotoRepository>((ref) {
  return ProfilePhotoRepository();
});

/// The current user's saved profile picture, or null if they haven't set
/// one. Keyed by uid (via [currentUidProvider]) so guest and registered
/// sessions on the same device never see each other's photo.
final profilePhotoProvider = FutureProvider<File?>((ref) async {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return null;
  return ref.watch(profilePhotoRepositoryProvider).getPhoto(uid);
});

class ProfilePhotoController {
  ProfilePhotoController(this._ref);

  final Ref _ref;

  Future<bool> setPhoto(File cropped) async {
    final uid = _ref.read(currentUidProvider);
    if (uid == null) return false;

    final saved = await _ref.read(profilePhotoRepositoryProvider).savePhoto(uid, cropped);

    // The photo is always written to the same path per uid, so the image
    // cache must be told this path's bytes changed or the old picture keeps
    // showing.
    await FileImage(saved).evict();

    _ref.invalidate(profilePhotoProvider);
    return true;
  }

  Future<bool> removePhoto() async {
    final uid = _ref.read(currentUidProvider);
    if (uid == null) return false;

    await _ref.read(profilePhotoRepositoryProvider).removePhoto(uid);
    _ref.invalidate(profilePhotoProvider);
    return true;
  }
}

final profilePhotoControllerProvider = Provider<ProfilePhotoController>((ref) {
  return ProfilePhotoController(ref);
});

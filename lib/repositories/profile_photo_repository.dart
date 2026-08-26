import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// On-device storage for the user's profile picture.
///
/// One JPEG per Firebase uid (guest uids included) at a deterministic path
/// under the app's documents directory — there's no database row to track
/// since the file's existence at that path *is* the state.
class ProfilePhotoRepository {
  Future<File> _fileFor(String uid) async {
    final dir = await getApplicationDocumentsDirectory();
    final photosDir = Directory(p.join(dir.path, 'profile_photos'));
    if (!await photosDir.exists()) {
      await photosDir.create(recursive: true);
    }
    return File(p.join(photosDir.path, '$uid.jpg'));
  }

  Future<File?> getPhoto(String uid) async {
    final file = await _fileFor(uid);
    return file.existsSync() ? file : null;
  }

  /// Copies [source] (the cropped image) into permanent storage, overwriting
  /// any previous photo for this uid.
  Future<File> savePhoto(String uid, File source) async {
    final dest = await _fileFor(uid);
    return source.copy(dest.path);
  }

  Future<void> removePhoto(String uid) async {
    final file = await _fileFor(uid);
    if (file.existsSync()) {
      await file.delete();
    }
  }
}

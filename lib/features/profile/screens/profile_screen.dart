import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/custom_dialog.dart';
import '../../../core/widgets/custom_snackbar.dart';
import '../../authentication/repositories/auth_repositories.dart';
import '../../../providers/current_user_provider.dart';
import '../../../providers/profile_photo_provider.dart';

/// Profile screen (drawer + dashboard app-bar "person" icon land here).
/// Guests get a prompt to create an account; registered users see their
/// account details and quick links to the settings/favourites they already
/// manage elsewhere.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  String _initials(User? user) {
    final name = user?.displayName?.trim();
    if (name != null && name.isNotEmpty) {
      final parts = name.split(RegExp(r'\s+'));
      final letters = parts.take(2).map((p) => p[0].toUpperCase()).join();
      return letters;
    }

    final email = user?.email;
    if (email != null && email.isNotEmpty) {
      return email[0].toUpperCase();
    }

    return '?';
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showConfirmDialog(
      context,
      title: ref.tr('logout_confirm_title'),
      message: ref.tr('logout_confirm_message'),
      confirmLabel: ref.tr('logout'),
      cancelLabel: ref.tr('cancel'),
    );

    if (confirmed == true) {
      await AuthRepository().logout();
    }
  }

  Future<void> _showPhotoOptions(BuildContext context, WidgetRef ref, bool hasPhoto) {
    return showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined, color: AppColors.primary),
                title: Text(ref.tr('take_photo')),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _changePhoto(context, ref, ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined, color: AppColors.primary),
                title: Text(ref.tr('choose_from_gallery')),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _changePhoto(context, ref, ImageSource.gallery);
                },
              ),
              if (hasPhoto)
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: AppColors.error),
                  title: Text(ref.tr('remove_photo'), style: const TextStyle(color: AppColors.error)),
                  onTap: () async {
                    Navigator.of(sheetContext).pop();
                    final removed = await ref.read(profilePhotoControllerProvider).removePhoto();
                    if (!context.mounted) return;
                    if (removed) showAppSnackBar(context, ref.tr('photo_removed'));
                  },
                ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Future<void> _changePhoto(BuildContext context, WidgetRef ref, ImageSource source) async {
    try {
      final picked = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1600,
        imageQuality: 90,
      );
      if (picked == null) return;

      final cropped = await ImageCropper().cropImage(
        sourcePath: picked.path,
        compressFormat: ImageCompressFormat.jpg,
        compressQuality: 90,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: ref.tr('edit_photo'),
            toolbarColor: AppColors.primary,
            toolbarWidgetColor: Colors.white,
            cropStyle: CropStyle.circle,
            lockAspectRatio: true,
          ),
          IOSUiSettings(
            title: ref.tr('edit_photo'),
            cropStyle: CropStyle.circle,
            aspectRatioLockEnabled: true,
          ),
        ],
      );
      if (cropped == null) return;

      final saved = await ref.read(profilePhotoControllerProvider).setPhoto(File(cropped.path));
      if (!context.mounted) return;
      showAppSnackBar(
        context,
        saved ? ref.tr('photo_updated') : ref.tr('please_try_again'),
        isError: !saved,
      );
    } catch (_) {
      if (!context.mounted) return;
      showAppSnackBar(context, ref.tr('could_not_update_photo'), isError: true);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    final isRegistered = ref.watch(isRegisteredProvider);
    final photoFile = ref.watch(profilePhotoProvider).value;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(ref.tr('profile')),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                GestureDetector(
                  onTap: () => _showPhotoOptions(context, ref, photoFile != null),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      CircleAvatar(
                        radius: 36,
                        backgroundColor: AppColors.primary,
                        backgroundImage: photoFile != null ? FileImage(photoFile) : null,
                        child: photoFile == null
                            ? Text(
                                _initials(user),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : null,
                      ),
                      Positioned(
                        right: -2,
                        bottom: -2,
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(Icons.camera_alt, size: 14, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  isRegistered
                      ? (user?.displayName?.trim().isNotEmpty == true
                          ? user!.displayName!
                          : ref.tr('registered_user'))
                      : ref.tr('guest'),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                if (isRegistered && user?.email != null) ...[
                  const SizedBox(height: 4),
                  Text(user!.email!, style: const TextStyle(color: AppColors.grey)),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          if (!isRegistered) _GuestPrompt(ref: ref),
          if (isRegistered) _AccountDetails(ref: ref, user: user),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              ref.tr('preferences'),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.grey,
                fontSize: 12,
              ),
            ),
          ),
          _ProfileMenuTile(
            icon: Icons.favorite_border,
            label: ref.tr('favourites'),
            onTap: () => context.push('/favourites'),
          ),
          _ProfileMenuTile(
            icon: Icons.settings_outlined,
            label: ref.tr('settings'),
            onTap: () => context.push('/settings'),
          ),
          const SizedBox(height: 16),
          AppButton(
            label: ref.tr('logout'),
            type: AppButtonType.outlined,
            onPressed: () => _confirmLogout(context, ref),
          ),
        ],
      ),
    );
  }
}

class _GuestPrompt extends StatelessWidget {
  const _GuestPrompt({required this.ref});

  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Icon(Icons.person_add_alt_outlined, size: 40, color: AppColors.primary),
          const SizedBox(height: 12),
          Text(
            ref.tr('guest_profile_title'),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            ref.tr('guest_profile_desc'),
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.grey),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: ref.tr('login'),
                  type: AppButtonType.outlined,
                  dense: true,
                  onPressed: () => context.push('/login'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppButton(
                  label: ref.tr('register'),
                  dense: true,
                  onPressed: () => context.push('/register'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AccountDetails extends StatelessWidget {
  const _AccountDetails({required this.ref, required this.user});

  final WidgetRef ref;
  final User? user;

  @override
  Widget build(BuildContext context) {
    final createdAt = user?.metadata.creationTime;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _DetailRow(
            icon: user!.emailVerified ? Icons.verified_outlined : Icons.error_outline,
            iconColor: user!.emailVerified ? AppColors.primary : AppColors.warning,
            label: ref.tr('email_status'),
            value: user!.emailVerified ? ref.tr('email_verified') : ref.tr('email_not_verified'),
          ),
          if (createdAt != null) ...[
            const Divider(height: 1, indent: 16, endIndent: 16),
            _DetailRow(
              icon: Icons.calendar_today_outlined,
              label: ref.tr('member_since'),
              value: DateFormat.yMMMd().format(createdAt),
            ),
          ],
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.iconColor,
  });

  final IconData icon;
  final Color? iconColor;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, color: iconColor ?? AppColors.grey, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(label)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _ProfileMenuTile extends StatelessWidget {
  const _ProfileMenuTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: AppColors.primary),
      title: Text(label),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

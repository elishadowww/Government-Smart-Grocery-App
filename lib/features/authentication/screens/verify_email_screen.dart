import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/localization/app_strings.dart';
import '../repositories/auth_repositories.dart';

class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  final _repository = AuthRepository();

  bool checking = false;

  Future<void> _checkVerification() async {
    setState(() {
      checking = true;
    });

    final verified = await _repository.isEmailVerified();

    if (!mounted) return;

    setState(() {
      checking = false;
    });

    if (verified) {
      context.go("/dashboard");
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ref.tr('email_not_verified_warning'),
        ),
      ),
    );
  }

  Future<void> _resend() async {
    await _repository.resendVerificationEmail();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ref.tr('verification_email_sent'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),

      body: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.mark_email_read_outlined,
              size: 110,
              color: AppColors.primary,
            ),

            const SizedBox(height: 28),

            Text(
              ref.tr('verify_your_email'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),

            const SizedBox(height: 16),

            Text(
              ref.tr('verify_email_subtitle'),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 36),

            SizedBox(
              width: double.infinity,
              height: 54,
              child: FilledButton(
                onPressed: checking ? null : _checkVerification,
                child: checking
                    ? const CircularProgressIndicator()
                    : Text(
                  ref.tr('ive_verified_my_email'),
                ),
              ),
            ),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              height: 54,
              child: OutlinedButton(
                onPressed: _resend,
                child: Text(
                  ref.tr('resend_verification_email'),
                ),
              ),
            ),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              height: 54,
              child: TextButton(
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: Text(
                          ref.tr('cancel_registration_title'),
                        ),
                        content: Text(
                            ref.tr('cancel_registration_message')
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.pop(
                                context,
                                false,
                              );
                            },
                            child: Text(
                              ref.tr('stay'),
                            ),
                          ),
                          FilledButton(
                            onPressed: () {
                              Navigator.pop(
                                context,
                                true,
                              );
                            },
                            child: Text(
                              ref.tr('leave'),
                            ),
                          ),
                        ],
                      );
                    },
                  );

                  if (confirmed != true) {
                    return;
                  }

                  await _repository.logout();

                  if (!mounted) return;

                  context.go("/intro");
                },
                child: Text(
                  ref.tr('cancel_registration'),
                ),
              ),
            ),
          ],
        )
      ),
    );
  }
}
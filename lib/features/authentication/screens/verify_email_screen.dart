import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../repositories/auth_repositories.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
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
      const SnackBar(
        content: Text(
          "Your email is still not verified. Please check your inbox and spam folder.",
        ),
      ),
    );
  }

  Future<void> _resend() async {
    await _repository.resendVerificationEmail();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          "Verification email sent.",
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

            const Text(
              "Verify your email",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),

            const SizedBox(height: 16),

            const Text(
              "We've sent a verification email to your inbox.\n\nOnce you've verified your email, press the button below.",
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
                    : const Text(
                  "I've Verified My Email",
                ),
              ),
            ),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              height: 54,
              child: OutlinedButton(
                onPressed: _resend,
                child: const Text(
                  "Resend Verification Email",
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
                        title: const Text(
                          "Cancel Registration?",
                        ),
                        content: const Text(
                          "You'll be signed out and returned to the introduction screen. You can register again later with a different email address if needed.",
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.pop(
                                context,
                                false,
                              );
                            },
                            child: const Text(
                              "Stay",
                            ),
                          ),
                          FilledButton(
                            onPressed: () {
                              Navigator.pop(
                                context,
                                true,
                              );
                            },
                            child: const Text(
                              "Leave",
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
                child: const Text(
                  "Cancel Registration",
                ),
              ),
            ),
          ],
        )
      ),
    );
  }
}
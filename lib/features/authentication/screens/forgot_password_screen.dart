import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../repositories/auth_repositories.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _repository = AuthRepository();

  final _formKey = GlobalKey<FormState>();

  final emailController = TextEditingController();

  bool isLoading = false;

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  Future<void> _sendResetLink() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      await _repository.forgotPassword(
        emailController.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Password reset email sent. Please check your inbox and spam folder.",
          ),
        ),
      );

      context.pop();
    } on FirebaseAuthException catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "If an account exists for this email, a password reset email has been sent.",
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      resizeToAvoidBottomInset: true,

      body: SafeArea(
        child: Form(
          key: _formKey,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 20,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      children: [

                        Align(
                          alignment: Alignment.centerLeft,
                          child: IconButton(
                            onPressed: () => context.pop(),
                            icon: const Icon(
                              Icons.arrow_back_ios_new,
                              color: AppColors.primary,
                            ),
                          ),
                        ),

                        const Spacer(),

                        const Icon(
                          Icons.lock_reset,
                          size: 80,
                          color: AppColors.primary,
                        ),

                        const SizedBox(height: 28),

                        const Text(
                          "Forgot Password?",
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 34,
                          ),
                        ),

                        const SizedBox(height: 12),

                        const Text(
                          "Enter the email address associated with your account and we'll send you a password reset link.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.black54,
                          ),
                        ),

                        const SizedBox(height: 32),

                        TextFormField(
                          controller: emailController,
                          keyboardType: TextInputType.emailAddress,

                          decoration: InputDecoration(
                            hintText: "Email Address",

                            prefixIcon: const Icon(
                              Icons.email_outlined,
                            ),

                            border: OutlineInputBorder(
                              borderRadius:
                              BorderRadius.circular(12),
                            ),
                          ),

                          validator: (value) {
                            if (value == null ||
                                value.trim().isEmpty) {
                              return "Please enter your email";
                            }

                            final email = value.trim();

                            if (!RegExp(
                              r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$',
                            ).hasMatch(email)) {
                              return "Please enter a valid email address";
                            }

                            return null;
                          },
                        ),

                        const SizedBox(height: 24),

                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            onPressed: isLoading
                                ? null
                                : _sendResetLink,
                            child: isLoading
                                ? const SizedBox(
                              width: 22,
                              height: 22,
                              child:
                              CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                                : const Text(
                              "Send Reset Link",
                              style: TextStyle(
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 26),

                        Row(
                          mainAxisAlignment:
                          MainAxisAlignment.center,
                          children: [

                            const Text(
                              "Remember your password? ",
                            ),

                            GestureDetector(
                              onTap: () => context.pop(),
                              child: const Text(
                                "Login",
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight:
                                  FontWeight.bold,
                                ),
                              ),
                            ),

                          ],
                        ),

                        const Spacer(),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
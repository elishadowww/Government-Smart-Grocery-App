import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_strings.dart';
import '../../../app/theme/app_colors.dart';
import '../repositories/auth_repositories.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _repository = AuthRepository();
  final _formKey = GlobalKey<FormState>();
  bool isLoading = false;
  final fullNameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool obscurePassword = true;
  bool obscureConfirmPassword = true;
  bool agreeTerms = false;

  @override
  void dispose() {
    fullNameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: 28,
            vertical: 24,
          ),

          child: Column(
            children: [

              Image.asset(
                "assets/images/logo.png",
                width: 170,
              ),

              const SizedBox(height: 26),

              Text(
                ref.tr('create_your_account'),
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),

              const SizedBox(height: 6),

              Text(
                ref.tr('sign_up_subtitle'),
                style: TextStyle(
                  color: Colors.black54,
                ),
              ),

              const SizedBox(height: 34),

              TextFormField(
                controller: fullNameController,
                decoration: InputDecoration(
                  hintText: ref.tr('full_name'),
                  prefixIcon: const Icon(Icons.person_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),

                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return ref.tr('please_enter_name');
                  }

                  return null;
                },
              ),

              const SizedBox(height: 18),

              TextFormField(
                controller: emailController,
                decoration: InputDecoration(
                  hintText: ref.tr('email_address'),
                  prefixIcon: const Icon(Icons.email_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),

                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return ref.tr('please_enter_email');
                  }

                  final email = value.trim();

                  if (!RegExp(
                    r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$',
                  ).hasMatch(email)) {
                    return ref.tr('please_enter_valid_email');
                  }

                  return null;
                },
              ),

              const SizedBox(height: 18),

              TextFormField(
                controller: passwordController,
                obscureText: obscurePassword,

                decoration: InputDecoration(
                  hintText: ref.tr('password'),

                  prefixIcon: const Icon(Icons.lock_outline),

                  suffixIcon: IconButton(
                    icon: Icon(
                      obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                    onPressed: () {
                      setState(() {
                        obscurePassword = !obscurePassword;
                      });
                    },
                  ),

                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),

                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return ref.tr('please_enter_password');
                  }

                  if (value.length < 8) {
                    return ref.tr('password_length_error');
                  }

                  if (!RegExp(r'[A-Z]').hasMatch(value)) {
                    return ref.tr('password_uppercase_error');
                  }

                  if (!RegExp(r'[a-z]').hasMatch(value)) {
                    return ref.tr('password_lowercase_error');
                  }

                  if (!RegExp(r'\d').hasMatch(value)) {
                    return ref.tr('password_number_error');
                  }

                  return null;
                },
              ),

              const SizedBox(height: 18),

              TextFormField(
                controller: confirmPasswordController,
                obscureText: obscureConfirmPassword,

                decoration: InputDecoration(
                  hintText: ref.tr('confirm_password'),

                  prefixIcon: const Icon(Icons.lock_outline),

                  suffixIcon: IconButton(
                    icon: Icon(
                      obscureConfirmPassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                    onPressed: () {
                      setState(() {
                        obscureConfirmPassword =
                        !obscureConfirmPassword;
                      });
                    },
                  ),

                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),

                validator: (value) {
                  if (value != passwordController.text) {
                    return ref.tr('passwords_do_not_match');
                  }

                  return null;
                },
              ),

              const SizedBox(height: 14),

              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [

                  Checkbox(
                    value: agreeTerms,
                    activeColor: AppColors.primary,

                    onChanged: (value) {
                      setState(() {
                        agreeTerms = value ?? false;
                      });
                    },
                  ),

                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 13,
                        ),
                        children: [

                          TextSpan(
                            text: ref.tr('i_agree_to'),
                          ),

                          TextSpan(
                            text: ref.tr('terms_of_service'),
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                context.push("/terms");
                              },
                          ),

                          TextSpan(
                            text: ref.tr('and'),
                          ),

                          TextSpan(
                            text: ref.tr('privacy_policy'),
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                context.push("/privacy");
                              },
                          ),

                        ],
                      ),
                    ),
                  ),

                ],
              ),

              const SizedBox(height: 18),

              SizedBox(
                width: double.infinity,
                height: 54,

                child: ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                    if (!_formKey.currentState!.validate()) {
                      return;
                    }

                    if (!agreeTerms) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            ref.tr('accept_terms_warning'),
                          ),
                        ),
                      );

                      return;
                    }

                    setState(() {
                      isLoading = true;
                    });

                    try {
                      await _repository.register(
                        fullName: fullNameController.text.trim(),
                        email: emailController.text.trim(),
                        password: passwordController.text,
                      );

                      if (!mounted) return;

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            ref.tr('account_created_verify'),
                          ),
                        ),
                      );

                      context.go("/verify-email");
                    } on FirebaseAuthException catch (e) {
                      if (!mounted) return;

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            e.message ?? ref.tr('registration_failed'),
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
                  },

                  child: Text(
                    ref.tr('register'),
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              Row(
                children: [

                  const Expanded(child: Divider()),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Text(
                      ref.tr('or'),
                      style: TextStyle(
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),

                  const Expanded(child: Divider()),

                ],
              ),

              const SizedBox(height: 22),

              SizedBox(
                width: double.infinity,
                height: 54,

                child: OutlinedButton.icon(
                  onPressed: isLoading
                      ? null
                      : () async {
                    setState(() {
                      isLoading = true;
                    });

                    try {
                      await _repository.googleLogin();
                    } on FirebaseAuthException catch (e) {
                      if (!mounted) return;

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            e.message ?? ref.tr('google_sign_in_failed'),
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
                  },

                  icon: const Icon(Icons.g_mobiledata),

                  label: Text(
                    ref.tr('sign_up_with_google'),
                    style: TextStyle(
                      fontSize: 16,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 28),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [

                  Text(
                    ref.tr('already_have_account_question'),
                  ),

                  GestureDetector(
                    onTap: () => context.pop(),

                    child: Text(
                      ref.tr('login'),
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                ],
              ),

            ],
          ),
        ),
      ),
      ),
    );
  }
}
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../repositories/auth_repositories.dart';
import '../../../core/localization/app_strings.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _obscurePassword = true;
  bool _isLoading = false;

  final _repository = AuthRepository();

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  Future<void> _googleLogin() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await _repository.googleLogin();

      if (!mounted) return;

      context.go("/dashboard");
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      if (e.code != "cancelled") {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.message ?? ref.tr('google_sign_in_failed'),
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString(),
          ),
        ),
      );
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _login() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await _repository.login(
        email: emailController.text,
        password: passwordController.text,
      );

      if (!mounted) return;

      context.go("/dashboard");
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      String message = "Login failed.";

      switch (e.code) {
        case "invalid-email":
        case "invalid-credential":
        case "user-not-found":
        case "wrong-password":
          message = ref.tr('incorrect_email_or_password');
          break;

        case "user-disabled":
          message = ref.tr('account_disabled');
          break;

        case "too-many-requests":
          message = ref.tr('too_many_login_attempts');
          break;

        default:
          message = ref.tr('login_failed_try_again');
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
        ),
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ref.tr('something_went_wrong'),
          ),
        ),
      );
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: 28,
            vertical: 24,
          ),

          child: Column(
            children: [

              const SizedBox(height: 12),

              Image.asset(
                "assets/images/logo.png",
                width: 170,
              ),

              const SizedBox(height: 26),

              Text(
                ref.tr('welcome_back'),
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 38,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 6),

              Text(
                ref.tr('login_subtitle'),
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: 15,
                ),
              ),

              const SizedBox(height: 42),

              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  ref.tr('email'),
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              const SizedBox(height: 8),

              TextField(
                controller: emailController,

                decoration: InputDecoration(
                  hintText: ref.tr('enter_your_email'),

                  prefixIcon: const Icon(Icons.email_outlined),

                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 18,
                    horizontal: 20,
                  ),

                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 22),

              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  ref.tr('password'),
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              const SizedBox(height: 8),

              TextField(
                controller: passwordController,
                obscureText: _obscurePassword,

                decoration: InputDecoration(
                  hintText: ref.tr('enter_your_password'),

                  prefixIcon: const Icon(Icons.lock_outline),

                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                    tooltip: _obscurePassword ? ref.tr('show_password') : ref.tr('hide_password'),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),

                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: () => context.push("/forgot"),
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                    child: Text(
                      ref.tr('forgot_password_question'),
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              SizedBox(
                height: 54,
                width: double.infinity,

                child: ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  child: _isLoading
                      ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : Text(
                    ref.tr('login'),
                    style: TextStyle(
                      fontSize: 16,
                    ),
                  ),
                )
              ),

              const SizedBox(height: 26),

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

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: OutlinedButton(
                  onPressed: _isLoading ? null : _googleLogin,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.g_mobiledata,
                        size: 28,
                      ),
                      SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          ref.tr('continue_with_google'),
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [

                  Text(
                    ref.tr('dont_have_account_question'),
                  ),

                  GestureDetector(
                    onTap: () => context.push("/register"),

                    child: Text(
                      ref.tr('register'),
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
    );
  }
}
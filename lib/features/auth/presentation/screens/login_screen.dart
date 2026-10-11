// lib/features/auth/presentation/screens/login_screen.dart
// লোগো PNG + localization + full form validation

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/validators.dart';
import '../../../../routing/route_names.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _auth = AuthService();
  bool _obscure = true;
  bool _loading = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await _auth.signInWithEmail(
        email: _email.text,
        password: _password.text,
      );
      if (!mounted) return;
      final needs = await _auth.needsProfileSetup();
      if (!mounted) return;
      context.go(needs ? RouteNames.profileSetup : RouteNames.home);
    } catch (e) {
      if (!mounted) return;
      final l10n = context.l10n;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${l10n.loginFailed}: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.login),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ============ লোগো PNG ============
                  Center(
                    child: Image.asset(
                      'assets/images/logo.png',
                      height: 110,
                      width: 110,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) {
                        return const Icon(
                          Icons.auto_stories_rounded,
                          size: 90,
                          color: AppColors.primary,
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ============ অ্যাপের নাম (সবসময় বাংলা) ============
                  const Text(
                    'গল্পঘর',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // ============ Email ============
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: l10n.email,
                      prefixIcon: const Icon(Icons.email_outlined),
                      border: const OutlineInputBorder(),
                    ),
                    validator: Validators.email,
                  ),
                  const SizedBox(height: 16),

                  // ============ Password ============
                  TextFormField(
                    controller: _password,
                    obscureText: _obscure,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _submit(),
                    decoration: InputDecoration(
                      labelText: l10n.password,
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscure
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                        onPressed: () =>
                            setState(() => _obscure = !_obscure),
                      ),
                      border: const OutlineInputBorder(),
                    ),
                    validator: Validators.password,
                  ),

                  // ============ Forgot Password ============
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () =>
                          context.push(RouteNames.forgotPassword),
                      child: Text(l10n.forgotPassword),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // ============ Login Button ============
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _loading ? null : _submit,
                      child: _loading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              l10n.login,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ============ Register Link ============
                  TextButton(
                    onPressed: () => context.push(RouteNames.register),
                    child: Text(l10n.dontHaveAccount),
                  ),

                  // ============ Offline Link ============
                  const SizedBox(height: 24),
                  TextButton.icon(
                    onPressed: () => context.push(RouteNames.offline),
                    icon: const Icon(
                      Icons.download_done_outlined,
                      size: 18,
                    ),
                    label: const Text('অফলাইন গল্প পড়ুন'),
                  ),

                  // ============ Version Text ============
                  const SizedBox(height: 16),
                  Text(
                    'গল্পঘর',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

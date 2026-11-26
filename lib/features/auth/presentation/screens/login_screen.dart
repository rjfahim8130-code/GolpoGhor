// lib/features/auth/presentation/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/providers/session_cache_provider.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/utils/error_mapper.dart'; // ✅ নতুন ইমপোর্ট
import '../../../../core/utils/validators.dart';
import '../../../../routing/route_names.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  static const Color _bgLight = Color(0xFFFFFFFF);
  static const Color _bgDark = Color(0xFF18191A);
  static const Color _brandGreen = Color(0xFF159447);

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

      try {
        final profile = await _auth.getMyProfile();
        if (profile != null) {
          await ref.read(sessionCacheProvider.notifier).save(profile);
        }
      } catch (_) {}

      if (!mounted) return;
      final needs = await _auth.needsProfileSetup();
      if (!mounted) return;
      context.go(needs ? RouteNames.profileSetup : RouteNames.home);
    } catch (e) {
      if (!mounted) return;
      // ✅ সুন্দর এরর মেসেজ
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ErrorMapper.get(context, e))),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? _bgDark : _bgLight;
    
    // ✅ গাঢ় কালো এবং সাদা
    final primaryText = isDark ? Colors.white : Colors.black;
    final secondary = isDark ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        foregroundColor: primaryText,
        elevation: 0,
        scrolledUnderElevation: 0,
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
                          color: _brandGreen,
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.appName,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: primaryText,
                    ),
                  ),
                  const SizedBox(height: 32),
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    style: TextStyle(color: primaryText),
                    decoration: InputDecoration(
                      labelText: l10n.email,
                      labelStyle: TextStyle(color: secondary),
                      prefixIcon: const Icon(Icons.email_outlined),
                      border: const OutlineInputBorder(),
                    ),
                    validator: (v) => Validators.email(context, v),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _password,
                    obscureText: _obscure,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _submit(),
                    style: TextStyle(color: primaryText),
                    decoration: InputDecoration(
                      labelText: l10n.password,
                      labelStyle: TextStyle(color: secondary),
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
                    validator: (v) => Validators.password(context, v),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () =>
                          context.push(RouteNames.forgotPassword),
                      child: Text(l10n.forgotPassword),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _brandGreen,
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
                  TextButton(
                    onPressed: () => context.push(RouteNames.register),
                    child: Text(l10n.dontHaveAccount),
                  ),
                  const SizedBox(height: 24),
                  TextButton.icon(
                    onPressed: () => context.push(RouteNames.offline),
                    icon: const Icon(
                      Icons.download_done_outlined,
                      size: 18,
                    ),
                    label: Text(l10n.readOfflineStories),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.appName,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      color: secondary,
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

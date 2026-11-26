// lib/features/auth/presentation/screens/forgot_password_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/utils/error_mapper.dart'; // ✅ নতুন ইমপোর্ট
import '../../../../routing/route_names.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  static const Color _bgLight = Color(0xFFFFFFFF);
  static const Color _bgDark = Color(0xFF18191A);
  static const Color _brandGreen = Color(0xFF159447);

  final _email = TextEditingController();
  final _otp = TextEditingController();
  final _pass = TextEditingController();
  final _pass2 = TextEditingController();
  final _auth = AuthService();

  int _step = 0; // 0 = email, 1 = otp + password
  bool _loading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _otp.dispose();
    _pass.dispose();
    _pass2.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    final l10n = context.l10n;
    final e = _email.text.trim();
    if (e.isEmpty || !e.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.enterValidEmail)),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      await _auth.sendPasswordResetOtp(e);
      if (!mounted) return;
      setState(() {
        _step = 1;
        _loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.otpSent)),
      );
    } catch (err) {
      if (!mounted) return;
      setState(() => _loading = false);
      // ✅ সুন্দর এরর মেসেজ
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ErrorMapper.get(context, err))),
      );
    }
  }

  Future<void> _confirmReset() async {
    final l10n = context.l10n;
    final e = _email.text.trim();
    final token = _otp.text.trim();
    final p1 = _pass.text;
    final p2 = _pass2.text;

    if (token.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.enterValidOtp)),
      );
      return;
    }
    if (p1.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.passwordMinSix)),
      );
      return;
    }
    if (p1 != p2) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.passwordMismatch)),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      await _auth.resetPasswordWithOtp(
        email: e,
        token: token,
        newPassword: p1,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.passwordChanged)),
      );
      context.go(RouteNames.login);
    } catch (err) {
      if (!mounted) return;
      // ✅ সুন্দর এরর মেসেজ
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ErrorMapper.get(context, err))),
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

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        foregroundColor: primaryText,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(l10n.passwordReset),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_step == 1) {
              setState(() => _step = 0);
            } else {
              context.pop();
            }
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: _step == 0
            ? _emailStep(l10n, primaryText)
            : _otpStep(l10n, primaryText),
      ),
    );
  }

  Widget _emailStep(AppLocalizations l10n, Color primaryText) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.otpEmailHint,
          style: TextStyle(fontSize: 14, color: primaryText),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          style: TextStyle(color: primaryText),
          decoration: InputDecoration(
            labelText: l10n.email,
            labelStyle: TextStyle(color: primaryText),
            prefixIcon: const Icon(Icons.email_outlined),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 50,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _brandGreen,
              foregroundColor: Colors.white,
            ),
            onPressed: _loading ? null : _sendOtp,
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
                    l10n.sendOtp,
                    style: const TextStyle(fontSize: 16),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _otpStep(AppLocalizations l10n, Color primaryText) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '${_email.text.trim()} — ${l10n.otpSentTo}',
          style: TextStyle(fontSize: 14, height: 1.4, color: primaryText),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _otp,
          keyboardType: TextInputType.number,
          style: TextStyle(color: primaryText),
          decoration: InputDecoration(
            labelText: 'OTP',
            labelStyle: TextStyle(color: primaryText),
            prefixIcon: const Icon(Icons.pin_outlined),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _pass,
          obscureText: _obscure,
          style: TextStyle(color: primaryText),
          decoration: InputDecoration(
            labelText: l10n.newPassword,
            labelStyle: TextStyle(color: primaryText),
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(
                _obscure ? Icons.visibility_off : Icons.visibility,
              ),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _pass2,
          obscureText: _obscure,
          style: TextStyle(color: primaryText),
          decoration: InputDecoration(
            labelText: l10n.passwordAgain,
            labelStyle: TextStyle(color: primaryText),
            prefixIcon: const Icon(Icons.lock_outline),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 50,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _brandGreen,
              foregroundColor: Colors.white,
            ),
            onPressed: _loading ? null : _confirmReset,
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
                    l10n.setPasswordAction,
                    style: const TextStyle(fontSize: 16),
                  ),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: _loading ? null : _sendOtp,
          child: Text(l10n.resendOtp),
        ),
      ],
    );
  }
}

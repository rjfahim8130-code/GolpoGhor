// lib/features/auth/presentation/screens/profile_setup_screen.dart
// সংশোধিত: username → nickname, localization

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/providers/session_cache_provider.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/validators.dart';
import '../../../../routing/route_names.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() =>
      _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _nickname = TextEditingController();
  final _bio = TextEditingController();
  final _auth = AuthService();
  bool _loading = false;
  bool _init = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await _auth.getMyProfile();
    if (p != null) {
      _name.text = p.fullName ?? '';
      _nickname.text = p.nickname ?? '';
      _bio.text = p.bio ?? '';
    }
    if (mounted) setState(() => _init = false);
  }

  @override
  void dispose() {
    _name.dispose();
    _nickname.dispose();
    _bio.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final updated = await _auth.updateProfile(
        fullName: _name.text,
        nickname: _nickname.text,
        bio: _bio.text,
        profileSetupDone: true,
      );

      await ref.read(sessionCacheProvider.notifier).save(updated);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('profile_setup_done', true);

      if (mounted) context.go(RouteNames.home);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _skip() async {
    setState(() => _loading = true);
    try {
      await _auth.markProfileSetupDone();
      if (mounted) context.go(RouteNames.home);
    } catch (_) {
      if (mounted) context.go(RouteNames.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    if (_init) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.profile),
        automaticallyImplyLeading: false,
        actions: [
          TextButton(
            onPressed: _loading ? null : _skip,
            child: Text(l10n.close),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'চাইলে এখনই প্রোফাইল ঠিক করুন — পরেও বদলানো যাবে।',
                  style: TextStyle(fontSize: 15),
                ),
                const SizedBox(height: 24),

                // নাম
                TextFormField(
                  controller: _name,
                  decoration: InputDecoration(
                    labelText: l10n.fullName,
                    prefixIcon: const Icon(Icons.person_outline),
                  ),
                  validator: Validators.name,
                ),
                const SizedBox(height: 16),

                // ডাক নাম
                TextFormField(
                  controller: _nickname,
                  decoration: InputDecoration(
                    labelText: l10n.nickname,
                    prefixIcon: const Icon(Icons.badge_outlined),
                    helperText: 'যেমন: গল্প লেখক, কবি, ঔপন্যাসিক',
                  ),
                ),
                const SizedBox(height: 16),

                // বায়ো
                TextFormField(
                  controller: _bio,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: l10n.bio,
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 28),

                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _loading ? null : _save,
                    child: _loading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('সংরক্ষণ করে এগোও'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

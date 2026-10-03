import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/theme/app_colors.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _username = TextEditingController();
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
      _username.text = p.username ?? '';
      _bio.text = p.bio ?? '';
    }
    if (mounted) setState(() => _init = false);
  }

  @override
  void dispose() {
    _name.dispose();
    _username.dispose();
    _bio.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await _auth.updateProfile(
        fullName: _name.text,
        username: _username.text,
        bio: _bio.text,
        profileSetupDone: true,
      );
      if (mounted) context.go('/home');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('সেভ সমস্যা: $e')),
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
      if (mounted) context.go('/home');
    } catch (_) {
      if (mounted) context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_init) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('প্রোফাইল সেটআপ'),
        automaticallyImplyLeading: false,
        actions: [
          TextButton(
            onPressed: _loading ? null : _skip,
            child: const Text('স্কিপ'),
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
                TextFormField(
                  controller: _name,
                  decoration: const InputDecoration(
                    labelText: 'নাম',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'নাম লিখুন' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _username,
                  decoration: const InputDecoration(
                    labelText: 'ইউজারনেম (ইউনিক কোড)',
                    prefixIcon: Icon(Icons.alternate_email),
                    helperText: 'ছোট হাতের অক্ষর, সংখ্যা — শেয়ারের জন্য',
                  ),
                  validator: (v) {
                    if (v == null || v.trim().length < 3) {
                      return 'কমপক্ষে ৩ অক্ষর';
                    }
                    if (!RegExp(r'^[a-z0-9_]+$').hasMatch(v.trim().toLowerCase())) {
                      return 'শুধু a-z, 0-9, _';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _bio,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'বায়ো (ঐচ্ছিক)',
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

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/theme/app_colors.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _themeMode = 'system'; // system | light | dark

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _themeMode = prefs.getString('theme_mode') ?? 'system';
    });
  }

  Future<void> _setTheme(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_mode', mode);
    setState(() => _themeMode = mode);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'থিম সেভ হয়েছে। অ্যাপ আবার চালু করলে পুরোপুরি প্রয়োগ হতে পারে (ব্যাচ আপডেটে লাইভ বাইন্ড)।',
          ),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('সেটিংস'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'থিম',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          RadioListTile<String>(
            title: const Text('সিস্টেম'),
            value: 'system',
            groupValue: _themeMode,
            activeColor: AppColors.primary,
            onChanged: (v) => _setTheme(v!),
          ),
          RadioListTile<String>(
            title: const Text('লাইট'),
            value: 'light',
            groupValue: _themeMode,
            activeColor: AppColors.primary,
            onChanged: (v) => _setTheme(v!),
          ),
          RadioListTile<String>(
            title: const Text('ডার্ক'),
            value: 'dark',
            groupValue: _themeMode,
            activeColor: AppColors.primary,
            onChanged: (v) => _setTheme(v!),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: const Text('পাসওয়ার্ড সেট'),
            onTap: () => context.push('/set-password'),
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('শর্তাবলী'),
            onTap: () => context.push('/legal/terms'),
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('প্রাইভেসি'),
            onTap: () => context.push('/legal/privacy'),
          ),
          const Divider(),
          const ListTile(
            title: Text('গল্পঘর'),
            subtitle: Text('ভার্সন 1.0.0'),
          ),
        ],
      ),
    );
  }
}

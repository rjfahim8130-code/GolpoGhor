// lib/features/profile/presentation/screens/edit_profile_screen.dart
// সংশোধিত: username বাদ, nickname যোগ, avatar delete R2, localization

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/providers/session_cache_provider.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/r2_storage_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/cached_avatar.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _nickname = TextEditingController();
  final _bio = TextEditingController();
  final _auth = AuthService();
  final _storage = R2StorageService();
  final _picker = ImagePicker();

  String? _avatarUrl;
  String? _oldAvatarUrl;
  String _userId = '';
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _name.dispose();
    _nickname.dispose();
    _bio.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final p = await _auth.getMyProfile();
    if (p != null) {
      _name.text = p.fullName ?? '';
      _nickname.text = p.nickname ?? '';
      _bio.text = p.bio ?? '';
      _avatarUrl = p.avatarUrl;
      _oldAvatarUrl = p.avatarUrl;
      _userId = p.id;
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _pickAvatar() async {
    final x = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (x == null) return;
    setState(() => _saving = true);
    try {
      final url = await _storage.uploadAvatar(File(x.path));
      if (!mounted) return;
      setState(() => _avatarUrl = url);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final updated = await _auth.updateProfile(
        fullName: _name.text,
        nickname: _nickname.text,
        bio: _bio.text,
        avatarUrl: _avatarUrl,
      );

      // পুরনো avatar R2 থেকে ডিলিট (নতুন থাকলে)
      if (_oldAvatarUrl != null &&
          _oldAvatarUrl!.isNotEmpty &&
          _avatarUrl != null &&
          _avatarUrl != _oldAvatarUrl) {
        await _storage.deleteByUrl(_oldAvatarUrl);
      }

      // Session cache আপডেট
      await ref.read(sessionCacheProvider.notifier).save(updated);

      if (!mounted) return;
      final l10n = context.l10n;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${l10n.save} ✓')),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('${l10n.profile} ${l10n.edit}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: Text(
              l10n.save,
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Avatar
              GestureDetector(
                onTap: _saving ? null : _pickAvatar,
                child: Stack(
                  children: [
                    CachedAvatar(
                      userId: _userId,
                      imageUrl: _avatarUrl,
                      name: _name.text.isNotEmpty ? _name.text : 'আমি',
                      radius: 52,
                      tappable: false,
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: _saving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(
                                Icons.camera_alt,
                                size: 16,
                                color: Colors.white,
                              ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'ছবি পরিবর্তন করলে পুরনো ছবি ডিলিট হবে',
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).hintColor,
                ),
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
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(l10n.save),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// lib/features/profile/presentation/screens/edit_profile_screen.dart (Part 1)
// Brand Green + cover image + R2 avatar delete

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/providers/session_cache_provider.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/r2_storage_service.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/cached_avatar.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  static const Color _bgLight = Color(0xFFFFFFFF);
  static const Color _bgDark = Color(0xFF18191A);
  static const Color _brandGreen = Color(0xFF159447);

  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _nickname = TextEditingController();
  final _bio = TextEditingController();
  final _auth = AuthService();
  final _storage = R2StorageService();
  final _picker = ImagePicker();

  String? _avatarUrl;
  String? _oldAvatarUrl;
  String? _coverUrl;
  String? _oldCoverUrl;
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
      _coverUrl = p.coverUrl;
      _oldCoverUrl = p.coverUrl;
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

  Future<void> _pickCover() async {
    final x = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (x == null) return;
    setState(() => _saving = true);
    try {
      final url = await _storage.uploadCover(File(x.path));
      if (!mounted) return;
      setState(() => _coverUrl = url);
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

      // পুরনো avatar R2 থেকে ডিলিট
      if (_oldAvatarUrl != null &&
          _oldAvatarUrl!.isNotEmpty &&
          _avatarUrl != null &&
          _avatarUrl != _oldAvatarUrl) {
        await _storage.deleteByUrl(_oldAvatarUrl);
      }

      // পুরনো cover R2 থেকে ডিলিট
      if (_oldCoverUrl != null &&
          _oldCoverUrl!.isNotEmpty &&
          _coverUrl != null &&
          _coverUrl != _oldCoverUrl) {
        await _storage.deleteByUrl(_oldCoverUrl);
      }

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
  // lib/features/profile/presentation/screens/edit_profile_screen.dart (Part 2)
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? _bgDark : _bgLight;
    final primaryText =
        isDark ? const Color(0xFFE4E6EB) : const Color(0xFF050505);

    if (_loading) {
      return Scaffold(
        backgroundColor: bg,
        body: const Center(
          child: CircularProgressIndicator(color: _brandGreen),
        ),
      );
    }

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        foregroundColor: primaryText,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(l10n.editProfile),
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
                color: _brandGreen,
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
              // Cover image
              GestureDetector(
                onTap: _saving ? null : _pickCover,
                child: Container(
                  height: 130,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: _brandGreen,
                    borderRadius: BorderRadius.circular(14),
                    image: (_coverUrl != null && _coverUrl!.isNotEmpty)
                        ? DecorationImage(
                            image: NetworkImage(_coverUrl!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: (_coverUrl == null || _coverUrl!.isEmpty)
                      ? const Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.photo_camera_back_outlined,
                              color: Colors.white,
                              size: 36,
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Cover',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.coverImageOptional,
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).hintColor,
                ),
              ),
              const SizedBox(height: 20),

              // Avatar
              GestureDetector(
                onTap: _saving ? null : _pickAvatar,
                child: Stack(
                  children: [
                    CachedAvatar(
                      userId: _userId,
                      imageUrl: _avatarUrl,
                      name: _name.text.isNotEmpty ? _name.text : l10n.me,
                      radius: 52,
                      tappable: false,
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: _brandGreen,
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
                l10n.avatarChangeHint,
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).hintColor,
                ),
              ),
              const SizedBox(height: 24),

              // Name
              TextFormField(
                controller: _name,
                style: TextStyle(color: primaryText),
                decoration: InputDecoration(
                  labelText: l10n.fullName,
                  prefixIcon: const Icon(Icons.person_outline),
                ),
                validator: (v) => Validators.name(context, v),
              ),
              const SizedBox(height: 16),

              // Nickname
              TextFormField(
                controller: _nickname,
                style: TextStyle(color: primaryText),
                decoration: InputDecoration(
                  labelText: l10n.nickname,
                  prefixIcon: const Icon(Icons.badge_outlined),
                  helperText: l10n.nicknameHelper,
                ),
              ),
              const SizedBox(height: 16),

              // Bio
              TextFormField(
                controller: _bio,
                maxLines: 3,
                style: TextStyle(color: primaryText),
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
                    backgroundColor: _brandGreen,
                    foregroundColor: Colors.white,
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

// lib/features/profile/presentation/screens/notification_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/app_localizations.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  static const Color _bgLight = Color(0xFFFFFFFF);
  static const Color _bgDark = Color(0xFF18191A);
  static const Color _brandGreen = Color(0xFF159447);

  bool _likes = true;
  bool _comments = true;
  bool _follows = true;
  bool _mentions = true;
  bool _replies = true;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? _bgDark : _bgLight;
    final primaryText =
        isDark ? const Color(0xFFFFFFFF) : const Color(0xFF000000);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        foregroundColor: primaryText,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(l10n.notifications),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        children: [
          SwitchListTile(
            title:
                Text(l10n.reactionLike, style: TextStyle(color: primaryText)),
            value: _likes,
            activeColor: _brandGreen,
            onChanged: (v) => setState(() => _likes = v),
          ),
          SwitchListTile(
            title: Text(l10n.comment, style: TextStyle(color: primaryText)),
            value: _comments,
            activeColor: _brandGreen,
            onChanged: (v) => setState(() => _comments = v),
          ),
          SwitchListTile(
            title: Text(l10n.follow, style: TextStyle(color: primaryText)),
            value: _follows,
            activeColor: _brandGreen,
            onChanged: (v) => setState(() => _follows = v),
          ),
          SwitchListTile(
            title: Text(l10n.notifMentioned,
                style: TextStyle(color: primaryText)),
            value: _mentions,
            activeColor: _brandGreen,
            onChanged: (v) => setState(() => _mentions = v),
          ),
          SwitchListTile(
            title: Text(l10n.reply, style: TextStyle(color: primaryText)),
            value: _replies,
            activeColor: _brandGreen,
            onChanged: (v) => setState(() => _replies = v),
          ),
        ],
      ),
    );
  }
}

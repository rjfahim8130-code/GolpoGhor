// lib/features/profile/presentation/screens/notification_settings_screen.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  bool _likes = true;
  bool _comments = true;
  bool _follows = true;
  bool _mentions = true;
  bool _replies = true;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.notifications),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        children: [
          SwitchListTile(
            title: Text(l10n.reactionLike),
            value: _likes,
            activeColor: AppColors.primary,
            onChanged: (v) => setState(() => _likes = v),
          ),
          SwitchListTile(
            title: Text(l10n.comment),
            value: _comments,
            activeColor: AppColors.primary,
            onChanged: (v) => setState(() => _comments = v),
          ),
          SwitchListTile(
            title: Text(l10n.follow),
            value: _follows,
            activeColor: AppColors.primary,
            onChanged: (v) => setState(() => _follows = v),
          ),
          SwitchListTile(
            title: Text(l10n.notifMentioned),
            value: _mentions,
            activeColor: AppColors.primary,
            onChanged: (v) => setState(() => _mentions = v),
          ),
          SwitchListTile(
            title: Text(l10n.reply),
            value: _replies,
            activeColor: AppColors.primary,
            onChanged: (v) => setState(() => _replies = v),
          ),
        ],
      ),
    );
  }
}

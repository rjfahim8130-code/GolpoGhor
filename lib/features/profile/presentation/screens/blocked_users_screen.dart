// lib/features/profile/presentation/screens/blocked_users_screen.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/empty_state.dart';

class BlockedUsersScreen extends StatelessWidget {
  const BlockedUsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: EmptyState(
        icon: Icons.block,
        title: l10n.noData,
        subtitle: l10n.noFollowers,
      ),
    );
  }
}

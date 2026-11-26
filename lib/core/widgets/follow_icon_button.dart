// lib/core/widgets/follow_icon_button.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../providers/follow_status_provider.dart';
import '../services/follow_service.dart';

class FollowIconButton extends ConsumerWidget {
  final String userId;
  final double size;

  const FollowIconButton({super.key, required this.userId, this.size = 20});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = Supabase.instance.client.auth.currentUser?.id;
    if (me == null || me == userId || userId.isEmpty) {
      return const SizedBox.shrink();
    }

    final statusAsync = ref.watch(followStatusProvider(userId));
    final isBusy = ref.watch(followBusyProvider(userId));

    return statusAsync.when(
      loading: () => SizedBox(width: size, height: size),
      error: (_, __) => const SizedBox.shrink(),
      data: (isFollowing) {
        if (isBusy) {
          return SizedBox(
            width: size,
            height: size,
            child: const CircularProgressIndicator(
              strokeWidth: 2,
              color: Color(0xFF159447),
            ),
          );
        }
        return GestureDetector(
          onTap: () async {
            ref.read(followBusyProvider(userId).notifier).state = true;
            try {
              await FollowService().toggleFollow(userId);
              ref.invalidate(followStatusProvider(userId));
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(e.toString())),
                );
              }
            } finally {
              ref.read(followBusyProvider(userId).notifier).state = false;
            }
          },
          child: Icon(
            isFollowing ? Icons.check_circle : Icons.add_circle_outline,
            size: size,
            color: const Color(0xFF159447),
          ),
        );
      },
    );
  }
}

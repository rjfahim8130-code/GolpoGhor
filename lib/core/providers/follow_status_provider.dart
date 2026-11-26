// lib/core/providers/follow_status_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/follow_service.dart';

final followStatusProvider = FutureProvider.family<bool, String>((ref, userId) async {
  if (userId.isEmpty) return false;
  return await FollowService().isFollowing(userId);
});

final followBusyProvider = StateProvider.family<bool, String>((ref, userId) => false);

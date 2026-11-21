// lib/core/services/admin_service.dart
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../constants/supabase_constants.dart';
import '../models/story_model.dart';
import '../models/user_model.dart';
import 'auth_service.dart';

class AdminService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<bool> isAdmin() async {
    try {
      final email = _client.auth.currentUser?.email;
      if (email == null || email.isEmpty) {
        await AuthService.refreshAdminFlag(false);
        return false;
      }

      final row = await _client
          .from('app_admins')
          .select('email')
          .eq('email', email.toLowerCase().trim())
          .maybeSingle();

      if (row != null) {
        await AuthService.refreshAdminFlag(true);
        return true;
      }

      final uid = _client.auth.currentUser?.id;
      if (uid == null) {
        await AuthService.refreshAdminFlag(false);
        return false;
      }
      final profile = await _client
          .from(SupabaseConstants.profiles)
          .select('is_admin')
          .eq('id', uid)
          .maybeSingle();
      final ok = profile?['is_admin'] as bool? ?? false;
      await AuthService.refreshAdminFlag(ok);
      return ok;
    } catch (e) {
      debugPrint('ADMIN_CHECK_FAILED: $e');
      await AuthService.refreshAdminFlag(false);
      return false;
    }
  }

  Future<List<StoryModel>> recentStories({int limit = 30}) async {
    final data = await _client
        .from(SupabaseConstants.stories)
        .select('''
          *,
          profiles:author_id (full_name, nickname, avatar_url)
        ''')
        .order('created_at', ascending: false)
        .limit(limit);

    return (data as List).map((e) {
      final map = Map<String, dynamic>.from(e as Map);
      final p = map['profiles'];
      if (p is Map) {
        map['author_name'] = p['full_name'];
        map['author_nickname'] = p['nickname'];
        map['author_avatar'] = p['avatar_url'];
      }
      return StoryModel.fromJson(map);
    }).toList();
  }

  Future<void> unpublishStory(String storyId) async {
    await _client.from(SupabaseConstants.stories).update({
      'is_published': false,
      'is_draft': true,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', storyId);
  }

  Future<void> publishStory(String storyId) async {
    await _client.from(SupabaseConstants.stories).update({
      'is_published': true,
      'is_draft': false,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', storyId);
  }

  Future<void> deleteStory(String storyId) async {
    await _client.from(SupabaseConstants.stories).delete().eq('id', storyId);
  }

  Future<List<UserModel>> recentUsers({int limit = 30}) async {
    final data = await _client
        .from(SupabaseConstants.profiles)
        .select()
        .order('created_at', ascending: false)
        .limit(limit);

    return (data as List)
        .map((e) => UserModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<Map<String, int>> stats() async {
    Future<int> count(String table) async {
      try {
        return await _client.from(table).count(CountOption.exact);
      } catch (e) {
        debugPrint('COUNT_FAILED ($table): $e');
        return 0;
      }
    }

    final s = await count(SupabaseConstants.stories);
    final n = await count(SupabaseConstants.novels);
    final u = await count(SupabaseConstants.profiles);
    final c = await count(SupabaseConstants.comments);
    final v = await count(SupabaseConstants.videoPosts);

    int thisMonthNew = 0;
    int lastMonthNew = 0;
    try {
      final now = DateTime.now().toUtc();
      final monthStart = DateTime.utc(now.year, now.month, 1);
      final prevMonthStart = DateTime.utc(now.year, now.month - 1, 1);

      thisMonthNew = await _client
          .from(SupabaseConstants.profiles)
          .count(CountOption.exact)
          .gte('created_at', monthStart.toIso8601String());

      lastMonthNew = await _client
          .from(SupabaseConstants.profiles)
          .count(CountOption.exact)
          .gte('created_at', prevMonthStart.toIso8601String())
          .lt('created_at', monthStart.toIso8601String());
    } catch (e) {
      debugPrint('MONTHLY_STATS_FAILED: $e');
    }

    return {
      'stories': s,
      'novels': n,
      'users': u,
      'comments': c,
      'videos': v,
      'this_month_new': thisMonthNew,
      'last_month_new': lastMonthNew,
    };
  }
}

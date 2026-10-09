import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../constants/supabase_constants.dart';
import '../constants/video_constants.dart';

/// অ্যাডমিন ভিডিও টগল — একবার load হলেই cache।
/// পুরো অ্যাপে এই provider-ই একমাত্র সত্য।
final videoFeatureProvider =
    StateNotifierProvider<VideoFeatureNotifier, bool>((ref) {
  return VideoFeatureNotifier();
});

class VideoFeatureNotifier extends StateNotifier<bool> {
  VideoFeatureNotifier() : super(false) {
    _load();
  }

  final _client = Supabase.instance.client;

  Future<void> _load() async {
    try {
      final row = await _client
          .from(SupabaseConstants.appSettings)
          .select('value')
          .eq('key', VideoConstants.settingsKeyFeature)
          .maybeSingle();
      if (!mounted) return;
      if (row == null) {
        state = false;
        return;
      }
      final v = row['value'];
      if (v is Map) {
        state = v['enabled'] == true;
      } else {
        state = false;
      }
    } catch (_) {
      if (mounted) state = false;
    }
  }

  /// ম্যানুয়াল refresh — অ্যাডমিন টগল বদলালে
  Future<void> refresh() => _load();

  /// অ্যাডমিন সেট করবে
  Future<void> setEnabled(bool enabled) async {
    await _client.from(SupabaseConstants.appSettings).upsert({
      'key': VideoConstants.settingsKeyFeature,
      'value': {'enabled': enabled},
    });
    state = enabled;
  }
}

/// ভিডিও সর্বোচ্চ দৈর্ঘ্য — cache করা
final videoMaxDurationProvider = FutureProvider<int>((ref) async {
  try {
    final client = Supabase.instance.client;
    final row = await client
        .from(SupabaseConstants.appSettings)
        .select('value')
        .eq('key', VideoConstants.settingsKeyLimits)
        .maybeSingle();
    if (row != null && row['value'] is Map) {
      final n = (row['value'] as Map)['max_duration_seconds'];
      if (n is num) return n.toInt();
    }
  } catch (_) {}
  return VideoConstants.maxDurationSeconds;
});

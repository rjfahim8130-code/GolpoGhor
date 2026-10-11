// lib/main.dart
// startup safe, error handling, runZonedGuarded

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/constants/supabase_constants.dart';
import 'core/providers/locale_provider.dart';
import 'core/providers/theme_provider.dart';

Future<void> main() async {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      FlutterError.onError = (details) {
        FlutterError.presentError(details);
        debugPrint('FLUTTER_ERROR: ${details.exception}');
        debugPrint('${details.stack}');
      };

      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
        ),
      );

      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);

      // Theme + Locale prefs আগে load করি
      final container = ProviderContainer();
      try {
        await container.read(themeModeProvider.notifier).load();
      } catch (e) {
        debugPrint('THEME_LOAD_FAILED: $e');
      }
      try {
        await container.read(localeProvider.notifier).load();
      } catch (e) {
        debugPrint('LOCALE_LOAD_FAILED: $e');
      }

      Object? initError;
      try {
        await Supabase.initialize(
          url: SupabaseConstants.supabaseUrl,
          anonKey: SupabaseConstants.supabaseAnonKey,
        );
        debugPrint('SUPABASE_INIT: success');
      } catch (e, st) {
        initError = e;
        debugPrint('SUPABASE_INIT_FAILED: $e');
        debugPrint('$st');
      }

      runApp(
        UncontrolledProviderScope(
          container: container,
          child: initError == null
              ? const GolpoGhorApp()
              : _BootErrorApp(message: initError.toString()),
        ),
      );
    },
    (error, stack) {
      debugPrint('ZONE_ERROR: $error');
      debugPrint('$stack');
    },
  );
}

/// Supabase init fail করলেও অ্যাপ খুলবে — error দেখাবে
class _BootErrorApp extends StatelessWidget {
  final String message;
  const _BootErrorApp({required this.message});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                const Icon(Icons.error_outline,
                    color: Colors.red, size: 56),
                const SizedBox(height: 16),
                const Text(
                  'গল্পঘর চালু হয়নি',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'ইন্টারনেট চালু আছে কি না দেখুন। এরপরও সমস্যা হলে '
                  'নিচের মেসেজটি কপি করে সাপোর্টে পাঠান:',
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    color: Colors.grey.shade100,
                    child: SingleChildScrollView(
                      child: SelectableText(
                        message,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/constants/supabase_constants.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
  );

  // পোর্ট্রেইট লক
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Flutter error ধরার জন্য
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('FLUTTER ERROR: ${details.exception}');
    debugPrint('${details.stack}');
  };

  Object? initError;
  try {
    await Supabase.initialize(
      url: SupabaseConstants.supabaseUrl,
      anonKey: SupabaseConstants.supabaseAnonKey,
    );
  } catch (e, st) {
    initError = e;
    debugPrint('SUPABASE INIT FAILED: $e');
    debugPrint('$st');
  }

  runApp(
    ProviderScope(
      child: initError == null
          ? const GolpoGhorApp()
          : _BootErrorApp(message: initError.toString()),
    ),
  );
}

/// init ফেল করলেও স্ক্রিনে এরর দেখাবে — অ্যাপ সাথে সাথে মরবে না
class _BootErrorApp extends StatelessWidget {
  final String message;
  const _BootErrorApp({required this.message});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'গল্পঘর চালু হয়নি',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'ইন্টারনেট চালু আছে কি না দেখুন। এরপরও সমস্যা হলে '
                  'নিচের মেসেজটি ডেভেলপারকে পাঠান:',
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: SingleChildScrollView(
                    child: SelectableText(message),
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

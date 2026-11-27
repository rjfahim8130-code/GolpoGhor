import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/constants/supabase_constants.dart';
import 'core/localization/app_localizations.dart';
import 'core/providers/locale_provider.dart';
import 'core/providers/session_cache_provider.dart';
import 'core/providers/theme_provider.dart';
import 'core/services/auth_service.dart';
import 'core/services/push_notification_service.dart';

Future<void> main() async {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      
      FlutterError.onError = (details) {
        FlutterError.presentError(details);
        debugPrint('FLUTTER_ERROR: ${details.exception}');
      };

      SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(statusBarColor: Colors.transparent));
      await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);

      final container = ProviderContainer();
      try { await container.read(themeModeProvider.notifier).load(); } catch (_) {}
      try { await container.read(localeProvider.notifier).load(); } catch (_) {}
      try {
        await container.read(sessionCacheProvider.notifier).load();
        await AuthService.loadAdminFlag();
      } catch (_) {}

      Object? initError;
      try {
        await Supabase.initialize(
          url: SupabaseConstants.supabaseUrl,
          anonKey: SupabaseConstants.supabaseAnonKey,
        );
        await PushNotificationService.instance.init();
      } catch (e) {
        initError = e;
      }

      runApp(
        UncontrolledProviderScope(
          container: container,
          child: initError == null ? const GolpoGhorApp() : _BootErrorApp(message: initError.toString()),
        ),
      );
    },
    (error, stack) => debugPrint('ZONE_ERROR: $error'),
  );
}

class _BootErrorApp extends StatelessWidget {
  final String message;
  const _BootErrorApp({required this.message});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: const Locale('bn'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [AppLocalizations.delegate],
      home: Builder(
        builder: (context) {
          final l10n = context.l10n;
          return Scaffold(
            backgroundColor: Colors.white,
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 56),
                    const SizedBox(height: 16),
                    Text(l10n.appName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Text(l10n.bootErrorHelp),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(10)),
                        child: SingleChildScrollView(child: SelectableText(message)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

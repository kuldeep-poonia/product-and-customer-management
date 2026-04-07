import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/router.dart';
import 'app/theme.dart';
import 'core/app_constants.dart';
import 'package:shopiq/app/app_localizations.dart';
import 'core/providers.dart';
import 'package:shopiq/app/app_lock_provider.dart';

import 'package:shopiq/app/lock_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));
  runApp(const ProviderScope(child: ShopIQApp()));
}

class ShopIQApp extends ConsumerWidget {
  const ShopIQApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(darkModeProvider);
    final router = ref.watch(routerProvider);
    final lockState = ref.watch(appLockProvider);
    final language = ref.watch(languageProvider);

    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: lightTheme(),
      darkTheme: darkTheme(),
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      routerConfig: router,

      // ── Localization: drives ALL translated text in the app ───────────────
      locale: Locale(language),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      // ── App Lock overlay: replaces entire UI when locked ──────────────────
      builder: (context, child) {
        if (lockState.status == LockStatus.locked) {
          return const LockScreen();
        }
        return child ?? const SizedBox.shrink();
      },
    );
  }
}
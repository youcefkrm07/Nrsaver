import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'services/local_db.dart';
import 'ui/home_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await LocalDB.init();
  } catch (e, st) {
    debugPrint('Failed to load clients from JSONBin: $e');
    debugPrintStack(stackTrace: st);
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFFF5F7FB),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      cardTheme: const CardThemeData(margin: EdgeInsets.symmetric(vertical: 8)),
    );

    return LocaleSwitcher(
      child: Builder(builder: (context) {
        final currentLocale = context
            .findAncestorWidgetOfExactType<MyLocale>()
            ?.locale ??
            const Locale('en');
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Client Manager',
          theme: theme,
          locale: currentLocale,
          supportedLocales: L10n.supportedLocales,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const HomePage(),
        );
      }),
    );
  }
}

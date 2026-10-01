import 'package:flutter/material.dart';
import 'screens/main_navigation.dart';
import 'services/preferences_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await PreferencesService().init();
  runApp(const SokaBrainApp());
}

class SokaBrainApp extends StatelessWidget {
  const SokaBrainApp({super.key});

  @override
  Widget build(BuildContext context) {
    final prefs = PreferencesService();
    return ListenableBuilder(
      listenable: Listenable.merge([prefs.themeNotifier, prefs.languageNotifier]),
      builder: (context, _) {
        return MaterialApp(
          title: 'SokaBrain',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: prefs.themeNotifier.value,
          home: const MainNavigationScreen(),
        );
      },
    );
  }
}

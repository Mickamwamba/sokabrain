import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sokabrain_mobile/screens/more_screen.dart';
import 'package:sokabrain_mobile/services/fan_profile_service.dart';
import 'package:sokabrain_mobile/services/preferences_service.dart';
import 'package:sokabrain_mobile/widgets/more_dialogs.dart';

class _TestHttpOverrides extends HttpOverrides {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = _TestHttpOverrides();

  group('PreferencesService Tests', () {
    test('Initializes with default theme, notifications and favorite teams', () async {
      final prefs = PreferencesService();
      await prefs.init();

      expect(prefs.notificationsEnabled, isTrue);
      expect(prefs.notifyGoals, isTrue);
      expect(prefs.favoriteTeams, isNotEmpty);
    });

    test('Add and remove favorite teams works and persists', () async {
      final prefs = PreferencesService();
      await prefs.init();

      await prefs.addFavoriteTeam('Coastal Union');
      expect(prefs.favoriteTeams.contains('Coastal Union'), isTrue);

      await prefs.removeFavoriteTeam('Coastal Union');
      expect(prefs.favoriteTeams.contains('Coastal Union'), isFalse);
    });

    test('Theme toggling updates themeNotifier value', () async {
      final prefs = PreferencesService();
      await prefs.init();

      await prefs.setThemeMode(ThemeMode.dark);
      expect(prefs.isDarkMode, isTrue);

      await prefs.toggleThemeMode();
      expect(prefs.isDarkMode, isFalse);
      expect(prefs.themeNotifier.value, ThemeMode.light);

      await prefs.setThemeMode(ThemeMode.dark);
      expect(prefs.isDarkMode, isTrue);
    });

    test('Language switching updates languageNotifier and persists', () async {
      final prefs = PreferencesService();
      await prefs.init();

      await prefs.setLanguage('en');
      expect(prefs.language, 'en');
      expect(prefs.languageNotifier.value, 'en');
      expect(prefs.isSwahili, isFalse);

      await prefs.setLanguage('sw');
      expect(prefs.language, 'sw');
      expect(prefs.languageNotifier.value, 'sw');
      expect(prefs.isSwahili, isTrue);
    });
  });

  group('MoreScreen UI Widget Tests', () {
    testWidgets('MoreScreen renders profile, favorite teams, theme and legal options', (tester) async {
      await FanProfileService().init();
      await PreferencesService().init();

      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: MoreScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Top bar & header card
      expect(find.text('Zaidi (More)'), findsOneWidget);
      expect(find.text('SHABIKI'), findsOneWidget);
      expect(find.text('Hariri'), findsOneWidget);

      // Section titles
      expect(find.text('TIMU PENDWA'), findsOneWidget);
      expect(find.text('MANDHARI YA PROGRAMU'), findsOneWidget);
      expect(find.text('LUGHA YA PROGRAMU (LANGUAGE)'), findsOneWidget);

      // Scroll down to notifications & legal section
      await tester.scrollUntilVisible(find.text('ARIFA (NOTIFICATIONS)'), 200);
      expect(find.text('ARIFA (NOTIFICATIONS)'), findsOneWidget);

      await tester.scrollUntilVisible(find.text('KISHERIA NA TAARIFA'), 200);
      expect(find.text('KISHERIA NA TAARIFA'), findsOneWidget);
      expect(find.text('Vigezo na Masharti'), findsOneWidget);

      // Tap on Vigezo na Masharti to open Terms sheet
      await tester.tap(find.text('Vigezo na Masharti'));
      await tester.pumpAndSettle();

      expect(find.byType(TermsConditionsSheet), findsOneWidget);
      expect(find.text('1. Utangulizi na Makubaliano'), findsOneWidget);

      // Close sheet
      await tester.tap(find.byKey(const Key('terms_close_button')));
      await tester.pumpAndSettle();

      // Scroll back up to theme switch
      await tester.scrollUntilVisible(find.text('MANDHARI YA PROGRAMU'), -300);
      await tester.pumpAndSettle();
      expect(find.byType(Switch), findsWidgets);

      await tester.tap(find.byType(Switch).first);
      await tester.pumpAndSettle();
    });

    testWidgets('Tapping English switches language and updates text labels', (tester) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.runAsync(() async {
        await FanProfileService().init();
        await PreferencesService().init();
        await PreferencesService().setLanguage('sw');
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: MoreScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Zaidi (More)'), findsOneWidget);
      expect(find.text('TIMU PENDWA'), findsOneWidget);

      // Tap English option
      await tester.runAsync(() async {
        await tester.tap(find.text('English (Kiingereza)'));
        await Future.delayed(const Duration(milliseconds: 100));
      });
      await tester.pumpAndSettle();

      expect(PreferencesService().language, 'en');
      expect(PreferencesService().isSwahili, isFalse);
      expect(find.text('More & Settings'), findsOneWidget);
      expect(find.text('FAVOURITE TEAMS'), findsOneWidget);
      expect(find.text('APPEARANCE'), findsOneWidget);
      expect(find.text('APP LANGUAGE'), findsOneWidget);
    });
  });
}

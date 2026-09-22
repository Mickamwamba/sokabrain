import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sokabrain_mobile/models/match.dart';
import 'package:sokabrain_mobile/services/api_service.dart';
import 'package:sokabrain_mobile/widgets/date_selector.dart';
import 'package:sokabrain_mobile/screens/matches_screen.dart';
import 'package:sokabrain_mobile/screens/league_hub_screen.dart';

class _TestHttpOverrides extends HttpOverrides {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = _TestHttpOverrides();

  group('Matches Schedule and MatchDayItem Tests', () {
    test('MatchDayItem parses correctly', () {
      final json = {
        'date': '2026-09-20',
        'matches': 8,
        'played': 4,
      };
      final item = MatchDayItem.fromJson(json);
      expect(item.date, '2026-09-20');
      expect(item.matches, 8);
      expect(item.played, 4);
      expect(item.isPlayedOut, isFalse);
    });

    test('ApiService.fetchMatchDays returns days with matches from backend', () async {
      final res = await ApiService.fetchMatchDays(around: '2026-09-21', before: 10, after: 10);
      expect(res.days, isNotEmpty);
      // Every single day in days must have matches > 0
      for (final day in res.days) {
        expect(day.matches, greaterThan(0));
      }
      expect(res.days.any((d) => d.date == '2026-09-20'), isTrue);
    });

    testWidgets('DateSelectorBar renders only dates with matches and triggers onDateSelected', (WidgetTester tester) async {
      final sampleDays = [
        MatchDayItem(date: '2026-09-19', matches: 8, played: 8),
        MatchDayItem(date: '2026-09-20', matches: 8, played: 4),
        MatchDayItem(date: '2026-10-07', matches: 4, played: 0),
      ];

      String selectedDate = '2026-09-20';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return DateSelectorBar(
                  days: sampleDays,
                  selectedDate: selectedDate,
                  onDateSelected: (newDate) {
                    setState(() {
                      selectedDate = newDate;
                    });
                  },
                );
              },
            ),
          ),
        ),
      );

      // Verify that only the 3 provided days are rendered (no empty dates in-between)
      expect(find.text('19 Sep'), findsOneWidget);
      expect(find.text('20 Sep'), findsOneWidget);
      expect(find.text('7 Oct'), findsOneWidget);
      expect(find.text('21 Sep'), findsNothing);
      expect(find.text('22 Sep'), findsNothing);

      // Tap on 7 Oct
      await tester.tap(find.text('7 Oct'));
      await tester.pumpAndSettle();

      expect(selectedDate, '2026-10-07');
    });

    testWidgets('MatchesScreen groups matches and renders clickable league header', (WidgetTester tester) async {
      final days = [
        MatchDayItem(date: '2026-09-20', matches: 1, played: 1),
      ];

      final matches = [
        MatchItem(
          id: 101,
          status: 'FULL_TIME',
          competition: MatchCompetition(
            id: 1,
            editionId: 10,
            name: 'Tanzania Premier League',
          ),
          homeTeam: TeamRef(id: 1, name: 'Simba SC'),
          awayTeam: TeamRef(id: 2, name: 'Yanga SC'),
          score: MatchScore(home: 2, away: 1),
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: MatchesScreen(
            initialDays: days,
            initialMatches: matches,
            initialSelectedDate: '2026-09-20',
          ),
        ),
      );

      // Verify header and match card
      expect(find.text('SOKA'), findsOneWidget);
      expect(find.text('BRAIN'), findsOneWidget);
      expect(find.text('TANZANIA PREMIER LEAGUE'), findsOneWidget);
      expect(find.text('Simba SC'), findsOneWidget);
      expect(find.text('Yanga SC'), findsOneWidget);
      expect(find.text('1 mechi'), findsNWidgets(2)); // in date pill and in league header

      // Tap on the clickable league header
      await tester.tap(find.text('TANZANIA PREMIER LEAGUE'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 400));

      // Expect LeagueHubScreen to be pushed
      expect(find.byType(LeagueHubScreen), findsOneWidget);
    });
  });
}

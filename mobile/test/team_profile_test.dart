import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sokabrain_mobile/models/team_profile.dart';
import 'package:sokabrain_mobile/screens/team_profile_screen.dart';
import 'package:sokabrain_mobile/services/api_service.dart';

class _TestHttpOverrides extends HttpOverrides {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = _TestHttpOverrides();

  group('Team Profile API Integration Tests', () {
    test('fetchTeamProfile decodes full team profile from backend', () async {
      final profile = await ApiService.fetchTeamProfile(1); // Azam FC

      expect(profile, isNotNull);
      expect(profile!.team.id, 1);
      expect(profile.team.name.isNotEmpty, isTrue);
      expect(profile.record.played > 0, isTrue);
      expect(profile.record.won >= 0, isTrue);
      expect(profile.seasons.isNotEmpty, isTrue);
      expect(profile.form.isNotEmpty, isTrue);
      expect(profile.topScorers.isNotEmpty, isTrue);
    });

    test('fetchTeamUpcomingMatches decodes scheduled fixtures', () async {
      final matches = await ApiService.fetchTeamUpcomingMatches(1, limit: 3);
      expect(matches, isNotNull);
      // Scheduled matches list can be verified
      for (final m in matches) {
        expect(m.status, 'SCHEDULED');
        expect(m.homeTeam.id == 1 || m.awayTeam.id == 1, isTrue);
      }
    });
  });

  group('Team Profile UI Widget Tests', () {
    testWidgets('TeamProfileScreen renders with mock data', (tester) async {
      final mockData = TeamProfileData(
        team: TeamInfo(
          id: 99,
          name: 'Simba SC',
          shortName: 'SIM',
          type: 'CLUB',
          country: 'Tanzania',
          stadium: TeamStadium(name: 'Benjamin Mkapa Stadium', city: 'Dar es Salaam', capacity: 60000),
        ),
        record: TeamRecordStats(
          played: 100,
          won: 70,
          drawn: 20,
          lost: 10,
          goalsFor: 180,
          goalsAgainst: 50,
          goalDifference: 130,
          points: 230,
          cleanSheets: 45,
          blanks: 8,
          winRate: 70.0,
          goalsPerGame: 1.8,
        ),
        competitions: [
          TeamCompetitionRecord(
            competitionId: 1,
            competition: 'Tanzania Premier League',
            competitionType: 'LEAGUE',
            seasons: 5,
            firstSeason: '2020/2021',
            lastSeason: '2024/2025',
            titles: 4,
          ),
        ],
        seasons: [
          TeamSeasonRecord(
            editionId: 129,
            season: '2024/2025',
            competitionId: 1,
            competition: 'Tanzania Premier League',
            competitionType: 'LEAGUE',
            played: 30,
            won: 22,
            drawn: 6,
            lost: 2,
            goalsFor: 60,
            goalsAgainst: 15,
            goalDifference: 45,
            points: 72,
            position: 1,
            teamsInEdition: 16,
            finished: true,
            settled: true,
            champion: true,
          ),
        ],
        form: [
          TeamFormMatch(
            matchId: 101,
            kickoffAt: DateTime.now(),
            competition: 'Tanzania Premier League',
            season: '2024/2025',
            home: true,
            opponentId: 2,
            opponent: 'Yanga SC',
            goalsFor: 2,
            goalsAgainst: 0,
            result: 'W',
          ),
        ],
        topScorers: [
          TeamTopScorer(
            playerId: 10,
            playerName: 'John Bocco',
            position: 'FW',
            teamId: 99,
            teamName: 'Simba SC',
            goals: 85,
            assists: 15,
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TeamProfileScreen(teamId: 99, initialProfile: mockData),
          ),
        ),
      );

      await tester.pump();
      expect(find.text('Simba SC'), findsWidgets);
      expect(find.text('PLAYED'), findsOneWidget);
      expect(find.text('100'), findsOneWidget);
      expect(find.text('WIN RATE'), findsOneWidget);
      expect(find.text('70.0%'), findsOneWidget);
    });
  });
}

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/match.dart';
import '../models/match_detail.dart';
import '../models/standings.dart';
import '../models/stats.dart';
import '../models/kijiweni.dart';
import '../models/team_profile.dart';

class ApiService {
  // Can be configured to machine IP, localhost, or 10.0.2.2 for Android emulator
  static String baseUrl = 'http://localhost:4010';

  static void setBaseUrl(String url) {
    baseUrl = url;
  }

  // --- MATCHES ---
  static Future<List<MatchItem>> fetchMatches({
    String? date,
    String? status,
    int? editionId,
    int limit = 100,
  }) async {
    try {
      final queryParams = <String, String>{
        'limit': limit.toString(),
      };
      if (date != null && date.isNotEmpty) {
        queryParams['from'] = "${date}T00:00:00Z";
        queryParams['to'] = "${date}T23:59:59Z";
        queryParams['order'] = 'asc';
      }
      if (status != null && status.isNotEmpty) {
        queryParams['status'] = status;
      }
      if (editionId != null) {
        queryParams['editionId'] = editionId.toString();
      }

      final uri = Uri.parse('$baseUrl/api/vault/matches').replace(queryParameters: queryParams);
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final list = data['matches'] as List<dynamic>? ?? [];
        return list.map((m) => MatchItem.fromJson(m as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (e) {
      // ignore: avoid_print
      print('ApiService.fetchMatches error: $e');
      return [];
    }
  }

  static Future<MatchDaysResult> fetchMatchDays({
    String? around,
    int before = 15,
    int after = 20,
    int? editionId,
  }) async {
    try {
      final queryParams = <String, String>{
        'before': before.toString(),
        'after': after.toString(),
      };
      if (around != null && around.isNotEmpty) {
        queryParams['around'] = around;
      }
      if (editionId != null) {
        queryParams['editionId'] = editionId.toString();
      }

      final uri = Uri.parse('$baseUrl/api/vault/schedule/days').replace(queryParameters: queryParams);
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final rawDays = data['days'] as List<dynamic>? ?? [];
        final days = rawDays
            .map((d) => MatchDayItem.fromJson(d as Map<String, dynamic>))
            .where((d) => d.matches > 0)
            .toList();
        final nearest = data['nearest'] as String?;
        return MatchDaysResult(days: days, nearest: nearest);
      }
      return MatchDaysResult(days: [], nearest: null);
    } catch (e) {
      // ignore: avoid_print
      print('ApiService.fetchMatchDays error: $e');
      return MatchDaysResult(days: [], nearest: null);
    }
  }

  static Future<String?> fetchNearestMatchDay(String anchorDate) async {
    try {
      final uri = Uri.parse('$baseUrl/api/vault/schedule/days?around=$anchorDate&before=7&after=7');
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['nearest'] as String?;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<MatchDetailItem?> fetchMatchDetail(int id) async {
    try {
      final uri = Uri.parse('$baseUrl/api/vault/matches/$id');
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return MatchDetailItem.fromJson(data);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // --- EDITIONS & STANDINGS ---
  static Future<List<LeagueEdition>> fetchEditions() async {
    try {
      final uri = Uri.parse('$baseUrl/api/vault/editions');
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final list = data['editions'] as List<dynamic>? ?? [];
        return list.map((e) => LeagueEdition.fromJson(e as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<StandingsResponseData?> fetchStandings(int editionId) async {
    try {
      final uri = Uri.parse('$baseUrl/api/vault/editions/$editionId/standings');
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return StandingsResponseData.fromJson(data);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // --- TOP SCORERS ---
  static Future<List<TopScorerItem>> fetchTopScorers(int editionId, {int limit = 20}) async {
    try {
      final uri = Uri.parse('$baseUrl/api/vault/editions/$editionId/top-scorers?limit=$limit');
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final list = data['scorers'] as List<dynamic>? ?? [];
        return list.map((s) => TopScorerItem.fromJson(s as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<StatsOverview?> fetchStatsOverview({int? competitionId, int? editionId}) async {
    try {
      final params = <String, String>{};
      if (competitionId != null) params['competitionId'] = competitionId.toString();
      if (editionId != null) params['editionId'] = editionId.toString();
      final uri = Uri.parse('$baseUrl/api/vault/stats/overview').replace(queryParameters: params.isNotEmpty ? params : null);
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return StatsOverview.fromJson(data);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<List<ClubStatItem>> fetchClubStats({int? competitionId, int? editionId, String type = 'CLUB'}) async {
    try {
      final params = <String, String>{'type': type};
      if (competitionId != null) params['competitionId'] = competitionId.toString();
      if (editionId != null) params['editionId'] = editionId.toString();
      final uri = Uri.parse('$baseUrl/api/vault/stats/clubs').replace(queryParameters: params);
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final list = data['clubs'] as List<dynamic>? ?? [];
        return list.map((c) => ClubStatItem.fromJson(c as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<List<TopScorerItem>> fetchPlayerStats({int? competitionId, int? editionId, String sort = 'goals', int limit = 25}) async {
    try {
      final params = <String, String>{'sort': sort, 'limit': limit.toString()};
      if (competitionId != null) params['competitionId'] = competitionId.toString();
      if (editionId != null) params['editionId'] = editionId.toString();
      final uri = Uri.parse('$baseUrl/api/vault/stats/players').replace(queryParameters: params);
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final list = data['players'] as List<dynamic>? ?? [];
        return list.asMap().entries.map((entry) {
          final p = entry.value as Map<String, dynamic>;
          return TopScorerItem(
            rank: entry.key + 1,
            playerId: p['playerId'] as int? ?? 0,
            playerName: p['playerName'] as String? ?? 'Player',
            teamId: p['teamId'] as int?,
            teamName: p['teamName'] as String?,
            goals: p['goals'] as int? ?? 0,
            penalties: p['penalties'] as int? ?? 0,
            matchesScoredIn: p['appearances'] as int? ?? 0,
          );
        }).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // --- KIJIWENI (FAN ZONE) ---
  static Future<List<KijiweSpaceItem>> fetchKijiweniSpaces() async {
    try {
      final uri = Uri.parse('$baseUrl/api/kijiweni/spaces');
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final list = data['spaces'] as List<dynamic>? ?? [];
        return list.map((s) => KijiweSpaceItem.fromJson(s as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<List<KijiweThreadItem>> fetchKijiweniThreads({
    String? spaceSlug,
    String? tag,
    String? sort,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (spaceSlug != null && spaceSlug.isNotEmpty) {
        queryParams['spaceSlug'] = spaceSlug;
      }
      if (tag != null && tag.isNotEmpty) {
        queryParams['tag'] = tag;
      }
      if (sort != null && sort.isNotEmpty) {
        queryParams['sort'] = sort;
      }

      final uri = Uri.parse('$baseUrl/api/kijiweni/threads').replace(queryParameters: queryParams);
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final list = data['threads'] as List<dynamic>? ?? [];
        return list.map((t) => KijiweThreadItem.fromJson(t as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<KijiweThreadDetailItem?> fetchKijiweniThreadDetail(int id) async {
    try {
      final uri = Uri.parse('$baseUrl/api/kijiweni/threads/$id');
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return KijiweThreadDetailItem.fromJson(data);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<Map<String, dynamic>?> likeThread(int id, {required String fanFingerprint}) async {
    try {
      final uri = Uri.parse('$baseUrl/api/kijiweni/threads/$id/like');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'fanFingerprint': fanFingerprint,
          'reactionType': 'LIKE',
        }),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<Map<String, dynamic>?> likeComment(int commentId, {required String fanFingerprint}) async {
    try {
      final uri = Uri.parse('$baseUrl/api/kijiweni/comments/$commentId/like');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'fanFingerprint': fanFingerprint,
          'reactionType': 'LIKE',
        }),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<int?> createThread({
    required String spaceSlug,
    required String title,
    required String content,
    required String authorName,
    String? authorTeamName,
    required String tag,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/api/kijiweni/threads');
      final payload = <String, dynamic>{
        'spaceSlug': spaceSlug,
        'title': title,
        'content': content,
        'authorName': authorName,
        'tag': tag,
      };
      if (authorTeamName != null && authorTeamName.trim().isNotEmpty) {
        payload['authorTeamName'] = authorTeamName.trim();
      }
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['thread']?['id'] as int?;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<KijiweCommentItem?> postComment({
    required int threadId,
    required String content,
    required String authorName,
    String? authorTeamName,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/api/kijiweni/threads/$threadId/comments');
      final payload = <String, dynamic>{
        'content': content,
        'authorName': authorName,
      };
      if (authorTeamName != null && authorTeamName.trim().isNotEmpty) {
        payload['authorTeamName'] = authorTeamName.trim();
      }
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['comment'] != null) {
          return KijiweCommentItem.fromJson(data['comment'] as Map<String, dynamic>);
        }
        return KijiweCommentItem(
          id: 0,
          content: content,
          authorName: authorName,
          authorTeamName: authorTeamName,
          likesCount: 0,
          createdAt: DateTime.now(),
        );
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // --- TEAM PROFILE ---
  static Future<TeamProfileData?> fetchTeamProfile(int teamId) async {
    try {
      final uri = Uri.parse('$baseUrl/api/vault/teams/$teamId');
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return TeamProfileData.fromJson(data);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<List<MatchItem>> fetchTeamUpcomingMatches(int teamId, {int limit = 5}) async {
    try {
      final uri = Uri.parse('$baseUrl/api/vault/matches').replace(queryParameters: {
        'teamId': teamId.toString(),
        'status': 'SCHEDULED',
        'order': 'asc',
        'limit': limit.toString(),
      });
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final list = data['matches'] as List<dynamic>? ?? [];
        return list.map((m) => MatchItem.fromJson(m as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}

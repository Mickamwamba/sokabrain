import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/match.dart';
import '../models/match_detail.dart';
import '../models/standings.dart';
import '../models/stats.dart';
import '../models/kijiweni.dart';

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
        queryParams['date'] = date;
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
      // Return empty list on error
      return [];
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

  static Future<bool> likeThread(int id) async {
    try {
      final uri = Uri.parse('$baseUrl/api/kijiweni/threads/$id/like');
      final response = await http.post(uri);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> postComment({
    required int threadId,
    required String content,
    required String authorName,
    String? authorTeamName,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/api/kijiweni/threads/$threadId/comments');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'content': content,
          'authorName': authorName,
          'authorTeamName': authorTeamName,
        }),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }
}

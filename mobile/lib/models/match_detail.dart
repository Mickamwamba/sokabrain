class MatchEventItem {
  final int id;
  final String type; // GOAL, OWN_GOAL, YELLOW_CARD, RED_CARD, PENALTY, etc.
  final int? minute;
  final int? addedTime;
  final int? teamId;
  final String? playerName;

  MatchEventItem({
    required this.id,
    required this.type,
    this.minute,
    this.addedTime,
    this.teamId,
    this.playerName,
  });

  bool get isGoal => type == 'GOAL' || type == 'PENALTY';
  bool get isOwnGoal => type == 'OWN_GOAL';
  bool get isCard => type == 'YELLOW_CARD' || type == 'RED_CARD' || type == 'YELLOW_RED_CARD';
  bool get isRedCard => type == 'RED_CARD' || type == 'YELLOW_RED_CARD';

  String get displayMinute {
    if (minute == null) return '';
    if (addedTime != null && addedTime! > 0) {
      return "$minute'+$addedTime";
    }
    return "$minute'";
  }

  factory MatchEventItem.fromJson(Map<String, dynamic> json) {
    return MatchEventItem(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      type: (json['type'] as String?)?.toUpperCase() ?? 'UNKNOWN',
      minute: json['minute'] as int?,
      addedTime: json['addedTime'] as int?,
      teamId: json['teamId'] as int?,
      playerName: json['playerName'] as String?,
    );
  }
}

class MatchDetailHeadToHead {
  final int played;
  final int homeWins;
  final int awayWins;
  final int draws;

  MatchDetailHeadToHead({
    required this.played,
    required this.homeWins,
    required this.awayWins,
    required this.draws,
  });

  factory MatchDetailHeadToHead.fromJson(Map<String, dynamic> json) {
    return MatchDetailHeadToHead(
      played: json['played'] as int? ?? 0,
      homeWins: json['homeWins'] as int? ?? 0,
      awayWins: json['awayWins'] as int? ?? 0,
      draws: json['draws'] as int? ?? 0,
    );
  }
}

class MatchDetailItem {
  final int id;
  final DateTime? kickoffAt;
  final String status;
  final String? round;
  final String? venue;
  final int? liveMinute;
  final DateTime? liveMinuteAt;
  final String? competitionName;
  final String? season;
  final int homeTeamId;
  final String homeTeamName;
  final String? homeTeamShortName;
  final int? homeScore;
  final int awayTeamId;
  final String awayTeamName;
  final String? awayTeamShortName;
  final int? awayScore;
  final List<MatchEventItem> events;
  final MatchDetailHeadToHead? headToHead;

  MatchDetailItem({
    required this.id,
    this.kickoffAt,
    required this.status,
    this.round,
    this.venue,
    this.liveMinute,
    this.liveMinuteAt,
    this.competitionName,
    this.season,
    required this.homeTeamId,
    required this.homeTeamName,
    this.homeTeamShortName,
    this.homeScore,
    required this.awayTeamId,
    required this.awayTeamName,
    this.awayTeamShortName,
    this.awayScore,
    required this.events,
    this.headToHead,
  });

  bool get isLive => status == 'LIVE' || status == 'IN_PLAY' || status == 'HT';
  bool get isFinished => status == 'FULL_TIME' || status == 'FT' || status == 'AET' || status == 'PEN_FT';

  factory MatchDetailItem.fromJson(Map<String, dynamic> json) {
    final home = json['home'] as Map<String, dynamic>? ?? {};
    final away = json['away'] as Map<String, dynamic>? ?? {};
    final comp = json['competition'] as Map<String, dynamic>? ?? {};
    final rawEvents = json['events'] as List<dynamic>? ?? [];

    return MatchDetailItem(
      id: json['id'] as int? ?? 0,
      kickoffAt: json['kickoffAt'] != null ? DateTime.tryParse(json['kickoffAt']) : null,
      status: (json['status'] as String?)?.toUpperCase() ?? 'SCHEDULED',
      round: json['round'] as String?,
      venue: json['venue'] as String?,
      liveMinute: json['liveMinute'] as int?,
      liveMinuteAt: json['liveMinuteAt'] != null ? DateTime.tryParse(json['liveMinuteAt']) : null,
      competitionName: comp['name'] as String?,
      season: comp['season'] as String?,
      homeTeamId: home['id'] as int? ?? 0,
      homeTeamName: home['name'] as String? ?? 'Home',
      homeTeamShortName: home['shortName'] as String?,
      homeScore: home['score'] as int?,
      awayTeamId: away['id'] as int? ?? 0,
      awayTeamName: away['name'] as String? ?? 'Away',
      awayTeamShortName: away['shortName'] as String?,
      awayScore: away['score'] as int?,
      events: rawEvents.map((e) => MatchEventItem.fromJson(e as Map<String, dynamic>)).toList(),
      headToHead: json['headToHead'] != null
          ? MatchDetailHeadToHead.fromJson(json['headToHead'] as Map<String, dynamic>)
          : null,
    );
  }
}

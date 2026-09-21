class TeamRef {
  final int id;
  final String name;
  final String? shortName;
  final String? logoUrl;

  TeamRef({
    required this.id,
    required this.name,
    this.shortName,
    this.logoUrl,
  });

  factory TeamRef.fromJson(Map<String, dynamic> json) {
    return TeamRef(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      name: json['name'] ?? '',
      shortName: json['short_name'] ?? json['shortName'],
      logoUrl: json['logo_url'] ?? json['logoUrl'],
    );
  }
}

class MatchScore {
  final int? home;
  final int? away;
  final int? homeHt;
  final int? awayHt;
  final int? homeEt;
  final int? awayEt;
  final int? homePen;
  final int? awayPen;

  MatchScore({
    this.home,
    this.away,
    this.homeHt,
    this.awayHt,
    this.homeEt,
    this.awayEt,
    this.homePen,
    this.awayPen,
  });

  factory MatchScore.fromJson(Map<String, dynamic> json) {
    return MatchScore(
      home: json['home'] as int?,
      away: json['away'] as int?,
      homeHt: json['homeHt'] as int?,
      awayHt: json['awayHt'] as int?,
      homeEt: json['homeEt'] as int?,
      awayEt: json['awayEt'] as int?,
      homePen: json['homePen'] as int?,
      awayPen: json['awayPen'] as int?,
    );
  }
}

class MatchCompetition {
  final int? editionId;
  final int? id;
  final String? name;
  final String? type;
  final String? season;

  MatchCompetition({
    this.editionId,
    this.id,
    this.name,
    this.type,
    this.season,
  });

  factory MatchCompetition.fromJson(Map<String, dynamic> json) {
    return MatchCompetition(
      editionId: json['editionId'] as int?,
      id: json['id'] as int?,
      name: json['name'] as String?,
      type: json['type'] as String?,
      season: json['season'] as String?,
    );
  }
}

class MatchItem {
  final int id;
  final DateTime? kickoffAt;
  final String status;
  final String? round;
  final int? liveMinute;
  final DateTime? liveMinuteAt;
  final MatchCompetition competition;
  final TeamRef homeTeam;
  final TeamRef awayTeam;
  final MatchScore score;

  MatchItem({
    required this.id,
    this.kickoffAt,
    required this.status,
    this.round,
    this.liveMinute,
    this.liveMinuteAt,
    required this.competition,
    required this.homeTeam,
    required this.awayTeam,
    required this.score,
  });

  bool get isLive => status == 'LIVE' || status == 'IN_PLAY' || status == 'HT';
  bool get isFinished => status == 'FULL_TIME' || status == 'FT' || status == 'AET' || status == 'PEN_FT';
  bool get isUpcoming => status == 'SCHEDULED' || status == 'TIMED' || status == 'TBA';

  factory MatchItem.fromJson(Map<String, dynamic> json) {
    return MatchItem(
      id: json['id'] as int? ?? 0,
      kickoffAt: json['kickoffAt'] != null ? DateTime.tryParse(json['kickoffAt']) : null,
      status: (json['status'] as String?)?.toUpperCase() ?? 'SCHEDULED',
      round: json['round'] as String?,
      liveMinute: json['liveMinute'] as int?,
      liveMinuteAt: json['liveMinuteAt'] != null ? DateTime.tryParse(json['liveMinuteAt']) : null,
      competition: MatchCompetition.fromJson(json['competition'] as Map<String, dynamic>? ?? {}),
      homeTeam: TeamRef.fromJson(json['homeTeam'] as Map<String, dynamic>? ?? {}),
      awayTeam: TeamRef.fromJson(json['awayTeam'] as Map<String, dynamic>? ?? {}),
      score: MatchScore.fromJson(json['score'] as Map<String, dynamic>? ?? {}),
    );
  }
}

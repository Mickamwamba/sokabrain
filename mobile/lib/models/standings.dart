class StandingsRow {
  final int position;
  final int teamId;
  final String teamName;
  final String? shortName;
  final String? logoUrl;
  final int played;
  final int won;
  final int drawn;
  final int lost;
  final int goalsFor;
  final int goalsAgainst;
  final int goalDifference;
  final int points;

  StandingsRow({
    required this.position,
    required this.teamId,
    required this.teamName,
    this.shortName,
    this.logoUrl,
    required this.played,
    required this.won,
    required this.drawn,
    required this.lost,
    required this.goalsFor,
    required this.goalsAgainst,
    required this.goalDifference,
    required this.points,
  });

  factory StandingsRow.fromJson(Map<String, dynamic> json) {
    return StandingsRow(
      position: json['position'] as int? ?? 0,
      teamId: json['teamId'] as int? ?? 0,
      teamName: json['teamName'] as String? ?? '',
      shortName: json['shortName'] as String?,
      logoUrl: json['logoUrl'] as String?,
      played: json['played'] as int? ?? 0,
      won: json['won'] as int? ?? 0,
      drawn: json['drawn'] as int? ?? 0,
      lost: json['lost'] as int? ?? 0,
      goalsFor: json['goalsFor'] as int? ?? 0,
      goalsAgainst: json['goalsAgainst'] as int? ?? 0,
      goalDifference: json['goalDifference'] as int? ?? 0,
      points: json['points'] as int? ?? 0,
    );
  }
}

class LeagueEdition {
  final int editionId;
  final int? competitionId;
  final String competition;
  final String? competitionType;
  final String? country;
  final int? tier;
  final String season;
  final int? matchCount;

  LeagueEdition({
    required this.editionId,
    this.competitionId,
    required this.competition,
    this.competitionType,
    this.country,
    this.tier,
    required this.season,
    this.matchCount,
  });

  factory LeagueEdition.fromJson(Map<String, dynamic> json) {
    return LeagueEdition(
      editionId: json['editionId'] as int? ?? 0,
      competitionId: json['competitionId'] as int?,
      competition: json['competition'] as String? ?? '',
      competitionType: json['competitionType'] as String?,
      country: json['country'] as String?,
      tier: json['tier'] as int?,
      season: json['season'] as String? ?? '',
      matchCount: json['matchCount'] as int?,
    );
  }
}

class CompetitionGroup {
  final int competitionId;
  final String name;
  final String? country;
  final String? type;
  final int? tier;
  final List<LeagueEdition> editions;

  CompetitionGroup({
    required this.competitionId,
    required this.name,
    this.country,
    this.type,
    this.tier,
    required this.editions,
  });

  String get flagEmoji {
    final c = (country ?? '').toLowerCase();
    if (c.contains('tanzania')) return '🇹🇿';
    if (c.contains('kenya')) return '🇰🇪';
    if (c.contains('uganda')) return '🇺🇬';
    if (c.contains('rwanda')) return '🇷🇼';
    if (c.contains('south africa')) return '🇿🇦';
    return '🌍';
  }

  int get totalMatches => editions.fold(0, (sum, e) => sum + (e.matchCount ?? 0));
}

class StandingsResponseData {
  final LeagueEdition? edition;
  final List<StandingsRow> standings;

  StandingsResponseData({
    this.edition,
    required this.standings,
  });

  factory StandingsResponseData.fromJson(Map<String, dynamic> json) {
    final editionMap = json['edition'] as Map<String, dynamic>?;
    final rowsList = json['standings'] as List<dynamic>? ?? [];

    return StandingsResponseData(
      edition: editionMap != null ? LeagueEdition.fromJson(editionMap) : null,
      standings: rowsList.map((r) => StandingsRow.fromJson(r as Map<String, dynamic>)).toList(),
    );
  }
}

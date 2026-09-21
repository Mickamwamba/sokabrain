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
  final String season;
  final int? matchCount;

  LeagueEdition({
    required this.editionId,
    this.competitionId,
    required this.competition,
    this.competitionType,
    required this.season,
    this.matchCount,
  });

  factory LeagueEdition.fromJson(Map<String, dynamic> json) {
    return LeagueEdition(
      editionId: json['editionId'] as int? ?? 0,
      competitionId: json['competitionId'] as int?,
      competition: json['competition'] as String? ?? '',
      competitionType: json['competitionType'] as String?,
      season: json['season'] as String? ?? '',
      matchCount: json['matchCount'] as int?,
    );
  }
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

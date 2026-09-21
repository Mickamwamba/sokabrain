class TopScorerItem {
  final int rank;
  final int playerId;
  final String playerName;
  final int? teamId;
  final String? teamName;
  final int goals;
  final int penalties;
  final int matchesScoredIn;

  TopScorerItem({
    required this.rank,
    required this.playerId,
    required this.playerName,
    this.teamId,
    this.teamName,
    required this.goals,
    required this.penalties,
    required this.matchesScoredIn,
  });

  factory TopScorerItem.fromJson(Map<String, dynamic> json) {
    return TopScorerItem(
      rank: json['rank'] as int? ?? 0,
      playerId: json['playerId'] as int? ?? 0,
      playerName: json['playerName'] as String? ?? 'Player',
      teamId: json['teamId'] as int?,
      teamName: json['teamName'] as String?,
      goals: json['goals'] as int? ?? 0,
      penalties: json['penalties'] as int? ?? 0,
      matchesScoredIn: json['matchesScoredIn'] as int? ?? 0,
    );
  }
}

class ClubStatItem {
  final int teamId;
  final String teamName;
  final String? shortName;
  final int played;
  final int won;
  final int drawn;
  final int lost;
  final int goalsFor;
  final int goalsAgainst;
  final int goalDifference;
  final int points;
  final int cleanSheets;
  final double winRate;
  final double goalsPerGame;

  ClubStatItem({
    required this.teamId,
    required this.teamName,
    this.shortName,
    required this.played,
    required this.won,
    required this.drawn,
    required this.lost,
    required this.goalsFor,
    required this.goalsAgainst,
    required this.goalDifference,
    required this.points,
    required this.cleanSheets,
    required this.winRate,
    required this.goalsPerGame,
  });

  factory ClubStatItem.fromJson(Map<String, dynamic> json) {
    return ClubStatItem(
      teamId: json['teamId'] as int? ?? 0,
      teamName: json['teamName'] as String? ?? '',
      shortName: json['shortName'] as String?,
      played: json['played'] as int? ?? 0,
      won: json['won'] as int? ?? 0,
      drawn: json['drawn'] as int? ?? 0,
      lost: json['lost'] as int? ?? 0,
      goalsFor: json['goalsFor'] as int? ?? 0,
      goalsAgainst: json['goalsAgainst'] as int? ?? 0,
      goalDifference: json['goalDifference'] as int? ?? 0,
      points: json['points'] as int? ?? 0,
      cleanSheets: json['cleanSheets'] as int? ?? 0,
      winRate: (json['winRate'] as num?)?.toDouble() ?? 0.0,
      goalsPerGame: (json['goalsPerGame'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class StatsOverview {
  final int matches;
  final int goals;
  final int clubs;
  final int players;
  final int seasons;
  final int competitions;

  StatsOverview({
    required this.matches,
    required this.goals,
    required this.clubs,
    required this.players,
    required this.seasons,
    required this.competitions,
  });

  double get goalsPerMatch => matches > 0 ? goals / matches : 0.0;

  factory StatsOverview.fromJson(Map<String, dynamic> json) {
    return StatsOverview(
      matches: json['matches'] as int? ?? 0,
      goals: json['goals'] as int? ?? 0,
      clubs: json['clubs'] as int? ?? 0,
      players: json['players'] as int? ?? 0,
      seasons: json['seasons'] as int? ?? 0,
      competitions: json['competitions'] as int? ?? 0,
    );
  }
}

class HeadToHeadStats {
  final String teamAName;
  final String teamBName;
  final int meetings;
  final int aWins;
  final int bWins;
  final int draws;
  final int aGoals;
  final int bGoals;

  HeadToHeadStats({
    required this.teamAName,
    required this.teamBName,
    required this.meetings,
    required this.aWins,
    required this.bWins,
    required this.draws,
    required this.aGoals,
    required this.bGoals,
  });

  factory HeadToHeadStats.fromJson(Map<String, dynamic> json) {
    final a = json['teamA'] as Map<String, dynamic>? ?? {};
    final b = json['teamB'] as Map<String, dynamic>? ?? {};

    return HeadToHeadStats(
      teamAName: a['name'] as String? ?? 'Team A',
      teamBName: b['name'] as String? ?? 'Team B',
      meetings: json['meetings'] as int? ?? 0,
      aWins: json['aWins'] as int? ?? 0,
      bWins: json['bWins'] as int? ?? 0,
      draws: json['draws'] as int? ?? 0,
      aGoals: json['aGoals'] as int? ?? 0,
      bGoals: json['bGoals'] as int? ?? 0,
    );
  }
}

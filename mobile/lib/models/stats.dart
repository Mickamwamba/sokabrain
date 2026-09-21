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

class TeamStadium {
  final String name;
  final String? city;
  final int? capacity;

  TeamStadium({
    required this.name,
    this.city,
    this.capacity,
  });

  factory TeamStadium.fromJson(Map<String, dynamic> json) {
    return TeamStadium(
      name: json['name'] as String? ?? '',
      city: json['city'] as String?,
      capacity: json['capacity'] as int?,
    );
  }
}

class TeamInfo {
  final int id;
  final String name;
  final String? shortName;
  final String type;
  final String? country;
  final String? logoUrl;
  final TeamStadium? stadium;

  TeamInfo({
    required this.id,
    required this.name,
    this.shortName,
    required this.type,
    this.country,
    this.logoUrl,
    this.stadium,
  });

  factory TeamInfo.fromJson(Map<String, dynamic> json) {
    return TeamInfo(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      shortName: json['shortName'] as String? ?? json['short_name'] as String?,
      type: json['type'] as String? ?? 'CLUB',
      country: json['country'] as String?,
      logoUrl: json['logoUrl'] as String? ?? json['logo_url'] as String?,
      stadium: json['stadium'] != null ? TeamStadium.fromJson(json['stadium'] as Map<String, dynamic>) : null,
    );
  }
}

class TeamRecordStats {
  final int played;
  final int won;
  final int drawn;
  final int lost;
  final int goalsFor;
  final int goalsAgainst;
  final int goalDifference;
  final int points;
  final int cleanSheets;
  final int blanks;
  final double winRate;
  final double goalsPerGame;

  TeamRecordStats({
    required this.played,
    required this.won,
    required this.drawn,
    required this.lost,
    required this.goalsFor,
    required this.goalsAgainst,
    required this.goalDifference,
    required this.points,
    required this.cleanSheets,
    required this.blanks,
    required this.winRate,
    required this.goalsPerGame,
  });

  factory TeamRecordStats.fromJson(Map<String, dynamic> json) {
    return TeamRecordStats(
      played: json['played'] as int? ?? 0,
      won: json['won'] as int? ?? 0,
      drawn: json['drawn'] as int? ?? 0,
      lost: json['lost'] as int? ?? 0,
      goalsFor: json['goalsFor'] as int? ?? 0,
      goalsAgainst: json['goalsAgainst'] as int? ?? 0,
      goalDifference: json['goalDifference'] as int? ?? 0,
      points: json['points'] as int? ?? 0,
      cleanSheets: json['cleanSheets'] as int? ?? 0,
      blanks: json['blanks'] as int? ?? 0,
      winRate: (json['winRate'] as num?)?.toDouble() ?? 0.0,
      goalsPerGame: (json['goalsPerGame'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class TeamCompetitionRecord {
  final int competitionId;
  final String competition;
  final String competitionType;
  final int seasons;
  final String firstSeason;
  final String lastSeason;
  final int titles;

  TeamCompetitionRecord({
    required this.competitionId,
    required this.competition,
    required this.competitionType,
    required this.seasons,
    required this.firstSeason,
    required this.lastSeason,
    required this.titles,
  });

  factory TeamCompetitionRecord.fromJson(Map<String, dynamic> json) {
    return TeamCompetitionRecord(
      competitionId: json['competitionId'] as int? ?? 0,
      competition: json['competition'] as String? ?? '',
      competitionType: json['competitionType'] as String? ?? 'LEAGUE',
      seasons: json['seasons'] as int? ?? 0,
      firstSeason: json['firstSeason'] as String? ?? '',
      lastSeason: json['lastSeason'] as String? ?? '',
      titles: json['titles'] as int? ?? 0,
    );
  }
}

class TeamSeasonRecord {
  final int editionId;
  final String season;
  final int competitionId;
  final String competition;
  final String competitionType;
  final int played;
  final int won;
  final int drawn;
  final int lost;
  final int goalsFor;
  final int goalsAgainst;
  final int goalDifference;
  final int points;
  final int? position;
  final int? teamsInEdition;
  final String? furthestRound;
  final bool finished;
  final bool settled;
  final bool? champion;

  TeamSeasonRecord({
    required this.editionId,
    required this.season,
    required this.competitionId,
    required this.competition,
    required this.competitionType,
    required this.played,
    required this.won,
    required this.drawn,
    required this.lost,
    required this.goalsFor,
    required this.goalsAgainst,
    required this.goalDifference,
    required this.points,
    this.position,
    this.teamsInEdition,
    this.furthestRound,
    required this.finished,
    required this.settled,
    this.champion,
  });

  factory TeamSeasonRecord.fromJson(Map<String, dynamic> json) {
    return TeamSeasonRecord(
      editionId: json['editionId'] as int? ?? 0,
      season: json['season'] as String? ?? '',
      competitionId: json['competitionId'] as int? ?? 0,
      competition: json['competition'] as String? ?? '',
      competitionType: json['competitionType'] as String? ?? 'LEAGUE',
      played: json['played'] as int? ?? 0,
      won: json['won'] as int? ?? 0,
      drawn: json['drawn'] as int? ?? 0,
      lost: json['lost'] as int? ?? 0,
      goalsFor: json['goalsFor'] as int? ?? 0,
      goalsAgainst: json['goalsAgainst'] as int? ?? 0,
      goalDifference: json['goalDifference'] as int? ?? 0,
      points: json['points'] as int? ?? 0,
      position: json['position'] as int?,
      teamsInEdition: json['teamsInEdition'] as int?,
      furthestRound: json['furthestRound'] as String?,
      finished: json['finished'] as bool? ?? false,
      settled: json['settled'] as bool? ?? true,
      champion: json['champion'] as bool?,
    );
  }

  String get finishText {
    if (competitionType == 'LEAGUE') {
      if (position == null) return '—';
      final posStr = _ordinal(position!);
      if (champion == true) return 'Champions';
      if (!settled) return '$posStr · incomplete';
      if (!finished) return '$posStr so far';
      return teamsInEdition != null ? '$posStr of $teamsInEdition' : posStr;
    }
    if (champion == true) return 'Winners';
    if (furthestRound == 'FINAL' && champion == false) return 'Runners-up';
    if (furthestRound != null) return furthestRound!;
    return finished ? 'Group stage' : 'In progress';
  }

  static String _ordinal(int n) {
    final tens = n % 100;
    if (tens >= 11 && tens <= 13) return '${n}th';
    final mod = n % 10;
    if (mod == 1) return '${n}st';
    if (mod == 2) return '${n}nd';
    if (mod == 3) return '${n}rd';
    return '${n}th';
  }
}

class TeamFormMatch {
  final int matchId;
  final DateTime? kickoffAt;
  final String competition;
  final String season;
  final bool home;
  final int opponentId;
  final String opponent;
  final int goalsFor;
  final int goalsAgainst;
  final String result; // 'W', 'D', 'L'

  TeamFormMatch({
    required this.matchId,
    this.kickoffAt,
    required this.competition,
    required this.season,
    required this.home,
    required this.opponentId,
    required this.opponent,
    required this.goalsFor,
    required this.goalsAgainst,
    required this.result,
  });

  factory TeamFormMatch.fromJson(Map<String, dynamic> json) {
    return TeamFormMatch(
      matchId: json['matchId'] as int? ?? 0,
      kickoffAt: json['kickoffAt'] != null ? DateTime.tryParse(json['kickoffAt']) : null,
      competition: json['competition'] as String? ?? '',
      season: json['season'] as String? ?? '',
      home: json['home'] as bool? ?? true,
      opponentId: json['opponentId'] as int? ?? 0,
      opponent: json['opponent'] as String? ?? '',
      goalsFor: json['goalsFor'] as int? ?? 0,
      goalsAgainst: json['goalsAgainst'] as int? ?? 0,
      result: json['result'] as String? ?? 'D',
    );
  }
}

class TeamTopScorer {
  final int playerId;
  final String playerName;
  final String? position;
  final int teamId;
  final String teamName;
  final int goals;
  final int? penalties;
  final int? assists;

  TeamTopScorer({
    required this.playerId,
    required this.playerName,
    this.position,
    required this.teamId,
    required this.teamName,
    required this.goals,
    this.penalties,
    this.assists,
  });

  factory TeamTopScorer.fromJson(Map<String, dynamic> json) {
    return TeamTopScorer(
      playerId: json['playerId'] as int? ?? 0,
      playerName: json['playerName'] as String? ?? 'Player',
      position: json['position'] as String?,
      teamId: json['teamId'] as int? ?? 0,
      teamName: json['teamName'] as String? ?? '',
      goals: json['goals'] as int? ?? 0,
      penalties: json['penalties'] as int?,
      assists: json['assists'] as int?,
    );
  }
}

class TeamProfileData {
  final TeamInfo team;
  final TeamRecordStats record;
  final List<TeamCompetitionRecord> competitions;
  final List<TeamSeasonRecord> seasons;
  final List<TeamFormMatch> form;
  final TeamFormMatch? biggestWin;
  final TeamFormMatch? heaviestDefeat;
  final List<TeamTopScorer> topScorers;

  TeamProfileData({
    required this.team,
    required this.record,
    required this.competitions,
    required this.seasons,
    required this.form,
    this.biggestWin,
    this.heaviestDefeat,
    required this.topScorers,
  });

  int get totalTitles => competitions.fold(0, (sum, c) => sum + c.titles);

  factory TeamProfileData.fromJson(Map<String, dynamic> json) {
    final teamObj = TeamInfo.fromJson(json['team'] as Map<String, dynamic>? ?? {});
    final recordObj = TeamRecordStats.fromJson(json['record'] as Map<String, dynamic>? ?? {});

    final compsList = (json['competitions'] as List<dynamic>?) ?? [];
    final competitions = compsList.map((c) => TeamCompetitionRecord.fromJson(c as Map<String, dynamic>)).toList();

    final seasonsList = (json['seasons'] as List<dynamic>?) ?? [];
    final seasons = seasonsList.map((s) => TeamSeasonRecord.fromJson(s as Map<String, dynamic>)).toList();

    final formList = (json['form'] as List<dynamic>?) ?? [];
    final form = formList.map((f) => TeamFormMatch.fromJson(f as Map<String, dynamic>)).toList();

    final biggestWin = json['biggestWin'] != null
        ? TeamFormMatch.fromJson(json['biggestWin'] as Map<String, dynamic>)
        : null;

    final heaviestDefeat = json['heaviestDefeat'] != null
        ? TeamFormMatch.fromJson(json['heaviestDefeat'] as Map<String, dynamic>)
        : null;

    final playersJson = json['players'] as Map<String, dynamic>?;
    final playersList = (playersJson?['players'] as List<dynamic>?) ?? [];
    final topScorers = playersList.map((p) => TeamTopScorer.fromJson(p as Map<String, dynamic>)).toList();

    return TeamProfileData(
      team: teamObj,
      record: recordObj,
      competitions: competitions,
      seasons: seasons,
      form: form,
      biggestWin: biggestWin,
      heaviestDefeat: heaviestDefeat,
      topScorers: topScorers,
    );
  }
}

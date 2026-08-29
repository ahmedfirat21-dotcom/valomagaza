class AgentCatalogEntry {
  const AgentCatalogEntry({required this.name, required this.imageUrl});

  final String name;
  final String imageUrl;
}

class MapCatalogEntry {
  const MapCatalogEntry({required this.name, this.splashUrl});

  final String name;
  final String? splashUrl;
}

enum MatchOutcome { win, loss, draw, completed }

class MatchPlayer {
  const MatchPlayer({
    required this.puuid,
    required this.name,
    required this.tag,
    required this.teamId,
    required this.agentName,
    required this.agentImageUrl,
    required this.kills,
    required this.deaths,
    required this.assists,
    required this.acs,
    required this.isCurrentPlayer,
  });

  final String puuid;
  final String name;
  final String tag;
  final String teamId;
  final String agentName;
  final String agentImageUrl;
  final int kills;
  final int deaths;
  final int assists;
  final int acs;
  final bool isCurrentPlayer;

  String get displayName => tag.isEmpty ? name : '$name#$tag';

  factory MatchPlayer.fromJson(
    Map<String, dynamic> json, {
    required String currentPuuid,
    required Map<String, AgentCatalogEntry> agents,
  }) {
    final stats = MatchSummary._map(json['stats'] ?? json['Stats']) ?? const {};
    final agentId = (json['characterId'] ?? json['CharacterID'] ?? '')
        .toString()
        .toLowerCase();
    final agent = agents[agentId];
    final rounds = MatchSummary._int(
      stats['roundsPlayed'] ?? stats['RoundsPlayed'],
    );
    final score = MatchSummary._int(stats['score'] ?? stats['Score']);
    final puuid = (json['subject'] ?? json['Subject'] ?? '').toString();
    return MatchPlayer(
      puuid: puuid,
      name: (json['gameName'] ?? json['GameName'] ?? 'Oyuncu').toString(),
      tag: (json['tagLine'] ?? json['TagLine'] ?? '').toString(),
      teamId: (json['teamId'] ?? json['TeamID'] ?? '').toString(),
      agentName: agent?.name ?? 'Bilinmeyen Ajan',
      agentImageUrl: agent?.imageUrl ?? '',
      kills: MatchSummary._int(stats['kills'] ?? stats['Kills']),
      deaths: MatchSummary._int(stats['deaths'] ?? stats['Deaths']),
      assists: MatchSummary._int(stats['assists'] ?? stats['Assists']),
      acs: rounds == 0 ? 0 : (score / rounds).round(),
      isCurrentPlayer: puuid.toLowerCase() == currentPuuid,
    );
  }
}

class MatchSummary {
  const MatchSummary({
    required this.id,
    required this.mapName,
    required this.modeName,
    required this.startedAt,
    required this.duration,
    required this.agentName,
    required this.agentImageUrl,
    required this.outcome,
    required this.teamScore,
    required this.opponentScore,
    required this.kills,
    required this.deaths,
    required this.assists,
    required this.acs,
    required this.headshots,
    required this.players,
  });

  final String id;
  final String mapName;
  final String modeName;
  final DateTime startedAt;
  final Duration duration;
  final String agentName;
  final String agentImageUrl;
  final MatchOutcome outcome;
  final int teamScore;
  final int opponentScore;
  final int kills;
  final int deaths;
  final int assists;
  final int acs;
  final int headshots;
  final List<MatchPlayer> players;

  int get headshotPercent =>
      kills == 0 ? 0 : ((headshots / kills) * 100).round();

  String get kda => '$kills / $deaths / $assists';

  factory MatchSummary.fromDetail(
    Map<String, dynamic> json, {
    required String currentPuuid,
    required Map<String, AgentCatalogEntry> agents,
    required Map<String, MapCatalogEntry> maps,
  }) {
    final info = _map(json['matchInfo'] ?? json['MatchInfo']) ?? json;
    final rawPlayers = json['players'] ?? json['Players'];
    if (rawPlayers is! List) {
      throw const FormatException('Maç oyuncu verisi bulunamadı.');
    }
    final currentId = currentPuuid.toLowerCase();
    final parsedPlayers = rawPlayers
        .map(_map)
        .whereType<Map<String, dynamic>>()
        .map(
          (player) => MatchPlayer.fromJson(
            player,
            currentPuuid: currentId,
            agents: agents,
          ),
        )
        .toList(growable: false);
    final current = parsedPlayers.cast<MatchPlayer?>().firstWhere(
      (player) => player?.puuid.toLowerCase() == currentId,
      orElse: () => null,
    );
    if (current == null) {
      throw const FormatException('Mevcut oyuncu maçta bulunamadı.');
    }

    final mapId = (info['mapId'] ?? info['MapID'] ?? '').toString();
    final map = maps[mapId.toLowerCase()];
    final teamScores = _teamScores(json['teams'] ?? json['Teams']);
    final ownScore = teamScores[current.teamId] ?? 0;
    final opponentScore = teamScores.entries
        .where((entry) => entry.key != current.teamId)
        .fold(0, (value, entry) => value > entry.value ? value : entry.value);
    final mode = (info['gameMode'] ?? info['GameMode'] ?? '').toString();
    final outcome = _outcome(
      mode: mode,
      ownScore: ownScore,
      opponentScore: opponentScore,
      teams: json['teams'] ?? json['Teams'],
      teamId: current.teamId,
    );
    final startedMillis = _int(
      info['gameStartMillis'] ?? info['GameStartMillis'],
    );
    final durationMillis = _int(
      info['gameLengthMillis'] ??
          info['GameLengthMillis'] ??
          info['GameLength'],
    );
    final agent = agents[_playerAgentId(rawPlayers, currentId)];
    final headshots = _headshots(
      json['roundResults'] ?? json['RoundResults'],
      currentId,
    );
    return MatchSummary(
      id: (info['matchId'] ?? info['MatchID'] ?? '').toString(),
      mapName: map?.name ?? _fallbackName(mapId),
      modeName: _modeName(mode, info['queueId'] ?? info['QueueID']),
      startedAt: DateTime.fromMillisecondsSinceEpoch(startedMillis),
      duration: Duration(milliseconds: durationMillis),
      agentName: agent?.name ?? current.agentName,
      agentImageUrl: agent?.imageUrl ?? current.agentImageUrl,
      outcome: outcome,
      teamScore: ownScore,
      opponentScore: opponentScore,
      kills: current.kills,
      deaths: current.deaths,
      assists: current.assists,
      acs: current.acs,
      headshots: headshots,
      players: parsedPlayers,
    );
  }

  static Map<String, int> _teamScores(Object? value) {
    final scores = <String, int>{};
    if (value is! List) return scores;
    for (final entry in value) {
      final team = _map(entry);
      if (team == null) continue;
      final id = (team['teamId'] ?? team['TeamID'] ?? '').toString();
      if (id.isEmpty) continue;
      scores[id] = _int(team['roundsWon'] ?? team['RoundsWon']);
    }
    return scores;
  }

  static MatchOutcome _outcome({
    required String mode,
    required int ownScore,
    required int opponentScore,
    required Object? teams,
    required String teamId,
  }) {
    if (mode.toLowerCase().contains('deathmatch')) {
      return MatchOutcome.completed;
    }
    if (teams is List) {
      for (final value in teams) {
        final team = _map(value);
        if ((team?['teamId'] ?? team?['TeamID'])?.toString() != teamId) {
          continue;
        }
        final won = team?['won'] ?? team?['Won'];
        if (won == true) return MatchOutcome.win;
        if (won == false) return MatchOutcome.loss;
      }
    }
    if (ownScore > opponentScore) return MatchOutcome.win;
    if (ownScore < opponentScore) return MatchOutcome.loss;
    return MatchOutcome.draw;
  }

  static String _playerAgentId(List players, String currentPuuid) {
    for (final value in players) {
      final player = _map(value);
      final id = (player?['subject'] ?? player?['Subject'] ?? '').toString();
      if (id.toLowerCase() == currentPuuid) {
        return (player?['characterId'] ?? player?['CharacterID'] ?? '')
            .toString()
            .toLowerCase();
      }
    }
    return '';
  }

  static int _headshots(Object? rounds, String currentPuuid) {
    var count = 0;
    if (rounds is! List) return count;
    for (final roundValue in rounds) {
      final round = _map(roundValue);
      final playerStats = round?['playerStats'] ?? round?['PlayerStats'];
      if (playerStats is! List) continue;
      for (final statValue in playerStats) {
        final stat = _map(statValue);
        final subject = (stat?['subject'] ?? stat?['Subject'] ?? '').toString();
        if (subject.toLowerCase() != currentPuuid) continue;
        final kills = stat?['kills'] ?? stat?['Kills'];
        if (kills is! List) continue;
        for (final killValue in kills) {
          final kill = _map(killValue);
          final damage = _map(
            kill?['finishingDamage'] ?? kill?['FinishingDamage'],
          );
          final type = (damage?['damageType'] ?? damage?['DamageType'] ?? '')
              .toString();
          if (type.toLowerCase().contains('head')) count++;
        }
      }
    }
    return count;
  }

  static String _modeName(String mode, Object? queue) {
    final value =
        '${mode.toLowerCase()} ${queue?.toString().toLowerCase() ?? ''}';
    if (value.contains('competitive')) return 'Dereceli';
    if (value.contains('unrated')) return 'Derecesiz';
    if (value.contains('swiftplay')) return 'Hızlı Oyun';
    if (value.contains('spikerush')) return 'Spike Rush';
    if (value.contains('deathmatch')) return 'Ölüm Kalım Savaşı';
    if (value.contains('teamdeathmatch')) return 'Takımlı Ölüm Kalım';
    if (value.contains('premier')) return 'Premier';
    if (value.contains('custom')) return 'Özel Oyun';
    return mode.isEmpty ? 'Bilinmeyen Mod' : _fallbackName(mode);
  }

  static String _fallbackName(String value) {
    if (value.isEmpty) return 'Bilinmeyen';
    final segments = value.split('/').where((part) => part.isNotEmpty).toList();
    return segments.isEmpty ? value : segments.last.replaceAll('_', ' ');
  }

  static int _int(Object? value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static Map<String, dynamic>? _map(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }
}

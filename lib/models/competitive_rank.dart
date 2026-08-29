class CompetitiveTierInfo {
  const CompetitiveTierInfo({
    required this.tier,
    required this.name,
    this.iconUrl,
  });

  final int tier;
  final String name;
  final String? iconUrl;
}

class CurrentCompetitiveRank {
  const CurrentCompetitiveRank({
    required this.tier,
    required this.rankingInTier,
    required this.tierInfo,
  });

  final int tier;
  final int rankingInTier;
  final CompetitiveTierInfo? tierInfo;

  String get name =>
      tierInfo?.name ?? (tier <= 2 ? 'Derecesiz' : 'Seviye $tier');

  String get rrLabel =>
      tier <= 2 ? 'Yerleştirme / derecesiz' : '$rankingInTier RR';

  String? get iconUrl => tierInfo?.iconUrl;

  factory CurrentCompetitiveRank.fromJson(
    Map<String, dynamic> json,
    Map<int, CompetitiveTierInfo> tiers,
  ) {
    final queue = _map(json['QueueSkills'] ?? json['queueSkills']);
    final competitive = _map(
      queue?['competitive'] ?? queue?['Competitive'] ?? json['competitive'],
    );
    final tier = _int(
      competitive?['CompetitiveTier'] ??
          competitive?['competitiveTier'] ??
          json['CurrentTier'] ??
          json['currentTier'],
    );
    final rr = _int(
      competitive?['RankRating'] ??
          competitive?['rankRating'] ??
          json['RankingInTier'] ??
          json['rankingInTier'],
    );
    return CurrentCompetitiveRank(
      tier: tier,
      rankingInTier: rr,
      tierInfo: tiers[tier],
    );
  }
}

class CompetitiveUpdate {
  const CompetitiveUpdate({
    required this.matchId,
    required this.startedAt,
    required this.mapId,
    required this.tierAfter,
    required this.rrAfter,
    required this.rrChange,
    required this.tierInfo,
    this.mapName,
  });

  final String matchId;
  final DateTime startedAt;
  final String mapId;
  final String? mapName;
  final int tierAfter;
  final int rrAfter;
  final int rrChange;
  final CompetitiveTierInfo? tierInfo;

  String get tierName =>
      tierInfo?.name ?? (tierAfter <= 2 ? 'Derecesiz' : 'Seviye $tierAfter');

  String get rrChangeLabel =>
      rrChange == 0 ? 'RR değişmedi' : '${rrChange > 0 ? '+' : ''}$rrChange RR';

  factory CompetitiveUpdate.fromJson(
    Map<String, dynamic> json,
    Map<int, CompetitiveTierInfo> tiers, {
    String? mapName,
  }) {
    final tier = _int(json['TierAfterUpdate'] ?? json['tierAfterUpdate']);
    final after = _int(
      json['RankedRatingAfterUpdate'] ?? json['rankedRatingAfterUpdate'],
    );
    final before = _int(
      json['RankedRatingBeforeUpdate'] ?? json['rankedRatingBeforeUpdate'],
    );
    final reportedChange = _nullableInt(
      json['RankedRatingEarned'] ?? json['rankedRatingEarned'],
    );
    final started = _int(json['MatchStartTime'] ?? json['matchStartTime']);
    return CompetitiveUpdate(
      matchId: (json['MatchID'] ?? json['matchId'] ?? '').toString(),
      startedAt: DateTime.fromMillisecondsSinceEpoch(started),
      mapId: (json['MapID'] ?? json['mapId'] ?? '').toString(),
      mapName: mapName,
      tierAfter: tier,
      rrAfter: after,
      rrChange: reportedChange ?? after - before,
      tierInfo: tiers[tier],
    );
  }
}

Map<String, dynamic>? _map(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return null;
}

int _int(Object? value) => _nullableInt(value) ?? 0;

int? _nullableInt(Object? value) {
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}

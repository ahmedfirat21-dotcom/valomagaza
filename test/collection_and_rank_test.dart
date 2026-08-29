import 'package:flutter_test/flutter_test.dart';
import 'package:valo_magaza/models/competitive_rank.dart';
import 'package:valo_magaza/services/riot_collection_service.dart';

void main() {
  test('envanter ve aktif loadout yalnızca kimlikleri çözümler', () {
    final ids = RiotCollectionService.parseOwnedSkinIds({
      'Entitlements': [
        {'ItemID': 'Skin-A'},
        {'ItemID': 'skin-a'},
        {'ItemID': 'Skin-B'},
      ],
    });
    final loadout = RiotCollectionService.parseLoadout({
      'Guns': [
        {'ID': 'vandal', 'SkinID': 'Skin-A', 'SkinLevelID': 'Level-A'},
        {'ID': 'knife', 'SkinID': 'Skin-B', 'SkinLevelID': ''},
      ],
    });

    expect(ids, ['skin-a', 'skin-b']);
    expect(loadout, hasLength(2));
    expect(loadout.first.activeSkinId, 'Level-A');
  });

  test('rank ve RR güncellemesi sunum modeli oluşturur', () {
    const tier = CompetitiveTierInfo(tier: 18, name: 'Diamond 1');
    final tiers = {18: tier};
    final current = CurrentCompetitiveRank.fromJson({
      'QueueSkills': {
        'competitive': {'CompetitiveTier': 18, 'RankRating': 47},
      },
    }, tiers);
    final update = CompetitiveUpdate.fromJson(
      {
        'MatchID': 'mock-match',
        'MatchStartTime': 1700000000000,
        'MapID': 'map-ascent',
        'TierAfterUpdate': 18,
        'RankedRatingAfterUpdate': 47,
        'RankedRatingBeforeUpdate': 29,
      },
      tiers,
      mapName: 'Ascent',
    );

    expect(current.name, 'Diamond 1');
    expect(current.rrLabel, '47 RR');
    expect(update.rrChange, 18);
    expect(update.mapName, 'Ascent');
  });
}

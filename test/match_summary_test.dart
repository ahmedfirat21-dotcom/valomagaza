import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:valo_magaza/models/auth_session.dart';
import 'package:valo_magaza/models/match_summary.dart';
import 'package:valo_magaza/services/riot_match_service.dart';

void main() {
  final agents = <String, AgentCatalogEntry>{
    'agent-jett': const AgentCatalogEntry(name: 'Jett', imageUrl: ''),
    'agent-sage': const AgentCatalogEntry(name: 'Sage', imageUrl: ''),
  };
  final maps = <String, MapCatalogEntry>{
    'map-ascent': const MapCatalogEntry(name: 'Ascent'),
  };

  test('maç ayrıntısı kişisel performans ve takım skorunu çözümler', () {
    final source = File('test/fixtures/match_detail.json').readAsStringSync();
    final match = MatchSummary.fromDetail(
      Map<String, dynamic>.from(jsonDecode(source) as Map),
      currentPuuid: 'mock-puuid',
      agents: agents,
      maps: maps,
    );

    expect(match.mapName, 'Ascent');
    expect(match.modeName, 'Dereceli');
    expect(match.outcome, MatchOutcome.win);
    expect(match.teamScore, 13);
    expect(match.opponentScore, 7);
    expect(match.kda, '18 / 12 / 4');
    expect(match.acs, 195);
    expect(match.headshots, 1);
    expect(match.headshotPercent, 6);
    expect(match.players, hasLength(3));
  });

  test('match history yalnız maç kimliklerini çıkarır', () async {
    final source = File('test/fixtures/match_history.json').readAsStringSync();
    final service = RiotMatchService(
      client: MockClient((request) async => http.Response(source, 200)),
    );
    const session = AuthSession(
      accessToken: 'not-a-real-access-token',
      idToken: 'not-a-real-id-token',
      entitlementsToken: 'not-a-real-entitlement-token',
      puuid: 'mock-puuid',
      region: 'eu',
      shard: 'eu',
    );

    final ids = await service.fetchRecentMatchIds(session, 'mock-version');

    expect(ids, ['match-001', 'match-002']);
  });
}

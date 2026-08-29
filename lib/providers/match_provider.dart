import 'package:flutter/foundation.dart';

import '../core/api_exception.dart';
import '../models/match_summary.dart';
import '../services/riot_match_service.dart';
import '../services/valorant_assets_service.dart';
import 'auth_provider.dart';

enum MatchStatus { idle, loading, ready, error }

class MatchProvider extends ChangeNotifier {
  MatchProvider(this._matchService, this._assetsService, this._authProvider);

  final RiotMatchService _matchService;
  final ValorantAssetsService _assetsService;
  final AuthProvider _authProvider;

  MatchStatus _status = MatchStatus.idle;
  List<MatchSummary> _matches = const [];
  String? _errorMessage;
  String? _loadedPuuid;

  MatchStatus get status => _status;
  List<MatchSummary> get matches => _matches;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == MatchStatus.loading;

  Future<void> load({bool force = false}) async {
    final session = _authProvider.session;
    if (session == null || _status == MatchStatus.loading) return;
    if (!force &&
        _status == MatchStatus.ready &&
        _loadedPuuid == session.puuid) {
      return;
    }
    _status = MatchStatus.loading;
    _errorMessage = null;
    notifyListeners();
    try {
      final assets = await Future.wait<Object>([
        _assetsService.getClientVersion(),
        _assetsService.getAgentCatalog(),
        _assetsService.getMapCatalog(),
      ]);
      final version = assets[0] as String;
      final agents = assets[1] as Map<String, AgentCatalogEntry>;
      final maps = assets[2] as Map<String, MapCatalogEntry>;
      final ids = await _matchService.fetchRecentMatchIds(session, version);
      final matches = <MatchSummary>[];
      // Ayrıntı istekleri kasıtlı olarak sırayla yapılır. Böylece kısa sürede
      // çok sayıda private endpoint isteği atılmaz; 429'da yeniden deneme yoktur.
      for (final id in ids) {
        final detail = await _matchService.fetchMatchDetail(
          session,
          version,
          id,
        );
        matches.add(
          MatchSummary.fromDetail(
            detail,
            currentPuuid: session.puuid,
            agents: agents,
            maps: maps,
          ),
        );
      }
      _matches = List.unmodifiable(matches);
      _loadedPuuid = session.puuid;
      _status = MatchStatus.ready;
    } on ApiException catch (error) {
      if (error.isSessionExpired) {
        reset();
        await _authProvider.expireSession();
        return;
      }
      _errorMessage = error.userMessage;
      _status = MatchStatus.error;
    } catch (_) {
      _errorMessage = const ApiException(ApiErrorType.matchData).userMessage;
      _status = MatchStatus.error;
    }
    notifyListeners();
  }

  void reset() {
    _status = MatchStatus.idle;
    _matches = const [];
    _errorMessage = null;
    _loadedPuuid = null;
    notifyListeners();
  }
}

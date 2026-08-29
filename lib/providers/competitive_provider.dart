import 'package:flutter/foundation.dart';

import '../core/api_exception.dart';
import '../models/competitive_rank.dart';
import '../models/match_summary.dart';
import '../services/riot_competitive_service.dart';
import '../services/valorant_assets_service.dart';
import 'auth_provider.dart';

enum CompetitiveStatus { idle, loading, ready, error }

class CompetitiveProvider extends ChangeNotifier {
  CompetitiveProvider(this._service, this._assetsService, this._authProvider);

  final RiotCompetitiveService _service;
  final ValorantAssetsService _assetsService;
  final AuthProvider _authProvider;

  CompetitiveStatus _status = CompetitiveStatus.idle;
  CurrentCompetitiveRank? _currentRank;
  List<CompetitiveUpdate> _updates = const [];
  String? _errorMessage;
  String? _loadedPuuid;

  CompetitiveStatus get status => _status;
  CurrentCompetitiveRank? get currentRank => _currentRank;
  List<CompetitiveUpdate> get updates => _updates;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == CompetitiveStatus.loading;

  Future<void> load({bool force = false}) async {
    final session = _authProvider.session;
    if (session == null || _status == CompetitiveStatus.loading) return;
    if (!force &&
        _status == CompetitiveStatus.ready &&
        _loadedPuuid == session.puuid) {
      return;
    }
    _status = CompetitiveStatus.loading;
    _errorMessage = null;
    notifyListeners();
    try {
      final version = await _assetsService.getClientVersion();
      final results = await Future.wait<Object>([
        _assetsService.getCompetitiveTiers(),
        _assetsService.getMapCatalog(),
        _service.fetchCurrentRank(session, version),
        _service.fetchRecentUpdates(session, version),
      ]);
      final tiers = results[0] as Map<int, CompetitiveTierInfo>;
      final maps = results[1] as Map<String, MapCatalogEntry>;
      _currentRank = CurrentCompetitiveRank.fromJson(
        results[2] as Map<String, dynamic>,
        tiers,
      );
      _updates = (results[3] as List<Map<String, dynamic>>)
          .map(
            (raw) => CompetitiveUpdate.fromJson(
              raw,
              tiers,
              mapName:
                  maps[(raw['MapID'] ?? raw['mapId'] ?? '')
                          .toString()
                          .toLowerCase()]
                      ?.name,
            ),
          )
          .toList(growable: false);
      _loadedPuuid = session.puuid;
      _status = CompetitiveStatus.ready;
    } on ApiException catch (error) {
      if (error.isSessionExpired) {
        reset();
        await _authProvider.expireSession();
        return;
      }
      _errorMessage = error.userMessage;
      _status = CompetitiveStatus.error;
    } catch (_) {
      _errorMessage = const ApiException(
        ApiErrorType.competitiveData,
      ).userMessage;
      _status = CompetitiveStatus.error;
    }
    notifyListeners();
  }

  void reset() {
    _status = CompetitiveStatus.idle;
    _currentRank = null;
    _updates = const [];
    _errorMessage = null;
    _loadedPuuid = null;
    notifyListeners();
  }
}

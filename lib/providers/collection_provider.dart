import 'package:flutter/foundation.dart';

import '../core/api_exception.dart';
import '../models/collection_item.dart';
import '../models/skin_offer.dart';
import '../services/riot_collection_service.dart';
import '../services/valorant_assets_service.dart';
import 'auth_provider.dart';

enum CollectionStatus { idle, loading, ready, error }

class CollectionProvider extends ChangeNotifier {
  CollectionProvider(this._service, this._assetsService, this._authProvider);

  final RiotCollectionService _service;
  final ValorantAssetsService _assetsService;
  final AuthProvider _authProvider;

  CollectionStatus _status = CollectionStatus.idle;
  List<CollectionItem> _ownedItems = const [];
  List<CollectionItem> _catalogItems = const [];
  String? _errorMessage;
  String? _loadedPuuid;

  CollectionStatus get status => _status;
  List<CollectionItem> get ownedItems => _ownedItems;
  List<CollectionItem> get catalogItems => _catalogItems;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == CollectionStatus.loading;

  Future<void> load({bool force = false}) async {
    final session = _authProvider.session;
    if (session == null || _status == CollectionStatus.loading) return;
    if (!force &&
        _status == CollectionStatus.ready &&
        _loadedPuuid == session.puuid) {
      return;
    }
    _status = CollectionStatus.loading;
    _errorMessage = null;
    notifyListeners();
    try {
      final results = await Future.wait<Object>([
        _assetsService.getClientVersion(),
        _assetsService.getWeaponSkinCatalog(),
        _assetsService.getContentTiers(),
      ]);
      final version = results[0] as String;
      final catalog = results[1] as Map<String, WeaponSkinCatalogEntry>;
      final tiers = results[2] as Map<String, ContentTierInfo>;
      final accountResults = await Future.wait<Object>([
        _service.fetchOwnedSkinIds(session, version),
        _service.fetchLoadout(session, version),
      ]);
      final ownedIds = accountResults[0] as List<String>;
      final loadout = accountResults[1] as List<PlayerLoadoutItem>;
      final equippedIds = loadout
          .expand((item) => [item.skinId, item.skinLevelId])
          .where((id) => id.isNotEmpty)
          .map((id) => id.toLowerCase())
          .toSet();

      _ownedItems =
          ownedIds
              .map(
                (id) => CollectionItem.resolve(
                  itemId: id,
                  catalog: catalog,
                  tiers: tiers,
                  equippedItemIds: equippedIds,
                ),
              )
              .toList(growable: false)
            ..sort((a, b) => a.name.compareTo(b.name));

      final catalogBaseIds = <String>{};
      _catalogItems =
          catalog.values
              .where((item) => catalogBaseIds.add(item.skinId))
              .map(
                (asset) => CollectionItem.resolve(
                  itemId: asset.skinId,
                  catalog: catalog,
                  tiers: tiers,
                  equippedItemIds: equippedIds,
                ),
              )
              .toList(growable: false)
            ..sort((a, b) => a.name.compareTo(b.name));
      _loadedPuuid = session.puuid;
      _status = CollectionStatus.ready;
    } on ApiException catch (error) {
      if (error.isSessionExpired) {
        reset();
        await _authProvider.expireSession();
        return;
      }
      _errorMessage = error.userMessage;
      _status = CollectionStatus.error;
    } catch (_) {
      _errorMessage = const ApiException(
        ApiErrorType.collectionData,
      ).userMessage;
      _status = CollectionStatus.error;
    }
    notifyListeners();
  }

  void reset() {
    _status = CollectionStatus.idle;
    _ownedItems = const [];
    _catalogItems = const [];
    _errorMessage = null;
    _loadedPuuid = null;
    notifyListeners();
  }
}

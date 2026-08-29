import 'package:flutter/foundation.dart';

import '../core/api_exception.dart';
import '../models/auth_session.dart';
import '../models/skin_offer.dart';
import '../models/wallet.dart';
import '../services/riot_store_service.dart';
import '../services/valorant_assets_service.dart';
import 'auth_provider.dart';

enum StoreStatus { idle, loading, ready, error }

class StoreProvider extends ChangeNotifier {
  StoreProvider(this._storeService, this._assetsService, this._authProvider);

  final RiotStoreService _storeService;
  final ValorantAssetsService _assetsService;
  final AuthProvider _authProvider;

  StoreStatus _status = StoreStatus.idle;
  List<SkinOffer> _offers = const [];
  List<SkinOffer> _nightMarketOffers = const [];
  Wallet? _wallet;
  DateTime? _refreshAt;
  DateTime? _nightMarketRefreshAt;
  String? _errorMessage;
  String? _loadedPuuid;

  StoreStatus get status => _status;
  List<SkinOffer> get offers => _offers;
  List<SkinOffer> get nightMarketOffers => _nightMarketOffers;
  Wallet? get wallet => _wallet;
  DateTime? get refreshAt => _refreshAt;
  DateTime? get nightMarketRefreshAt => _nightMarketRefreshAt;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == StoreStatus.loading;

  Future<void> load(AuthSession session, {bool force = false}) async {
    if (_status == StoreStatus.loading) return;
    if (!force &&
        _status == StoreStatus.ready &&
        _loadedPuuid == session.puuid) {
      return;
    }
    _status = StoreStatus.loading;
    _errorMessage = null;
    notifyListeners();
    try {
      final clientVersion = await _assetsService.getClientVersion();
      final results = await Future.wait<Object>([
        _storeService.fetchStorefront(session, clientVersion),
        _storeService.fetchWallet(session, clientVersion),
        _assetsService.getSkinCatalog(),
        _assetsService.getContentTiers(),
      ]);
      final storefront = results[0] as StorefrontSnapshot;
      final catalog = results[2] as Map<String, SkinCatalogEntry>;
      final tiers = results[3] as Map<String, ContentTierInfo>;
      _wallet = results[1] as Wallet;
      _offers = storefront.offers
          .map((offer) => SkinOffer.resolve(offer, catalog, tiers))
          .toList(growable: false);
      _nightMarketOffers = storefront.nightMarketOffers
          .map((offer) => SkinOffer.resolveNightMarket(offer, catalog, tiers))
          .toList(growable: false);
      _refreshAt = DateTime.now().add(
        Duration(seconds: storefront.remainingSeconds),
      );
      _nightMarketRefreshAt = storefront.nightMarketRemainingSeconds > 0
          ? DateTime.now().add(
              Duration(seconds: storefront.nightMarketRemainingSeconds),
            )
          : null;
      _loadedPuuid = session.puuid;
      _status = StoreStatus.ready;
    } on ApiException catch (error) {
      if (error.isSessionExpired) {
        reset();
        await _authProvider.expireSession();
        return;
      }
      _errorMessage = error.userMessage;
      _status = StoreStatus.error;
    } catch (_) {
      _errorMessage = const ApiException(ApiErrorType.storeData).userMessage;
      _status = StoreStatus.error;
    }
    notifyListeners();
  }

  Future<void> refresh() async {
    final session = _authProvider.session;
    if (session != null) await load(session, force: true);
  }

  void reset() {
    _status = StoreStatus.idle;
    _offers = const [];
    _nightMarketOffers = const [];
    _wallet = null;
    _refreshAt = null;
    _nightMarketRefreshAt = null;
    _errorMessage = null;
    _loadedPuuid = null;
    notifyListeners();
  }
}

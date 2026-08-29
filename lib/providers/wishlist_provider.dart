import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/skin_offer.dart';

class WishlistProvider extends ChangeNotifier {
  WishlistProvider() {
    _load();
  }

  static const _key = 'valo_magaza_wishlist_items';
  final Set<String> _wishlistIds = {};
  bool _isLoaded = false;

  bool get isLoaded => _isLoaded;
  Set<String> get wishlistIds => Set.unmodifiable(_wishlistIds);
  int get count => _wishlistIds.length;

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_key) ?? [];
      _wishlistIds.clear();
      _wishlistIds.addAll(list.map((id) => id.toLowerCase()));
      _isLoaded = true;
      notifyListeners();
    } catch (_) {
      _isLoaded = true;
    }
  }

  bool isWishlisted(String skinId) {
    return _wishlistIds.contains(skinId.toLowerCase());
  }

  Future<bool> toggleWishlist(String skinId) async {
    final normalized = skinId.toLowerCase();
    final bool added;
    if (_wishlistIds.contains(normalized)) {
      _wishlistIds.remove(normalized);
      added = false;
    } else {
      _wishlistIds.add(normalized);
      added = true;
    }
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_key, _wishlistIds.toList(growable: false));
    } catch (_) {}

    return added;
  }

  List<SkinOffer> getMatchingOffers(List<SkinOffer> offers) {
    return offers
        .where((offer) => _wishlistIds.contains(offer.itemId.toLowerCase()))
        .toList(growable: false);
  }

  /// İçerik seviyesine göre yaklaşık VP fiyatı
  static int estimatePriceForTier(String? tierId) {
    if (tierId == null) return 1775;
    final normalized = tierId.toLowerCase();
    // Select (Mavi Daire) - 875 VP
    if (normalized == '12683d76-48d7-84a3-4e09-6985794f0445') return 875;
    // Deluxe (Yeşil Prizma) - 1275 VP
    if (normalized == '0cebb8be-46d7-c12a-d306-e9907be16d05') return 1275;
    // Premium (Pembe Üçgen) - 1775 VP
    if (normalized == '60bca009-4182-7998-dee7-b8a2558dc369') return 1775;
    // Ultra (Sarı Elmas) - 2175 VP
    if (normalized == '411e4a55-4e59-775b-37d0-8ac725d76075') return 2175;
    // Exclusive (Turuncu Yıldız) - 2175 VP
    if (normalized == 'e046854e-406c-37f4-6607-19a9ba8426fc') return 2175;
    return 1775;
  }

  int calculateTotalEstimatedVp(Map<String, SkinCatalogEntry> catalog) {
    var total = 0;
    for (final id in _wishlistIds) {
      final entry = catalog[id];
      total += estimatePriceForTier(entry?.contentTierId);
    }
    return total;
  }
}

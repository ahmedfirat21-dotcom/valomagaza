import '../core/constants.dart';

class RawSkinOffer {
  const RawSkinOffer({required this.itemId, required this.price});

  final String itemId;
  final int price;
}

class RawNightMarketOffer {
  const RawNightMarketOffer({
    required this.itemId,
    required this.originalPrice,
    required this.discountedPrice,
    required this.discountPercent,
    required this.isSeen,
  });

  final String itemId;
  final int originalPrice;
  final int discountedPrice;
  final int discountPercent;
  final bool isSeen;
}

class StorefrontSnapshot {
  const StorefrontSnapshot({
    required this.offers,
    required this.remainingSeconds,
    required this.nightMarketOffers,
    required this.nightMarketRemainingSeconds,
  });

  final List<RawSkinOffer> offers;
  final int remainingSeconds;
  final List<RawNightMarketOffer> nightMarketOffers;
  final int nightMarketRemainingSeconds;

  factory StorefrontSnapshot.fromJson(Map<String, dynamic> json) {
    final root = _map(json['Store'] ?? json['store']) ?? json;
    final panel =
        _map(root['SkinsPanelLayout'] ?? root['skinsPanelLayout']) ??
        const <String, dynamic>{};
    final rawOffers =
        panel['SingleItemStoreOffers'] ?? panel['singleItemStoreOffers'];
    if (rawOffers is! List) {
      throw const FormatException('SkinsPanelLayout bulunamadı.');
    }

    final offers = <RawSkinOffer>[];
    for (final value in rawOffers) {
      final offer = _map(value);
      if (offer == null) continue;
      final itemId = _itemIdFromOffer(offer);
      final price = _currencyValue(
        _map(offer['Cost'] ?? offer['cost']),
        AppConstants.vpCurrencyId,
      );
      if (itemId != null && price != null) {
        offers.add(RawSkinOffer(itemId: itemId, price: price));
      }
    }

    final bonusStore =
        _map(
          root['BonusStore'] ??
              root['bonusStore'] ??
              json['BonusStore'] ??
              json['bonusStore'],
        ) ??
        const <String, dynamic>{};
    final rawBonusOffers =
        bonusStore['BonusStoreOffers'] ?? bonusStore['bonusStoreOffers'];
    final nightMarketOffers = <RawNightMarketOffer>[];
    if (rawBonusOffers is List) {
      for (final value in rawBonusOffers) {
        final bonus = _map(value);
        final offer = _map(bonus?['Offer'] ?? bonus?['offer']);
        if (bonus == null || offer == null) continue;
        final itemId = _itemIdFromOffer(offer);
        final originalPrice = _currencyValue(
          _map(offer['Cost'] ?? offer['cost']),
          AppConstants.vpCurrencyId,
        );
        final discountedPrice = _currencyValue(
          _map(bonus['DiscountCosts'] ?? bonus['discountCosts']),
          AppConstants.vpCurrencyId,
        );
        if (itemId == null ||
            originalPrice == null ||
            discountedPrice == null) {
          continue;
        }
        nightMarketOffers.add(
          RawNightMarketOffer(
            itemId: itemId,
            originalPrice: originalPrice,
            discountedPrice: discountedPrice,
            discountPercent: _intValue(
              bonus['DiscountPercent'] ?? bonus['discountPercent'],
            ),
            isSeen: bonus['IsSeen'] == true || bonus['isSeen'] == true,
          ),
        );
      }
    }

    final seconds = _intValue(
      panel['SingleItemOffersRemainingDurationInSeconds'] ??
          panel['singleItemOffersRemainingDurationInSeconds'],
    );
    final nightMarketSeconds = _intValue(
      bonusStore['BonusStoreRemainingDurationInSeconds'] ??
          bonusStore['bonusStoreRemainingDurationInSeconds'],
    );
    if (offers.isEmpty) {
      throw const FormatException('Teklifler çözümlenemedi.');
    }
    return StorefrontSnapshot(
      offers: offers.take(4).toList(growable: false),
      remainingSeconds: seconds,
      nightMarketOffers: nightMarketOffers.toList(growable: false),
      nightMarketRemainingSeconds: nightMarketSeconds,
    );
  }

  static String? _itemIdFromOffer(Map<String, dynamic> offer) {
    final rewards = offer['Rewards'] ?? offer['rewards'];
    if (rewards is List && rewards.isNotEmpty) {
      final reward = _map(rewards.first);
      final itemId = (reward?['ItemID'] ?? reward?['itemId'])?.toString();
      if (itemId != null && itemId.isNotEmpty) return itemId;
    }
    final offerId = (offer['OfferID'] ?? offer['offerId'])?.toString();
    return offerId == null || offerId.isEmpty ? null : offerId;
  }

  static int? _currencyValue(Map<String, dynamic>? values, String uuid) {
    if (values == null) return null;
    final value = values[uuid] ?? values[uuid.toLowerCase()];
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  static int _intValue(Object? value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static Map<String, dynamic>? _map(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }
}

class SkinLevel {
  const SkinLevel({
    required this.uuid,
    required this.displayName,
    this.levelItem,
    this.displayIcon,
    this.streamedVideo,
  });

  final String uuid;
  final String displayName;
  final String? levelItem;
  final String? displayIcon;
  final String? streamedVideo;
}

class SkinChroma {
  const SkinChroma({
    required this.uuid,
    required this.displayName,
    this.displayIcon,
    this.fullRender,
    this.swatch,
    this.streamedVideo,
  });

  final String uuid;
  final String displayName;
  final String? displayIcon;
  final String? fullRender;
  final String? swatch;
  final String? streamedVideo;
}

class SkinCatalogEntry {
  const SkinCatalogEntry({
    required this.name,
    required this.imageUrl,
    this.contentTierId,
    this.wallpaper,
    this.levels = const [],
    this.chromas = const [],
  });

  final String name;
  final String imageUrl;
  final String? contentTierId;
  final String? wallpaper;
  final List<SkinLevel> levels;
  final List<SkinChroma> chromas;
}

class ContentTierInfo {
  const ContentTierInfo({required this.name, this.colorHex});

  final String name;
  final String? colorHex;
}

class SkinOffer {
  const SkinOffer({
    required this.itemId,
    required this.name,
    required this.imageUrl,
    required this.price,
    required this.tierName,
    this.tierColorHex,
    this.originalPrice,
    this.discountPercent,
    this.isSeen,
    this.wallpaper,
    this.levels = const [],
    this.chromas = const [],
  });

  final String itemId;
  final String name;
  final String imageUrl;
  final int price;
  final String tierName;
  final String? tierColorHex;
  final int? originalPrice;
  final int? discountPercent;
  final bool? isSeen;
  final String? wallpaper;
  final List<SkinLevel> levels;
  final List<SkinChroma> chromas;

  bool get isNightMarket => originalPrice != null;

  factory SkinOffer.resolve(
    RawSkinOffer raw,
    Map<String, SkinCatalogEntry> catalog,
    Map<String, ContentTierInfo> tiers,
  ) => _resolve(
    itemId: raw.itemId,
    price: raw.price,
    catalog: catalog,
    tiers: tiers,
  );

  factory SkinOffer.resolveNightMarket(
    RawNightMarketOffer raw,
    Map<String, SkinCatalogEntry> catalog,
    Map<String, ContentTierInfo> tiers,
  ) => _resolve(
    itemId: raw.itemId,
    price: raw.discountedPrice,
    originalPrice: raw.originalPrice,
    discountPercent: raw.discountPercent,
    isSeen: raw.isSeen,
    catalog: catalog,
    tiers: tiers,
  );

  static SkinOffer _resolve({
    required String itemId,
    required int price,
    required Map<String, SkinCatalogEntry> catalog,
    required Map<String, ContentTierInfo> tiers,
    int? originalPrice,
    int? discountPercent,
    bool? isSeen,
  }) {
    final asset = catalog[itemId.toLowerCase()];
    final tier = asset?.contentTierId == null
        ? null
        : tiers[asset!.contentTierId!.toLowerCase()];
    return SkinOffer(
      itemId: itemId,
      name: asset?.name ?? 'Bilinmeyen Kaplama',
      imageUrl: asset?.imageUrl ?? '',
      price: price,
      originalPrice: originalPrice,
      discountPercent: discountPercent,
      isSeen: isSeen,
      tierName: tier?.name ?? 'İçerik seviyesi bilinmiyor',
      tierColorHex: tier?.colorHex,
      wallpaper: asset?.wallpaper,
      levels: asset?.levels ?? const [],
      chromas: asset?.chromas ?? const [],
    );
  }
}

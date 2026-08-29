import 'skin_offer.dart';

class WeaponSkinCatalogEntry {
  const WeaponSkinCatalogEntry({
    required this.skinId,
    required this.name,
    required this.weaponName,
    required this.weaponCategory,
    required this.imageUrl,
    this.contentTierId,
  });

  final String skinId;
  final String name;
  final String weaponName;
  final String weaponCategory;
  final String imageUrl;
  final String? contentTierId;

  bool get isMelee => weaponCategory.toLowerCase().contains('melee');
}

class CollectionItem {
  const CollectionItem({
    required this.itemId,
    required this.name,
    required this.weaponName,
    required this.weaponCategory,
    required this.imageUrl,
    required this.tierName,
    this.tierColorHex,
    this.isEquipped = false,
  });

  final String itemId;
  final String name;
  final String weaponName;
  final String weaponCategory;
  final String imageUrl;
  final String tierName;
  final String? tierColorHex;
  final bool isEquipped;

  bool get isMelee => weaponCategory.toLowerCase().contains('melee');

  CollectionItem copyWith({bool? isEquipped}) => CollectionItem(
    itemId: itemId,
    name: name,
    weaponName: weaponName,
    weaponCategory: weaponCategory,
    imageUrl: imageUrl,
    tierName: tierName,
    tierColorHex: tierColorHex,
    isEquipped: isEquipped ?? this.isEquipped,
  );

  factory CollectionItem.resolve({
    required String itemId,
    required Map<String, WeaponSkinCatalogEntry> catalog,
    required Map<String, ContentTierInfo> tiers,
    required Set<String> equippedItemIds,
  }) {
    final asset = catalog[itemId.toLowerCase()];
    final tier = asset?.contentTierId == null
        ? null
        : tiers[asset!.contentTierId!.toLowerCase()];
    return CollectionItem(
      itemId: itemId,
      name: asset?.name ?? 'Bilinmeyen kaplama',
      weaponName: asset?.weaponName ?? 'Silah',
      weaponCategory: asset?.weaponCategory ?? '',
      imageUrl: asset?.imageUrl ?? '',
      tierName: tier?.name ?? 'İçerik seviyesi bilinmiyor',
      tierColorHex: tier?.colorHex,
      isEquipped: equippedItemIds.contains(itemId.toLowerCase()),
    );
  }
}

class PlayerLoadoutItem {
  const PlayerLoadoutItem({
    required this.weaponId,
    required this.skinId,
    required this.skinLevelId,
  });

  final String weaponId;
  final String skinId;
  final String skinLevelId;

  String get activeSkinId => skinLevelId.isNotEmpty ? skinLevelId : skinId;
}

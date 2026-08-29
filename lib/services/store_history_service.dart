import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/skin_offer.dart';

class StoreHistoryDay {
  const StoreHistoryDay({
    required this.date,
    required this.offers,
    required this.nightMarketOffers,
  });

  final DateTime date;
  final List<SkinOffer> offers;
  final List<SkinOffer> nightMarketOffers;

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'offers': offers.map((o) => _offerToMap(o)).toList(),
    'nightMarketOffers':
        nightMarketOffers.map((o) => _offerToMap(o)).toList(),
  };

  factory StoreHistoryDay.fromJson(Map<String, dynamic> json) {
    final date = DateTime.tryParse(json['date']?.toString() ?? '') ??
        DateTime.now();
    final rawOffers = json['offers'] as List? ?? [];
    final rawNightOffers = json['nightMarketOffers'] as List? ?? [];

    return StoreHistoryDay(
      date: date,
      offers: rawOffers
          .map((item) => _mapToOffer(item as Map<String, dynamic>))
          .toList(growable: false),
      nightMarketOffers: rawNightOffers
          .map((item) => _mapToOffer(item as Map<String, dynamic>))
          .toList(growable: false),
    );
  }

  static Map<String, dynamic> _offerToMap(SkinOffer offer) => {
    'itemId': offer.itemId,
    'name': offer.name,
    'imageUrl': offer.imageUrl,
    'price': offer.price,
    'tierName': offer.tierName,
    'tierColorHex': offer.tierColorHex,
    'originalPrice': offer.originalPrice,
    'discountPercent': offer.discountPercent,
  };

  static SkinOffer _mapToOffer(Map<String, dynamic> map) => SkinOffer(
    itemId: map['itemId']?.toString() ?? '',
    name: map['name']?.toString() ?? 'Bilinmeyen Kaplama',
    imageUrl: map['imageUrl']?.toString() ?? '',
    price: (map['price'] as num?)?.toInt() ?? 0,
    tierName: map['tierName']?.toString() ?? '',
    tierColorHex: map['tierColorHex']?.toString(),
    originalPrice: (map['originalPrice'] as num?)?.toInt(),
    discountPercent: (map['discountPercent'] as num?)?.toInt(),
  );
}

class StoreHistoryService {
  static const _historyPrefix = 'valo_magaza_history_';

  Future<void> saveStorefront(
    String puuid, {
    required List<SkinOffer> offers,
    required List<SkinOffer> nightMarketOffers,
  }) async {
    if (offers.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      final todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final key = '$_historyPrefix${puuid.toLowerCase()}';

      final history = await getHistory(puuid);
      final filtered = history.where((entry) {
        final entryDate = entry.date;
        final entryStr = '${entryDate.year}-${entryDate.month.toString().padLeft(2, '0')}-${entryDate.day.toString().padLeft(2, '0')}';
        return entryStr != todayStr;
      }).toList();

      final todayEntry = StoreHistoryDay(
        date: now,
        offers: offers,
        nightMarketOffers: nightMarketOffers,
      );

      filtered.insert(0, todayEntry);

      // En fazla son 30 günü tut
      final limited = filtered.take(30).toList();
      final rawList = limited.map((entry) => jsonEncode(entry.toJson())).toList();
      await prefs.setStringList(key, rawList);
    } catch (_) {}
  }

  Future<List<StoreHistoryDay>> getHistory(String puuid) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_historyPrefix${puuid.toLowerCase()}';
      final rawList = prefs.getStringList(key) ?? [];

      final list = <StoreHistoryDay>[];
      for (final raw in rawList) {
        try {
          final decoded = jsonDecode(raw) as Map<String, dynamic>;
          list.add(StoreHistoryDay.fromJson(decoded));
        } catch (_) {}
      }
      return list;
    } catch (_) {
      return [];
    }
  }

  Future<void> clearAllHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs
          .getKeys()
          .where((key) => key.startsWith(_historyPrefix))
          .toList(growable: false);
      for (final key in keys) {
        await prefs.remove(key);
      }
    } catch (_) {}
  }
}

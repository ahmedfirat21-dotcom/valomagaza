import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:valo_magaza/models/skin_offer.dart';

void main() {
  late StorefrontSnapshot snapshot;

  setUpAll(() {
    final source = File('test/fixtures/storefront.json').readAsStringSync();
    snapshot = StorefrontSnapshot.fromJson(
      Map<String, dynamic>.from(jsonDecode(source) as Map),
    );
  });

  test('storefront JSON ve kalan süre çözümlenir', () {
    expect(snapshot.remainingSeconds, 43210);
    expect(snapshot.offers, isNotEmpty);
  });

  test('dört günlük teklif doğru sırayla çıkarılır', () {
    expect(snapshot.offers, hasLength(4));
    expect(snapshot.offers.map((offer) => offer.itemId), [
      'level-one',
      'level-two',
      'level-three',
      'level-four',
    ]);
  });

  test('fiyat yalnız VP currency UUID değerinden okunur', () {
    expect(snapshot.offers.map((offer) => offer.price), [
      875,
      1275,
      1775,
      2175,
    ]);
  });

  test('Gece Pazarı indirim ayrıntıları çözümlenir', () {
    expect(snapshot.nightMarketRemainingSeconds, 654321);
    expect(snapshot.nightMarketOffers, hasLength(2));
    final first = snapshot.nightMarketOffers.first;
    expect(first.itemId, 'night-level-one');
    expect(first.originalPrice, 1775);
    expect(first.discountedPrice, 1225);
    expect(first.discountPercent, 31);
    expect(first.isSeen, isFalse);
  });
}

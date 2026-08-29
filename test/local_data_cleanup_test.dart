import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:valo_magaza/models/skin_offer.dart';
import 'package:valo_magaza/providers/wishlist_provider.dart';
import 'package:valo_magaza/services/notification_service.dart';
import 'package:valo_magaza/services/store_history_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('istek listesi tamamen temizlenir', () async {
    final wishlist = WishlistProvider();
    await Future<void>.delayed(Duration.zero);
    await wishlist.toggleWishlist('skin-id');
    expect(wishlist.count, 1);

    await wishlist.clear();

    expect(wishlist.count, 0);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList('valo_magaza_wishlist_items'), isNull);
  });

  test('bütün hesaplara ait mağaza geçmişi temizlenir', () async {
    final history = StoreHistoryService();
    const offer = SkinOffer(
      itemId: 'skin-id',
      name: 'Test Skin',
      imageUrl: '',
      price: 1775,
      tierName: 'Premium',
    );
    await history.saveStorefront(
      'first-puuid',
      offers: const [offer],
      nightMarketOffers: const [],
    );
    await history.saveStorefront(
      'second-puuid',
      offers: const [offer],
      nightMarketOffers: const [],
    );

    await history.clearAllHistory();

    expect(await history.getHistory('first-puuid'), isEmpty);
    expect(await history.getHistory('second-puuid'), isEmpty);
  });

  test('bildirim tercihi ve günlük bildirim kayıtları temizlenir', () async {
    SharedPreferences.setMockInitialValues({
      'valo_magaza_notifications_enabled': false,
      'valo_magaza_last_notification_mock-puuid': '2026-08-29',
    });
    final service = NotificationService();

    await service.clearLocalSettings();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('valo_magaza_notifications_enabled'), isNull);
    expect(
      prefs.getString('valo_magaza_last_notification_mock-puuid'),
      isNull,
    );
  });
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../core/app_theme.dart';
import '../core/constants.dart';
import '../models/auth_session.dart';
import '../providers/auth_provider.dart';
import '../providers/collection_provider.dart';
import '../providers/competitive_provider.dart';
import '../providers/match_provider.dart';
import '../providers/store_provider.dart';
import '../providers/wishlist_provider.dart';
import '../services/notification_service.dart';
import '../services/store_history_service.dart';
import '../widgets/countdown_timer.dart';
import '../widgets/error_view.dart';
import '../widgets/skin_card.dart';
import '../widgets/skin_search_sheet.dart';
import '../widgets/store_history_sheet.dart';
import '../widgets/wallet_header.dart';
import '../widgets/wishlist_sheet.dart';

class StoreScreen extends StatefulWidget {
  const StoreScreen({super.key});

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> {
  String? _observedPuuid;

  void _loadForSession(AuthSession session) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final store = context.read<StoreProvider>();
      store.load(session, force: true).then((_) {
        if (!mounted) return;
        final activePuuid = context.read<AuthProvider>().session?.puuid;
        if (activePuuid == session.puuid) {
          _checkHistoryAndNotifications(store, session);
        }
      });
    });
  }

  Future<void> _refreshStore() async {
    final session = context.read<AuthProvider>().session;
    if (session == null) return;
    final store = context.read<StoreProvider>();
    await store.load(session, force: true);
    if (!mounted) return;
    _checkHistoryAndNotifications(store, session);
  }

  void _checkHistoryAndNotifications(StoreProvider store, AuthSession session) {
    if (store.status != StoreStatus.ready || store.offers.isEmpty) return;
    // Geçmişe kaydet
    context.read<StoreHistoryService>().saveStorefront(
      session.puuid,
      offers: store.offers,
      nightMarketOffers: store.nightMarketOffers,
    );

    // İstek listesi eşleşmesi bildirimi
    final wishlist = context.read<WishlistProvider>();
    final allOffers = [...store.offers, ...store.nightMarketOffers];
    final matches = wishlist.getMatchingOffers(allOffers);
    if (matches.isNotEmpty) {
      context.read<NotificationService>().showWishlistMatchNotification(
        puuid: session.puuid,
        skinNames: matches.map((m) => m.name).toList(),
      );
    }
  }

  Future<void> _logout() async {
    final approved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Çıkış yapılsın mı?'),
        content: const Text(
          'Bu cihazda saklanan tüm Riot oturum verileri silinecek.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Çıkış Yap'),
          ),
        ],
      ),
    );
    if (approved != true || !mounted) return;
    context.read<StoreProvider>().reset();
    context.read<MatchProvider>().reset();
    context.read<CollectionProvider>().reset();
    context.read<CompetitiveProvider>().reset();
    await context.read<AuthProvider>().logout();
  }

  void _showAbout() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.info_outline_rounded),
        title: const Text('Valo Mağaza Hakkında'),
        content: const Text(
          '${AppConstants.legalNotice}\n\n'
          'Bu uygulama yalnızca kişisel mağaza ve bakiye görüntüler; satın alma özelliği içermez.',
          style: TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }

  Future<void> _shareStore(BuildContext context, StoreProvider store) async {
    if (store.offers.isEmpty) return;
    final buffer = StringBuffer();
    buffer.writeln('🎯 Bugünün VALORANT Mağazası:');
    for (final offer in store.offers) {
      buffer.writeln('• ${offer.name} (${offer.price} VP)');
    }
    if (store.nightMarketOffers.isNotEmpty) {
      buffer.writeln('\n🌙 Gece Pazarı:');
      for (final offer in store.nightMarketOffers) {
        buffer.writeln('• ${offer.name} (%${offer.discountPercent} indirim -> ${offer.price} VP)');
      }
    }
    final text = buffer.toString();
    try {
      await SharePlus.instance.share(
        ShareParams(text: text, subject: 'VALORANT Günlük Mağaza'),
      );
    } catch (_) {
      await Clipboard.setData(ClipboardData(text: text));
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Mağaza listesi panoya kopyalandı! 📋'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<AuthProvider>().session;
    if (session != null && session.puuid != _observedPuuid) {
      _observedPuuid = session.puuid;
      _loadForSession(session);
    }
    final store = context.watch<StoreProvider>();
    final wishlist = context.watch<WishlistProvider>();
    final allOffers = [...store.offers, ...store.nightMarketOffers];
    final wishlistMatches = wishlist.getMatchingOffers(allOffers);

    final screenWidth = MediaQuery.sizeOf(context).width;
    final horizontalPadding = screenWidth > 900
        ? (screenWidth - 900) / 2 + 16
        : 16.0;
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Mağazam',
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: -0.4),
        ),
        actions: [
          IconButton(
            tooltip: 'İstek Listem (${wishlist.count})',
            onPressed: () => WishlistSheet.show(context),
            icon: Badge(
              isLabelVisible: wishlist.count > 0,
              label: Text('${wishlist.count}'),
              backgroundColor: AppColors.accent,
              child: const Icon(Icons.favorite_rounded),
            ),
          ),
          IconButton(
            tooltip: 'Mağazayı Paylaş',
            onPressed: store.offers.isEmpty ? null : () => _shareStore(context, store),
            icon: const Icon(Icons.share_outlined),
          ),
          IconButton(
            tooltip: 'Yenile',
            onPressed: store.isLoading ? null : _refreshStore,
            icon: const Icon(Icons.refresh_rounded),
          ),
          PopupMenuButton<String>(
            tooltip: 'Menü',
            onSelected: (value) {
              if (value == 'search') SkinSearchSheet.show(context);
              if (value == 'wishlist') WishlistSheet.show(context);
              if (value == 'history') StoreHistorySheet.show(context);
              if (value == 'about') _showAbout();
              if (value == 'logout') _logout();
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'search',
                child: ListTile(
                  leading: Icon(Icons.search_rounded, color: AppColors.accent),
                  title: Text('Katalogda Skin Ara'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'wishlist',
                child: ListTile(
                  leading: const Icon(Icons.favorite_rounded, color: AppColors.accent),
                  title: Text('İstek Listem (${wishlist.count})'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'history',
                child: ListTile(
                  leading: Icon(Icons.history_rounded, color: AppColors.gold),
                  title: Text('Mağaza Geçmişi'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'about',
                child: ListTile(
                  leading: Icon(Icons.info_outline_rounded),
                  title: Text('Hakkında'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: ListTile(
                  leading: Icon(Icons.logout_rounded),
                  title: Text('Çıkış Yap'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshStore,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                8,
                horizontalPadding,
                18,
              ),
              sliver: SliverList.list(
                children: [
                  WalletHeader(wallet: store.wallet),
                  if (wishlistMatches.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.accent.withValues(alpha: 0.22),
                            AppColors.surface,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.accent.withValues(alpha: 0.6)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.stars_rounded, color: AppColors.accent, size: 28),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '🎉 İSTEK LİSTEN MAĞAZANDA!',
                                  style: TextStyle(
                                    color: AppColors.accent,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 13,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${wishlistMatches.map((m) => m.name).join(', ')} bugün mağazana geldi!',
                                  style: const TextStyle(
                                    color: AppColors.ivory,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'BUGÜNÜN TEKLİFLERİ',
                          style: TextStyle(
                            color: AppColors.muted,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      if (store.refreshAt != null)
                        CountdownTimer(target: store.refreshAt!),
                    ],
                  ),
                ],
              ),
            ),
            if (store.status == StoreStatus.error)
              SliverFillRemaining(
                hasScrollBody: false,
                child: ErrorView(
                  message: store.errorMessage ?? 'Mağaza verisi alınamadı.',
                  onRetry: store.refresh,
                ),
              )
            else if (store.status == StoreStatus.loading)
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  0,
                  horizontalPadding,
                  24,
                ),
                sliver: const _LoadingGrid(),
              )
            else if (store.offers.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Text(
                    'Gösterilecek günlük teklif bulunamadı.',
                    style: TextStyle(color: AppColors.muted),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  0,
                  horizontalPadding,
                  28,
                ),
                sliver: SliverGrid.builder(
                  itemCount: store.offers.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: screenWidth < 370 ? 9 : 14,
                    mainAxisSpacing: screenWidth < 370 ? 9 : 14,
                    mainAxisExtent: screenWidth < 370 ? 292 : 318,
                  ),
                  itemBuilder: (_, index) =>
                      SkinCard(offer: store.offers[index]),
                ),
              ),
            if (store.status == StoreStatus.ready)
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  4,
                  horizontalPadding,
                  16,
                ),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    children: [
                      const Icon(
                        Icons.auto_awesome_rounded,
                        color: AppColors.accent,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'GECE PAZARI',
                          style: TextStyle(
                            color: AppColors.ivory,
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      if (store.nightMarketRefreshAt != null)
                        CountdownTimer(target: store.nightMarketRefreshAt!),
                    ],
                  ),
                ),
              ),
            if (store.status == StoreStatus.ready &&
                store.nightMarketOffers.isEmpty)
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  0,
                  horizontalPadding,
                  28,
                ),
                sliver: SliverToBoxAdapter(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.surfaceBright),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.nights_stay_outlined,
                          color: AppColors.muted,
                          size: 28,
                        ),
                        SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            'Gece Pazarı şu anda aktif değil. Etkinlik açıldığında kişisel indirimli tekliflerin burada görünecek.',
                            style: TextStyle(
                              color: AppColors.muted,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            if (store.status == StoreStatus.ready &&
                store.nightMarketOffers.isNotEmpty)
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  0,
                  horizontalPadding,
                  28,
                ),
                sliver: SliverGrid.builder(
                  itemCount: store.nightMarketOffers.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: screenWidth < 370 ? 9 : 14,
                    mainAxisSpacing: screenWidth < 370 ? 9 : 14,
                    mainAxisExtent: screenWidth < 370 ? 302 : 328,
                  ),
                  itemBuilder: (_, index) =>
                      SkinCard(offer: store.nightMarketOffers[index]),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _LoadingGrid extends StatelessWidget {
  const _LoadingGrid();

  @override
  Widget build(BuildContext context) {
    return SliverGrid.builder(
      itemCount: 4,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        mainAxisExtent: 318,
      ),
      itemBuilder: (_, index) => Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: AppColors.surfaceBright,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  _SkeletonLine(widthFactor: 1),
                  SizedBox(height: 10),
                  _SkeletonLine(widthFactor: 0.62),
                  SizedBox(height: 14),
                  _SkeletonLine(widthFactor: 0.42),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SkeletonLine extends StatelessWidget {
  const _SkeletonLine({required this.widthFactor});

  final double widthFactor;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: FractionallySizedBox(
        widthFactor: widthFactor,
        child: Container(
          height: 10,
          decoration: BoxDecoration(
            color: AppColors.surfaceBright,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}

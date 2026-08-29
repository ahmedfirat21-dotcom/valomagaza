import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/app_theme.dart';
import '../models/skin_offer.dart';
import '../providers/store_provider.dart';
import '../providers/wishlist_provider.dart';
import '../services/valorant_assets_service.dart';
import 'skin_detail_sheet.dart';
import 'skin_search_sheet.dart';

class WishlistSheet extends StatefulWidget {
  const WishlistSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const WishlistSheet(),
    );
  }

  @override
  State<WishlistSheet> createState() => _WishlistSheetState();
}

class _WishlistSheetState extends State<WishlistSheet> {
  final _searchController = TextEditingController();
  String _filterQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wishlist = context.watch<WishlistProvider>();
    final assetsService = context.read<ValorantAssetsService>();
    final store = context.watch<StoreProvider>();
    final walletVp = store.wallet?.vp;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.90,
      ),
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.surfaceBright,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
            child: Row(
              children: [
                const Icon(
                  Icons.favorite_rounded,
                  color: AppColors.accent,
                  size: 24,
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'İstek Listem',
                    style: TextStyle(
                      color: AppColors.ivory,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                // Skin Ara & Ekle Butonu
                FilledButton.icon(
                  onPressed: () => SkinSearchSheet.show(context),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Skin Ekle'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: AppColors.surfaceBright, height: 1),
          if (wishlist.wishlistIds.isEmpty)
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.favorite_border_rounded,
                        color: AppColors.muted,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'İstek Listeniz Boş',
                        style: TextStyle(
                          color: AppColors.ivory,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Mağazadaki veya Koleksiyon sayfasındaki silahlara dokunarak kalp simgesiyle istek listenize ekleyebilirsiniz. "Skin Ekle" butonuyla tüm katalogda arama yapabilirsiniz!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.muted,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 20),
                      FilledButton.icon(
                        onPressed: () => SkinSearchSheet.show(context),
                        icon: const Icon(Icons.search_rounded),
                        label: const Text('Katalogda Skin Ara'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.surfaceBright,
                          foregroundColor: AppColors.ivory,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            Expanded(
              child: FutureBuilder<Map<String, SkinCatalogEntry>>(
                future: assetsService.getSkinCatalog(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    );
                  }
                  final catalog = snapshot.data!;
                  final totalVp = wishlist.calculateTotalEstimatedVp(catalog);
                  final ids = wishlist.wishlistIds.where((id) {
                    if (_filterQuery.isEmpty) return true;
                    final skin = catalog[id];
                    return skin != null && skin.name.toLowerCase().contains(_filterQuery);
                  }).toList();

                  return ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // VP Bütçe ve Bakiye Kartı
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: AppColors.gold.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.account_balance_wallet_rounded, color: AppColors.gold, size: 20),
                                const SizedBox(width: 8),
                                const Text(
                                  'VP BÜTÇE HESAPLAYICI',
                                  style: TextStyle(
                                    color: AppColors.muted,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.1,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  '${wishlist.count} Kaplama',
                                  style: const TextStyle(
                                    color: AppColors.muted,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Toplam Maliyet', style: TextStyle(color: AppColors.muted, fontSize: 11)),
                                    const SizedBox(height: 2),
                                    Text(
                                      '~${NumberFormat.decimalPattern('tr_TR').format(totalVp)} VP',
                                      style: const TextStyle(
                                        color: AppColors.gold,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ],
                                ),
                                if (walletVp != null) ...[
                                  Container(width: 1, height: 32, color: AppColors.surfaceBright),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Mevcut Bakiye', style: TextStyle(color: AppColors.muted, fontSize: 11)),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${NumberFormat.decimalPattern('tr_TR').format(walletVp)} VP',
                                        style: const TextStyle(
                                          color: AppColors.ivory,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Container(width: 1, height: 32, color: AppColors.surfaceBright),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        walletVp >= totalVp ? 'Durum' : 'Eksik VP',
                                        style: const TextStyle(color: AppColors.muted, fontSize: 11),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        walletVp >= totalVp
                                            ? 'Yeterli 💎'
                                            : '-${NumberFormat.decimalPattern('tr_TR').format(totalVp - walletVp)} VP',
                                        style: TextStyle(
                                          color: walletVp >= totalVp ? AppColors.emerald : AppColors.accent,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      // İstek listesi içi arama
                      TextField(
                        controller: _searchController,
                        onChanged: (v) => setState(() => _filterQuery = v.trim().toLowerCase()),
                        style: const TextStyle(color: AppColors.ivory, fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'İstek listenizde filtreleyin…',
                          hintStyle: const TextStyle(color: AppColors.muted, fontSize: 13),
                          prefixIcon: const Icon(Icons.search_rounded, color: AppColors.muted, size: 18),
                          suffixIcon: _filterQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded, color: AppColors.muted, size: 16),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _filterQuery = '');
                                  },
                                )
                              : null,
                          filled: true,
                          fillColor: AppColors.surface,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: AppColors.surfaceBright),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: AppColors.surfaceBright),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Kaplama Listesi
                      ...ids.map((id) {
                        final skin = catalog[id];
                        final name = skin?.name ?? 'Bilinmeyen Kaplama';
                        final imageUrl = skin?.imageUrl ?? '';
                        final estimatedVp = WishlistProvider.estimatePriceForTier(skin?.contentTierId);

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Material(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(16),
                            child: InkWell(
                              onTap: () {
                                if (skin != null) {
                                  final offer = SkinOffer(
                                    itemId: id,
                                    name: name,
                                    imageUrl: imageUrl,
                                    price: estimatedVp,
                                    tierName: 'İstek Listesi',
                                    levels: skin.levels,
                                    chromas: skin.chromas,
                                  );
                                  SkinDetailSheet.show(context, offer);
                                }
                              },
                              borderRadius: BorderRadius.circular(16),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 60,
                                      height: 48,
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: AppColors.surfaceBright,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: imageUrl.isNotEmpty
                                          ? CachedNetworkImage(
                                              imageUrl: imageUrl,
                                              fit: BoxFit.contain,
                                            )
                                          : const Icon(
                                              Icons.image_not_supported_outlined,
                                              color: AppColors.muted,
                                              size: 24,
                                            ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            name,
                                            style: const TextStyle(
                                              color: AppColors.ivory,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            '~$estimatedVp VP • Videoları incele',
                                            style: const TextStyle(
                                              color: AppColors.gold,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: 'Listeden Çıkar',
                                      onPressed: () => wishlist.toggleWishlist(id),
                                      icon: const Icon(
                                        Icons.delete_outline_rounded,
                                        color: AppColors.muted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

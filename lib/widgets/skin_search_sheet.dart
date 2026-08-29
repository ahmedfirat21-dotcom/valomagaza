import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_theme.dart';
import '../models/skin_offer.dart';
import '../providers/wishlist_provider.dart';
import '../services/valorant_assets_service.dart';
import 'skin_detail_sheet.dart';

class SkinSearchSheet extends StatefulWidget {
  const SkinSearchSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const SkinSearchSheet(),
    );
  }

  @override
  State<SkinSearchSheet> createState() => _SkinSearchSheetState();
}

class _SkinSearchSheetState extends State<SkinSearchSheet> {
  final _searchController = TextEditingController();
  String _query = '';
  String _selectedWeaponFilter = 'Tümü';

  static const _weaponFilters = [
    'Tümü',
    'Vandal',
    'Phantom',
    'Bıçak',
    'Operator',
    'Sheriff',
    'Ghost',
    'Spectre',
    'Classic',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final assetsService = context.read<ValorantAssetsService>();
    final wishlist = context.watch<WishlistProvider>();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.90,
      ),
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
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
                  Icons.search_rounded,
                  color: AppColors.accent,
                  size: 24,
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Skin Ara & İstek Listesine Ekle',
                    style: TextStyle(
                      color: AppColors.ivory,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.4,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, color: AppColors.muted),
                ),
              ],
            ),
          ),
          // Arama Girişi
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _query = val.trim().toLowerCase()),
              style: const TextStyle(color: AppColors.ivory),
              decoration: InputDecoration(
                hintText: 'Örn: Asil Vandal, Yağmacı, Kuronami…',
                hintStyle: const TextStyle(color: AppColors.muted, fontSize: 14),
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.muted, size: 20),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, color: AppColors.muted, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.surface,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.surfaceBright),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.surfaceBright),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Hızlı Kategori Filtreleri
          SizedBox(
            height: 38,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              itemCount: _weaponFilters.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final filter = _weaponFilters[index];
                final isSelected = _selectedWeaponFilter == filter;
                return ChoiceChip(
                  label: Text(filter),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedWeaponFilter = filter);
                    }
                  },
                  selectedColor: AppColors.accent.withValues(alpha: 0.25),
                  backgroundColor: AppColors.surface,
                  side: BorderSide(
                    color: isSelected ? AppColors.accent : AppColors.surfaceBright,
                  ),
                  labelStyle: TextStyle(
                    color: isSelected ? AppColors.ivory : AppColors.muted,
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          const Divider(color: AppColors.surfaceBright, height: 1),
          // Liste
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
                final uniqueSkins = <String, SkinCatalogEntry>{};

                // Yalnızca temel kaplamaları (aynı ada sahip tekil girişleri) al
                for (final entry in catalog.entries) {
                  final skin = entry.value;
                  if (skin.imageUrl.isNotEmpty && !uniqueSkins.containsKey(skin.name)) {
                    uniqueSkins[skin.name] = skin;
                  }
                }

                var filteredList = uniqueSkins.entries.where((e) {
                  final skin = e.value;
                  final name = skin.name.toLowerCase();

                  // Arama filtresi
                  if (_query.isNotEmpty && !name.contains(_query)) {
                    return false;
                  }

                  // Silah filtresi
                  if (_selectedWeaponFilter != 'Tümü') {
                    if (_selectedWeaponFilter == 'Bıçak') {
                      final isMelee = name.contains('bıçak') ||
                          name.contains('hançer') ||
                          name.contains('karambit') ||
                          name.contains('kılıç') ||
                          name.contains('balta') ||
                          name.contains('kelebek') ||
                          name.contains('yelpaze') ||
                          name.contains('asa') ||
                          name.contains('tatar') ||
                          name.contains('katar');
                      if (!isMelee) return false;
                    } else if (!name.contains(_selectedWeaponFilter.toLowerCase())) {
                      return false;
                    }
                  }

                  return true;
                }).toList(growable: false);

                if (filteredList.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.search_off_rounded, color: AppColors.muted, size: 44),
                          SizedBox(height: 12),
                          Text(
                            'Aradığınız kriterlere uygun kaplama bulunamadı.',
                            style: TextStyle(color: AppColors.muted, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredList.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = filteredList[index];
                    final skin = item.value;
                    // UUID'yi catalog'dan bul
                    final entryUuid = catalog.entries
                        .firstWhere(
                          (c) => c.value.name == skin.name,
                          orElse: () => catalog.entries.first,
                        )
                        .key;

                    final isWishlisted = wishlist.isWishlisted(entryUuid);
                    final hasVideo = skin.levels.any((l) => l.streamedVideo != null && l.streamedVideo!.isNotEmpty);
                    final estimatedVp = WishlistProvider.estimatePriceForTier(skin.contentTierId);

                    return Material(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        onTap: () {
                          final offer = SkinOffer(
                            itemId: entryUuid,
                            name: skin.name,
                            imageUrl: skin.imageUrl,
                            price: estimatedVp,
                            tierName: 'Katalog',
                            levels: skin.levels,
                            chromas: skin.chromas,
                          );
                          SkinDetailSheet.show(context, offer);
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          child: Row(
                            children: [
                              Container(
                                width: 56,
                                height: 44,
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceBright,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: CachedNetworkImage(
                                  imageUrl: skin.imageUrl,
                                  fit: BoxFit.contain,
                                  placeholder: (_, _) => const Center(
                                    child: SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 1.5),
                                    ),
                                  ),
                                  errorWidget: (_, _, _) => const Icon(
                                    Icons.broken_image_outlined,
                                    color: AppColors.muted,
                                    size: 20,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      skin.name,
                                      style: const TextStyle(
                                        color: AppColors.ivory,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Row(
                                      children: [
                                        if (hasVideo) ...[
                                          const Icon(
                                            Icons.play_circle_filled_rounded,
                                            size: 13,
                                            color: AppColors.accent,
                                          ),
                                          const SizedBox(width: 4),
                                          const Text(
                                            'Video Mevcut',
                                            style: TextStyle(
                                              color: AppColors.muted,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                        ],
                                        Text(
                                          '~$estimatedVp VP',
                                          style: const TextStyle(
                                            color: AppColors.gold,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                tooltip: isWishlisted ? 'İstek Listesinden Çıkar' : 'İstek Listesine Ekle',
                                onPressed: () async {
                                  final added = await wishlist.toggleWishlist(entryUuid);
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      behavior: SnackBarBehavior.floating,
                                      duration: const Duration(seconds: 2),
                                      content: Text(
                                        added
                                            ? '${skin.name} istek listesine eklendi! ✨'
                                            : '${skin.name} istek listesinden çıkarıldı.',
                                      ),
                                    ),
                                  );
                                },
                                icon: Icon(
                                  isWishlisted ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                  color: isWishlisted ? AppColors.accent : AppColors.muted,
                                  size: 22,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

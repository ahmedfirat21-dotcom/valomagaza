import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/app_theme.dart';
import '../models/skin_offer.dart';
import '../providers/wishlist_provider.dart';
import 'skin_video_player.dart';

class SkinDetailSheet extends StatefulWidget {
  const SkinDetailSheet({
    required this.offer,
    super.key,
  });

  final SkinOffer offer;

  static void show(BuildContext context, SkinOffer offer) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SkinDetailSheet(offer: offer),
    );
  }

  @override
  State<SkinDetailSheet> createState() => _SkinDetailSheetState();
}

class _SkinDetailSheetState extends State<SkinDetailSheet> {
  int _selectedLevelIndex = 0;
  int _selectedChromaIndex = 0;
  bool _isShowingChroma = false;

  @override
  void initState() {
    super.initState();
    // Varsa varsayılan olarak son seviyeyi (genelde en zengin animasyon/bitiriş seviyesi) seçelim
    if (widget.offer.levels.isNotEmpty) {
      _selectedLevelIndex = widget.offer.levels.length - 1;
    }
  }

  String? get _currentVideoUrl {
    if (_isShowingChroma && widget.offer.chromas.isNotEmpty) {
      final chroma = widget.offer.chromas[_selectedChromaIndex];
      if (chroma.streamedVideo != null && chroma.streamedVideo!.isNotEmpty) {
        return chroma.streamedVideo;
      }
    }
    if (widget.offer.levels.isNotEmpty && _selectedLevelIndex < widget.offer.levels.length) {
      final level = widget.offer.levels[_selectedLevelIndex];
      if (level.streamedVideo != null && level.streamedVideo!.isNotEmpty) {
        return level.streamedVideo;
      }
    }
    return null;
  }

  String get _currentImageUrl {
    if (_isShowingChroma && widget.offer.chromas.isNotEmpty) {
      final chroma = widget.offer.chromas[_selectedChromaIndex];
      if (chroma.fullRender != null && chroma.fullRender!.isNotEmpty) {
        return chroma.fullRender!;
      }
      if (chroma.displayIcon != null && chroma.displayIcon!.isNotEmpty) {
        return chroma.displayIcon!;
      }
    }
    if (widget.offer.levels.isNotEmpty && _selectedLevelIndex < widget.offer.levels.length) {
      final level = widget.offer.levels[_selectedLevelIndex];
      if (level.displayIcon != null && level.displayIcon!.isNotEmpty) {
        return level.displayIcon!;
      }
    }
    return widget.offer.imageUrl;
  }

  String _formatLevelName(SkinLevel level, int index) {
    final item = level.levelItem;
    if (item != null && item.isNotEmpty) {
      final clean = item.replaceAll('EEquippableSkinLevelItem::', '');
      switch (clean) {
        case 'VFX':
          return 'Sv. ${index + 1} (Efekt)';
        case 'Animation':
        case 'Animations':
          return 'Sv. ${index + 1} (Animasyon)';
        case 'Finisher':
          return 'Sv. ${index + 1} (Bitiriş)';
        case 'KillEffect':
        case 'KillBanner':
          return 'Sv. ${index + 1} (Sancak)';
        default:
          return 'Sv. ${index + 1} ($clean)';
      }
    }
    return 'Seviye ${index + 1}';
  }

  @override
  Widget build(BuildContext context) {
    final offer = widget.offer;
    final videoUrl = _currentVideoUrl;
    final tierColor = _parseTierColor(offer.tierColorHex);

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
          // Tutamaç
          const SizedBox(height: 12),
          Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.surfaceBright,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 12),

          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Başlık & Fiyat Alanı
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              offer.name,
                              style: const TextStyle(
                                color: AppColors.ivory,
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: tierColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  offer.tierName,
                                  style: const TextStyle(
                                    color: AppColors.muted,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      // İstek Listesi Butonu
                      Consumer<WishlistProvider>(
                        builder: (context, wishlist, _) {
                          final isWishlisted = wishlist.isWishlisted(offer.itemId);
                          return Material(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(16),
                            child: InkWell(
                              onTap: () async {
                                final added = await wishlist.toggleWishlist(offer.itemId);
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    behavior: SnackBarBehavior.floating,
                                    duration: const Duration(seconds: 2),
                                    content: Text(
                                      added
                                          ? '${offer.name} istek listesine eklendi! ✨'
                                          : '${offer.name} istek listesinden çıkarıldı.',
                                    ),
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isWishlisted
                                        ? AppColors.accent
                                        : AppColors.surfaceBright,
                                  ),
                                ),
                                child: Icon(
                                  isWishlisted
                                      ? Icons.favorite_rounded
                                      : Icons.favorite_border_rounded,
                                  color: isWishlisted ? AppColors.accent : AppColors.muted,
                                  size: 22,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                      // Fiyat Kutusu
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.surfaceBright),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.diamond_outlined,
                              color: AppColors.gold,
                              size: 20,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              NumberFormat.decimalPattern('tr_TR').format(offer.price),
                              style: const TextStyle(
                                color: AppColors.ivory,
                                fontWeight: FontWeight.w900,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              'VP',
                              style: TextStyle(
                                color: AppColors.muted,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Medya Alanı: Video Oynatıcı veya Görsel
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      height: 230,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        border: Border.all(
                          color: tierColor.withValues(alpha: 0.35),
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: videoUrl != null
                          ? SkinVideoPlayer(
                              key: ValueKey(videoUrl),
                              videoUrl: videoUrl,
                            )
                          : Container(
                              padding: const EdgeInsets.all(20),
                              alignment: Alignment.center,
                              child: CachedNetworkImage(
                                imageUrl: _currentImageUrl,
                                fit: BoxFit.contain,
                                placeholder: (context, url) => const Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.accent,
                                  ),
                                ),
                                errorWidget: (context, url, error) => const Icon(
                                  Icons.broken_image_outlined,
                                  color: AppColors.muted,
                                  size: 48,
                                ),
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 22),

                  // Seviyeler Başlığı & Seçici
                  if (offer.levels.length > 1) ...[
                    Row(
                      children: [
                        const Icon(
                          Icons.upgrade_rounded,
                          color: AppColors.accent,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'SEVİYELER & ANİMASYONLAR',
                          style: TextStyle(
                            color: AppColors.muted,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: List.generate(offer.levels.length, (index) {
                        final lvl = offer.levels[index];
                        final isSelected = !_isShowingChroma && _selectedLevelIndex == index;
                        final hasVideo = lvl.streamedVideo != null && lvl.streamedVideo!.isNotEmpty;

                        return ChoiceChip(
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _isShowingChroma = false;
                                _selectedLevelIndex = index;
                              });
                            }
                          },
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (hasVideo) ...[
                                const Icon(
                                  Icons.play_circle_fill_rounded,
                                  size: 14,
                                  color: AppColors.accent,
                                ),
                                const SizedBox(width: 5),
                              ],
                              Text(_formatLevelName(lvl, index)),
                            ],
                          ),
                          selectedColor: AppColors.accent.withValues(alpha: 0.25),
                          backgroundColor: AppColors.surface,
                          side: BorderSide(
                            color: isSelected ? AppColors.accent : AppColors.surfaceBright,
                          ),
                          labelStyle: TextStyle(
                            color: isSelected ? AppColors.ivory : AppColors.muted,
                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                            fontSize: 12,
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Renk Varyantları (Chromas)
                  if (offer.chromas.length > 1) ...[
                    Row(
                      children: [
                        const Icon(
                          Icons.palette_outlined,
                          color: AppColors.gold,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'RENK VARYANTLARI',
                          style: TextStyle(
                            color: AppColors.muted,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: List.generate(offer.chromas.length, (index) {
                        final chroma = offer.chromas[index];
                        final isSelected = _isShowingChroma && _selectedChromaIndex == index;
                        final swatchUrl = chroma.swatch;

                        return InkWell(
                          onTap: () {
                            setState(() {
                              _isShowingChroma = true;
                              _selectedChromaIndex = index;
                            });
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected ? AppColors.gold : AppColors.surfaceBright,
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (swatchUrl != null && swatchUrl.isNotEmpty)
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: CachedNetworkImage(
                                      imageUrl: swatchUrl,
                                      width: 28,
                                      height: 28,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                else
                                  Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceBright,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.color_lens_rounded,
                                      size: 16,
                                      color: AppColors.muted,
                                    ),
                                  ),
                                const SizedBox(width: 8),
                                Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: Text(
                                    chroma.displayName.split('\n').first,
                                    style: TextStyle(
                                      color: isSelected ? AppColors.ivory : AppColors.muted,
                                      fontSize: 12,
                                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Kapat Butonu
                  FilledButton(
                    onPressed: () => Navigator.pop(context),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.surfaceBright,
                      foregroundColor: AppColors.ivory,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Kapat',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Color _parseTierColor(String? value) {
    var hex = value?.replaceAll('#', '') ?? '';
    if (hex.length == 8) {
      hex = '${hex.substring(6)}${hex.substring(0, 6)}';
    } else if (hex.length == 6) {
      hex = 'FF$hex';
    } else {
      return AppColors.accent;
    }
    return Color(int.tryParse(hex, radix: 16) ?? AppColors.accent.toARGB32());
  }
}

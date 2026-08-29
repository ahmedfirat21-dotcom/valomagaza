import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/app_theme.dart';
import '../models/skin_offer.dart';
import '../providers/wishlist_provider.dart';
import 'skin_detail_sheet.dart';

class SkinCard extends StatelessWidget {
  const SkinCard({required this.offer, super.key});

  final SkinOffer offer;

  @override
  Widget build(BuildContext context) {
    final tierColor = _parseTierColor(offer.tierColorHex);
    final hasVideo = offer.levels.any((l) => l.streamedVideo != null && l.streamedVideo!.isNotEmpty);
    final isWishlisted = context.select<WishlistProvider, bool>(
      (w) => w.isWishlisted(offer.itemId),
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => SkinDetailSheet.show(context, offer),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: tierColor.withValues(alpha: 0.42)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Container(
                        color: AppColors.surfaceBright.withValues(alpha: 0.55),
                        padding: const EdgeInsets.all(12),
                        child: offer.imageUrl.isEmpty
                            ? const Icon(
                                Icons.image_not_supported_outlined,
                                color: AppColors.muted,
                                size: 42,
                              )
                            : CachedNetworkImage(
                                imageUrl: offer.imageUrl,
                                fit: BoxFit.contain,
                                placeholder: (context, url) => const Center(
                                  child: SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                ),
                                errorWidget: (context, url, error) => const Icon(
                                  Icons.broken_image_outlined,
                                  color: AppColors.muted,
                                  size: 42,
                                ),
                              ),
                      ),
                    ),
                    if (hasVideo)
                      Positioned(
                        top: 10,
                        left: 10,
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.65),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.play_arrow_rounded,
                            color: AppColors.accent,
                            size: 16,
                          ),
                        ),
                      ),
                    if (offer.isNightMarket)
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.accent,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '%${offer.discountPercent ?? 0} İNDİRİM',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    if (isWishlisted)
                      Positioned(
                        top: 10,
                        right: offer.isNightMarket ? null : 10,
                        left: offer.isNightMarket ? (hasVideo ? 40 : 10) : null,
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.65),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.favorite_rounded,
                            color: AppColors.accent,
                            size: 16,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 13, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  offer.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.ivory,
                    fontSize: 14,
                    height: 1.2,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 7),
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: tierColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        offer.tierName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 11),
                Row(
                  children: [
                    const Icon(
                      Icons.diamond_outlined,
                      color: AppColors.gold,
                      size: 18,
                    ),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        NumberFormat.decimalPattern(
                          'tr_TR',
                        ).format(offer.price),
                        maxLines: 1,
                        overflow: TextOverflow.fade,
                        softWrap: false,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'VP',
                      style: TextStyle(color: AppColors.muted, fontSize: 11),
                    ),
                    if (offer.originalPrice != null) ...[
                      const SizedBox(width: 7),
                      Flexible(
                        child: Text(
                          NumberFormat.decimalPattern(
                            'tr_TR',
                          ).format(offer.originalPrice),
                          maxLines: 1,
                          overflow: TextOverflow.fade,
                          softWrap: false,
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 11,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ),
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

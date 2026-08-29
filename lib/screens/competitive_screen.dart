import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_theme.dart';
import '../models/competitive_rank.dart';
import '../providers/competitive_provider.dart';
import '../widgets/error_view.dart';

class CompetitiveScreen extends StatefulWidget {
  const CompetitiveScreen({required this.active, super.key});

  final bool active;

  @override
  State<CompetitiveScreen> createState() => _CompetitiveScreenState();
}

class _CompetitiveScreenState extends State<CompetitiveScreen> {
  @override
  void initState() {
    super.initState();
    _loadIfActive();
  }

  @override
  void didUpdateWidget(covariant CompetitiveScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.active && widget.active) _loadIfActive();
  }

  void _loadIfActive() {
    if (!widget.active) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<CompetitiveProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CompetitiveProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Rekabet',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        actions: [
          IconButton(
            tooltip: 'Yenile',
            onPressed: provider.isLoading
                ? null
                : () => provider.load(force: true),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => provider.load(force: true),
        child: _CompetitiveBody(provider: provider),
      ),
    );
  }
}

class _CompetitiveBody extends StatelessWidget {
  const _CompetitiveBody({required this.provider});
  final CompetitiveProvider provider;

  @override
  Widget build(BuildContext context) {
    if (provider.status == CompetitiveStatus.loading &&
        provider.currentRank == null) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Dereceli veriler hazırlanıyor…',
              style: TextStyle(color: AppColors.muted),
            ),
          ],
        ),
      );
    }
    if (provider.status == CompetitiveStatus.error) {
      return ErrorView(
        message: provider.errorMessage ?? 'Rekabet bilgisi alınamadı.',
        onRetry: () => provider.load(force: true),
      );
    }
    final rank = provider.currentRank;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        _RankHero(rank: rank),
        const SizedBox(height: 24),
        const Text(
          'SON DERECELİ GÜNCELLEMELER',
          style: TextStyle(
            color: AppColors.muted,
            fontWeight: FontWeight.w900,
            fontSize: 12,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        if (provider.updates.isEmpty)
          const _EmptyUpdates()
        else
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              children: [
                for (
                  var index = 0;
                  index < provider.updates.length;
                  index++
                ) ...[
                  _UpdateRow(update: provider.updates[index]),
                  if (index != provider.updates.length - 1)
                    const Divider(height: 1, color: AppColors.surfaceBright),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _RankHero extends StatelessWidget {
  const _RankHero({required this.rank});
  final CurrentCompetitiveRank? rank;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [AppColors.surfaceBright, AppColors.surface],
      ),
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: AppColors.gold.withValues(alpha: .35)),
    ),
    child: Row(
      children: [
        _RankIcon(url: rank?.iconUrl, size: 76),
        const SizedBox(width: 18),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'GÜNCEL DERECE',
                style: TextStyle(
                  color: AppColors.muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                rank?.name ?? 'Derece bulunamadı',
                style: const TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                rank?.rrLabel ?? 'Dereceli oyun verisi yok',
                style: const TextStyle(
                  color: AppColors.gold,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _UpdateRow extends StatelessWidget {
  const _UpdateRow({required this.update});
  final CompetitiveUpdate update;

  @override
  Widget build(BuildContext context) {
    final earned = update.rrChange >= 0;
    final color = earned ? const Color(0xFF54D6A5) : AppColors.accent;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          _RankIcon(url: update.tierInfo?.iconUrl, size: 38),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  update.mapName ?? _fallbackMapName(update.mapId),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  '${update.tierName} • ${_formatDate(update.startedAt)}',
                  style: const TextStyle(color: AppColors.muted, fontSize: 11),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                update.rrChangeLabel,
                style: TextStyle(color: color, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 2),
              Text(
                '${update.rrAfter} RR',
                style: const TextStyle(color: AppColors.muted, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RankIcon extends StatelessWidget {
  const _RankIcon({required this.url, required this.size});
  final String? url;
  final double size;
  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: AppColors.surfaceBright,
      borderRadius: BorderRadius.circular(size / 3),
    ),
    child: url == null || url!.isEmpty
        ? Icon(
            Icons.workspace_premium_rounded,
            color: AppColors.gold,
            size: size * .58,
          )
        : CachedNetworkImage(
            imageUrl: url!,
            fit: BoxFit.contain,
            errorWidget: (_, _, _) => Icon(
              Icons.workspace_premium_rounded,
              color: AppColors.gold,
              size: size * .58,
            ),
          ),
  );
}

class _EmptyUpdates extends StatelessWidget {
  const _EmptyUpdates();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(18),
    ),
    child: const Text(
      'Yakın zamanda dereceli güncelleme bulunamadı.',
      style: TextStyle(color: AppColors.muted),
    ),
  );
}

String _fallbackMapName(String mapId) {
  if (mapId.isEmpty) return 'Dereceli maç';
  return mapId.split('/').last.replaceAll('_', ' ');
}

String _formatDate(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}';

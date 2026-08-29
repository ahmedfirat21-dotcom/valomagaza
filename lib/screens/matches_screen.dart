import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_theme.dart';
import '../models/match_summary.dart';
import '../providers/match_provider.dart';
import '../widgets/error_view.dart';

class MatchesScreen extends StatefulWidget {
  const MatchesScreen({required this.active, super.key});

  final bool active;

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen> {
  @override
  void initState() {
    super.initState();
    _loadIfActive();
  }

  @override
  void didUpdateWidget(covariant MatchesScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.active && widget.active) _loadIfActive();
  }

  void _loadIfActive() {
    if (!widget.active) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<MatchProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final matches = context.watch<MatchProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Son Maçlar',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        actions: [
          IconButton(
            tooltip: 'Yenile',
            onPressed: matches.isLoading
                ? null
                : () => matches.load(force: true),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => matches.load(force: true),
        child: _MatchBody(provider: matches),
      ),
    );
  }
}

class _MatchBody extends StatelessWidget {
  const _MatchBody({required this.provider});

  final MatchProvider provider;

  @override
  Widget build(BuildContext context) {
    if (provider.status == MatchStatus.loading && provider.matches.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Son maçlar hazırlanıyor…',
              style: TextStyle(color: AppColors.muted),
            ),
          ],
        ),
      );
    }
    if (provider.status == MatchStatus.error) {
      return ErrorView(
        message: provider.errorMessage ?? 'Maç verisi alınamadı.',
        onRetry: () => provider.load(force: true),
      );
    }
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        if (provider.matches.isNotEmpty)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            sliver: SliverToBoxAdapter(
              child: _PerformanceSummaryCard(matches: provider.matches),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            sliver: SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.surfaceBright),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.insights_rounded, color: AppColors.blue),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Son maçların kişisel performansını görmek için bir maça dokun.',
                        style: TextStyle(color: AppColors.muted, height: 1.35),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        if (provider.matches.isEmpty)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Text(
                'Gösterilecek son maç bulunamadı.',
                style: TextStyle(color: AppColors.muted),
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            sliver: SliverList.separated(
              itemCount: provider.matches.length,
              itemBuilder: (_, index) => _MatchCard(
                match: provider.matches[index],
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        MatchDetailScreen(match: provider.matches[index]),
                  ),
                ),
              ),
              separatorBuilder: (_, _) => const SizedBox(height: 10),
            ),
          ),
      ],
    );
  }
}

class _MatchCard extends StatelessWidget {
  const _MatchCard({required this.match, required this.onTap});

  final MatchSummary match;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final outcomeColor = _outcomeColor(match.outcome);
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: outcomeColor.withValues(alpha: 0.5)),
          ),
          child: Row(
            children: [
              _AgentAvatar(imageUrl: match.agentImageUrl, size: 54),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            match.mapName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        Text(
                          _outcomeLabel(match.outcome),
                          style: TextStyle(
                            color: outcomeColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${match.modeName} • ${match.agentName} • ${_formatDate(match.startedAt)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 9),
                    Row(
                      children: [
                        Text(
                          match.kda,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '${match.acs} ACS',
                          style: const TextStyle(color: AppColors.muted),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                children: [
                  Text(
                    '${match.teamScore}–${match.opponentScore}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.muted,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MatchDetailScreen extends StatelessWidget {
  const MatchDetailScreen({required this.match, super.key});

  final MatchSummary match;

  @override
  Widget build(BuildContext context) {
    final ownPlayer = match.players.cast<MatchPlayer?>().firstWhere(
      (player) => player?.isCurrentPlayer == true,
      orElse: () => match.players.isNotEmpty ? match.players.first : null,
    );
    final ownTeam = ownPlayer?.teamId ?? '';
    final allies = match.players
        .where((player) => player.teamId == ownTeam)
        .toList();
    final opponents = match.players
        .where((player) => player.teamId != ownTeam)
        .toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Maç Ayrıntısı')),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverToBoxAdapter(
              child: Column(
                children: [
                  _MatchHero(match: match),
                  const SizedBox(height: 14),
                  _PersonalStats(match: match),
                  const SizedBox(height: 22),
                  _TeamTable(title: 'Takımın', players: allies),
                  const SizedBox(height: 18),
                  _TeamTable(title: 'Rakip Takım', players: opponents),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MatchHero extends StatelessWidget {
  const _MatchHero({required this.match});

  final MatchSummary match;

  @override
  Widget build(BuildContext context) {
    final color = _outcomeColor(match.outcome);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.55)),
      ),
      child: Column(
        children: [
          Text(
            _outcomeLabel(match.outcome),
            style: TextStyle(color: color, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 7),
          Text(
            '${match.teamScore} – ${match.opponentScore}',
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 38),
          ),
          const SizedBox(height: 10),
          Text(
            '${match.mapName} • ${match.modeName} • ${_formatDuration(match.duration)}',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 4),
          Text(
            _formatDate(match.startedAt),
            style: const TextStyle(color: AppColors.muted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _PersonalStats extends StatelessWidget {
  const _PersonalStats({required this.match});

  final MatchSummary match;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _StatTile(label: 'K / D / A', value: match.kda),
        _StatTile(label: 'ACS', value: '${match.acs}'),
        _StatTile(label: 'Kafa Vuruşu', value: '%${match.headshotPercent}'),
        _StatTile(label: 'Ajan', value: match.agentName),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final width = (MediaQuery.sizeOf(context).width - 42) / 2;
    return Container(
      width: width,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: AppColors.muted, fontSize: 11),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _TeamTable extends StatelessWidget {
  const _TeamTable({required this.title, required this.players});

  final String title;
  final List<MatchPlayer> players;

  @override
  Widget build(BuildContext context) {
    final sorted = [...players]..sort((a, b) => b.acs.compareTo(a.acs));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              for (var index = 0; index < sorted.length; index++) ...[
                _PlayerRow(player: sorted[index]),
                if (index < sorted.length - 1)
                  const Divider(height: 1, color: AppColors.surfaceBright),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _PlayerRow extends StatelessWidget {
  const _PlayerRow({required this.player});

  final MatchPlayer player;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: player.isCurrentPlayer
          ? AppColors.accent.withValues(alpha: 0.10)
          : Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          _AgentAvatar(imageUrl: player.agentImageUrl, size: 36),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              player.displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: player.isCurrentPlayer
                    ? FontWeight.w900
                    : FontWeight.w600,
              ),
            ),
          ),
          Text('${player.kills}/${player.deaths}/${player.assists}'),
          const SizedBox(width: 12),
          SizedBox(
            width: 42,
            child: Text(
              '${player.acs}',
              textAlign: TextAlign.end,
              style: const TextStyle(color: AppColors.muted),
            ),
          ),
        ],
      ),
    );
  }
}

class _AgentAvatar extends StatelessWidget {
  const _AgentAvatar({required this.imageUrl, required this.size});

  final String imageUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: Container(
        width: size,
        height: size,
        color: AppColors.surfaceBright,
        child: imageUrl.isEmpty
            ? Icon(Icons.person_outline_rounded, size: size * 0.55)
            : CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                errorWidget: (_, _, _) =>
                    Icon(Icons.person_outline_rounded, size: size * 0.55),
              ),
      ),
    );
  }
}

Color _outcomeColor(MatchOutcome outcome) {
  switch (outcome) {
    case MatchOutcome.win:
      return const Color(0xFF54D6A5);
    case MatchOutcome.loss:
      return AppColors.accent;
    case MatchOutcome.draw:
    case MatchOutcome.completed:
      return AppColors.gold;
  }
}

String _outcomeLabel(MatchOutcome outcome) {
  switch (outcome) {
    case MatchOutcome.win:
      return 'GALİBİYET';
    case MatchOutcome.loss:
      return 'MAĞLUBİYET';
    case MatchOutcome.draw:
      return 'BERABERE';
    case MatchOutcome.completed:
      return 'TAMAMLANDI';
  }
}

String _formatDate(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year} '
    '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

String _formatDuration(Duration duration) {
  final minutes = duration.inMinutes;
  final seconds = duration.inSeconds % 60;
  return '$minutes:${seconds.toString().padLeft(2, '0')}';
}

class _PerformanceSummaryCard extends StatelessWidget {
  const _PerformanceSummaryCard({required this.matches});

  final List<MatchSummary> matches;

  @override
  Widget build(BuildContext context) {
    var wins = 0;
    var losses = 0;
    var totalKills = 0;
    var totalDeaths = 0;
    var totalAcs = 0;
    final agentCounts = <String, int>{};
    final agentImages = <String, String>{};

    for (final m in matches) {
      if (m.outcome == MatchOutcome.win) wins++;
      if (m.outcome == MatchOutcome.loss) losses++;
      totalKills += m.kills;
      totalDeaths += m.deaths;
      totalAcs += m.acs;

      if (m.agentName.isNotEmpty) {
        agentCounts[m.agentName] = (agentCounts[m.agentName] ?? 0) + 1;
        agentImages[m.agentName] = m.agentImageUrl;
      }
    }

    final totalDecided = wins + losses;
    final winRate = totalDecided == 0 ? 0 : ((wins / totalDecided) * 100).round();
    final kd = totalDeaths == 0 ? totalKills.toDouble() : totalKills / totalDeaths;
    final avgAcs = matches.isEmpty ? 0 : (totalAcs / matches.length).round();

    String topAgent = 'Yok';
    String topAgentImg = '';
    var maxCount = 0;
    for (final entry in agentCounts.entries) {
      if (entry.value > maxCount) {
        maxCount = entry.value;
        topAgent = entry.key;
        topAgentImg = agentImages[entry.key] ?? '';
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.blue.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.analytics_rounded, color: AppColors.blue, size: 20),
              const SizedBox(width: 8),
              const Text(
                'SON MAÇLAR ANALİTİĞİ',
                style: TextStyle(
                  color: AppColors.muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.1,
                ),
              ),
              const Spacer(),
              Text(
                '${matches.length} Maç',
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Win Rate
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Win Rate', style: TextStyle(color: AppColors.muted, fontSize: 11)),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        '%$winRate',
                        style: TextStyle(
                          color: winRate >= 50 ? const Color(0xFF54D6A5) : AppColors.accent,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '($wins G / $losses M)',
                        style: const TextStyle(color: AppColors.muted, fontSize: 10),
                      ),
                    ],
                  ),
                ],
              ),
              Container(width: 1, height: 32, color: AppColors.surfaceBright),
              // K/D
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('K/D Oranı', style: TextStyle(color: AppColors.muted, fontSize: 11)),
                  const SizedBox(height: 2),
                  Text(
                    kd.toStringAsFixed(2),
                    style: TextStyle(
                      color: kd >= 1.0 ? AppColors.ivory : AppColors.accent,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              Container(width: 1, height: 32, color: AppColors.surfaceBright),
              // ACS
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Ort. ACS', style: TextStyle(color: AppColors.muted, fontSize: 11)),
                  const SizedBox(height: 2),
                  Text(
                    '$avgAcs',
                    style: const TextStyle(
                      color: AppColors.gold,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              Container(width: 1, height: 32, color: AppColors.surfaceBright),
              // Top Agent
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('Favori Ajan', style: TextStyle(color: AppColors.muted, fontSize: 11)),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (topAgentImg.isNotEmpty) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: CachedNetworkImage(
                            imageUrl: topAgentImg,
                            width: 18,
                            height: 18,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 5),
                      ],
                      Text(
                        topAgent,
                        style: const TextStyle(
                          color: AppColors.ivory,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

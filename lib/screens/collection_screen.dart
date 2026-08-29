import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_theme.dart';
import '../models/collection_item.dart';
import '../models/skin_offer.dart';
import '../providers/collection_provider.dart';
import '../services/valorant_assets_service.dart';
import '../widgets/error_view.dart';
import '../providers/wishlist_provider.dart';
import '../widgets/skin_detail_sheet.dart';
import '../widgets/skin_search_sheet.dart';
import '../widgets/wishlist_sheet.dart';

enum _CollectionTab { owned, catalog }

enum _CollectionFilter { all, weapons, melee }

class CollectionScreen extends StatefulWidget {
  const CollectionScreen({required this.active, super.key});

  final bool active;

  @override
  State<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends State<CollectionScreen> {
  var _tab = _CollectionTab.owned;
  var _filter = _CollectionFilter.all;
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadIfActive();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant CollectionScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.active && widget.active) _loadIfActive();
  }

  void _loadIfActive() {
    if (!widget.active) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<CollectionProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CollectionProvider>();
    final wishlist = context.watch<WishlistProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Koleksiyon',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        actions: [
          IconButton(
            tooltip: 'Katalogda Skin Ara',
            onPressed: () => SkinSearchSheet.show(context),
            icon: const Icon(Icons.search_rounded),
          ),
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
        child: _CollectionBody(
          provider: provider,
          tab: _tab,
          filter: _filter,
          searchQuery: _searchQuery,
          searchController: _searchController,
          onSearchChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
          onTabChanged: (value) => setState(() => _tab = value),
          onFilterChanged: (value) => setState(() => _filter = value),
        ),
      ),
    );
  }
}

class _CollectionBody extends StatelessWidget {
  const _CollectionBody({
    required this.provider,
    required this.tab,
    required this.filter,
    required this.searchQuery,
    required this.searchController,
    required this.onSearchChanged,
    required this.onTabChanged,
    required this.onFilterChanged,
  });

  final CollectionProvider provider;
  final _CollectionTab tab;
  final _CollectionFilter filter;
  final String searchQuery;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<_CollectionTab> onTabChanged;
  final ValueChanged<_CollectionFilter> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    if (provider.status == CollectionStatus.loading &&
        provider.catalogItems.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Koleksiyon hazırlanıyor…',
              style: TextStyle(color: AppColors.muted),
            ),
          ],
        ),
      );
    }
    if (provider.status == CollectionStatus.error &&
        provider.catalogItems.isEmpty) {
      return ErrorView(
        message: provider.errorMessage ?? 'Koleksiyon verisi alınamadı.',
        onRetry: () => provider.load(force: true),
      );
    }
    final source = tab == _CollectionTab.owned
        ? provider.ownedItems
        : provider.catalogItems;
    final items = source
        .where((item) {
          if (searchQuery.isNotEmpty) {
            final queryMatch = item.name.toLowerCase().contains(searchQuery) ||
                item.weaponName.toLowerCase().contains(searchQuery);
            if (!queryMatch) return false;
          }
          switch (filter) {
            case _CollectionFilter.all:
              return true;
            case _CollectionFilter.weapons:
              return !item.isMelee;
            case _CollectionFilter.melee:
              return item.isMelee;
          }
        })
        .toList(growable: false);
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          sliver: SliverToBoxAdapter(
            child: _CollectionHeader(
              ownedCount: provider.ownedItems.length,
              catalogCount: provider.catalogItems.length,
              tab: tab,
              onTabChanged: onTabChanged,
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          sliver: SliverToBoxAdapter(
            child: TextField(
              controller: searchController,
              onChanged: onSearchChanged,
              style: const TextStyle(color: AppColors.ivory, fontSize: 13),
              decoration: InputDecoration(
                hintText: tab == _CollectionTab.owned
                    ? 'Sahip olunan skinlerde ara…'
                    : 'Katalogda ara…',
                hintStyle: const TextStyle(color: AppColors.muted, fontSize: 13),
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.muted, size: 18),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, color: AppColors.muted, size: 16),
                        onPressed: () {
                          searchController.clear();
                          onSearchChanged('');
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
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          sliver: SliverToBoxAdapter(
            child: Wrap(
              spacing: 8,
              children: [
                _FilterChip(
                  label: 'Tümü',
                  selected: filter == _CollectionFilter.all,
                  onTap: () => onFilterChanged(_CollectionFilter.all),
                ),
                _FilterChip(
                  label: 'Silahlar',
                  selected: filter == _CollectionFilter.weapons,
                  onTap: () => onFilterChanged(_CollectionFilter.weapons),
                ),
                _FilterChip(
                  label: 'Bıçaklar',
                  selected: filter == _CollectionFilter.melee,
                  onTap: () => onFilterChanged(_CollectionFilter.melee),
                ),
              ],
            ),
          ),
        ),
        if (provider.status == CollectionStatus.error)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            sliver: SliverToBoxAdapter(
              child: _InlineError(message: provider.errorMessage),
            ),
          ),
        if (items.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Text(
                tab == _CollectionTab.owned
                    ? 'Bu filtrede sahip olduğun kaplama yok.'
                    : 'Gösterilecek kaplama bulunamadı.',
                style: const TextStyle(color: AppColors.muted),
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            sliver: SliverGrid(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _CollectionCard(item: items[index]),
                childCount: items.length,
              ),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: MediaQuery.sizeOf(context).width >= 700 ? 3 : 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 0.79,
              ),
            ),
          ),
      ],
    );
  }
}

class _CollectionHeader extends StatelessWidget {
  const _CollectionHeader({
    required this.ownedCount,
    required this.catalogCount,
    required this.tab,
    required this.onTabChanged,
  });

  final int ownedCount;
  final int catalogCount;
  final _CollectionTab tab;
  final ValueChanged<_CollectionTab> onTabChanged;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: AppColors.surfaceBright),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'SKIN ARŞİVİ',
          style: TextStyle(
            color: AppColors.muted,
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '$ownedCount sahip olunan • $catalogCount katalogda',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 14),
        SegmentedButton<_CollectionTab>(
          segments: const [
            ButtonSegment(
              value: _CollectionTab.owned,
              icon: Icon(Icons.inventory_2_outlined),
              label: Text('Benim skinlerim'),
            ),
            ButtonSegment(
              value: _CollectionTab.catalog,
              icon: Icon(Icons.grid_view_rounded),
              label: Text('Tüm skinler'),
            ),
          ],
          selected: {tab},
          onSelectionChanged: (value) => onTabChanged(value.first),
        ),
      ],
    ),
  );
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ChoiceChip(
    label: Text(label),
    selected: selected,
    onSelected: (_) => onTap(),
  );
}

class _CollectionCard extends StatelessWidget {
  const _CollectionCard({required this.item});

  final CollectionItem item;

  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(16),
    child: InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => SkinPreviewScreen(item: item))),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: item.isEquipped
                ? AppColors.gold.withValues(alpha: 0.7)
                : AppColors.surfaceBright,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(child: _SkinImage(imageUrl: item.imageUrl)),
                  if (item.isEquipped)
                    const Positioned(right: 0, top: 0, child: _EquippedBadge()),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              item.weaponName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.muted, fontSize: 11),
            ),
            const SizedBox(height: 2),
            Text(
              item.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w800, height: 1.1),
            ),
          ],
        ),
      ),
    ),
  );
}

class _SkinImage extends StatelessWidget {
  const _SkinImage({required this.imageUrl});
  final String imageUrl;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: AppColors.surfaceBright,
      borderRadius: BorderRadius.circular(12),
    ),
    child: imageUrl.isEmpty
        ? const Center(
            child: Icon(
              Icons.image_not_supported_outlined,
              color: AppColors.muted,
            ),
          )
        : CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.contain,
            placeholder: (_, _) =>
                const Center(child: CircularProgressIndicator(strokeWidth: 2)),
            errorWidget: (_, _, _) => const Center(
              child: Icon(Icons.broken_image_outlined, color: AppColors.muted),
            ),
          ),
  );
}

class _EquippedBadge extends StatelessWidget {
  const _EquippedBadge();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
    decoration: BoxDecoration(
      color: AppColors.gold,
      borderRadius: BorderRadius.circular(99),
    ),
    child: const Text(
      'TAKILI',
      style: TextStyle(
        color: Colors.black,
        fontSize: 9,
        fontWeight: FontWeight.w900,
      ),
    ),
  );
}

class _InlineError extends StatelessWidget {
  const _InlineError({this.message});
  final String? message;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppColors.accent.withValues(alpha: .12),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Text(
      message ?? 'Sahip olunan skinler okunamadı.',
      style: const TextStyle(color: AppColors.ivory),
    ),
  );
}

class SkinPreviewScreen extends StatelessWidget {
  const SkinPreviewScreen({required this.item, super.key});

  final CollectionItem item;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Skin Önizleme')),
    body: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: _SkinImage(imageUrl: item.imageUrl)),
          const SizedBox(height: 22),
          Text(item.weaponName, style: const TextStyle(color: AppColors.muted)),
          const SizedBox(height: 4),
          Text(
            item.name,
            style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(
            item.tierName,
            style: TextStyle(color: _tierColor(item.tierColorHex)),
          ),
          if (item.isEquipped) ...[
            const SizedBox(height: 14),
            const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: AppColors.gold),
                SizedBox(width: 8),
                Text('Aktif loadout içinde takılı'),
              ],
            ),
          ],
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: () async {
              final catalog = await context.read<ValorantAssetsService>().getSkinCatalog();
              final entry = catalog[item.itemId.toLowerCase()];
              if (!context.mounted) return;
              final offer = SkinOffer(
                itemId: item.itemId,
                name: item.name,
                imageUrl: item.imageUrl,
                price: 0,
                tierName: item.tierName,
                tierColorHex: item.tierColorHex,
                levels: entry?.levels ?? const [],
                chromas: entry?.chromas ?? const [],
              );
              SkinDetailSheet.show(context, offer);
            },
            icon: const Icon(Icons.play_circle_outline_rounded),
            label: const Text('Videoları ve Seviyeleri İncele'),
          ),
          const SizedBox(height: 14),
          const Text(
            'Bu ekran yalnızca görüntüleme içindir; skin takma veya satın alma işlemi yapmaz.',
            style: TextStyle(color: AppColors.muted, height: 1.35),
          ),
        ],
      ),
    ),
  );
}

Color _tierColor(String? hex) {
  if (hex == null || hex.length < 6) return AppColors.muted;
  final normalized = hex.replaceFirst('#', '');
  final value = int.tryParse(normalized.substring(0, 6), radix: 16);
  return value == null ? AppColors.muted : Color(0xFF000000 | value);
}

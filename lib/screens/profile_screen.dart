import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/app_theme.dart';
import '../core/constants.dart';
import '../providers/auth_provider.dart';
import '../providers/collection_provider.dart';
import '../providers/competitive_provider.dart';
import '../providers/match_provider.dart';
import '../providers/store_provider.dart';
import '../providers/wishlist_provider.dart';
import '../services/notification_service.dart';
import '../services/store_history_service.dart';
import '../widgets/skin_search_sheet.dart';
import '../widgets/store_history_sheet.dart';
import 'account_management_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    final approved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Çıkış yapılsın mı?'),
        content: const Text(
          'Bu cihazdaki oturum tokenları silinir. Mağaza ve maç verileri tekrar giriş yapılana kadar gösterilmez.',
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
    if (approved != true || !context.mounted) return;
    context.read<StoreProvider>().reset();
    context.read<MatchProvider>().reset();
    context.read<CollectionProvider>().reset();
    context.read<CompetitiveProvider>().reset();
    await context.read<AuthProvider>().logout();
  }

  Future<void> _openPrivacyPolicy(BuildContext context) async {
    final opened = await launchUrl(
      Uri.parse(AppConstants.privacyPolicyUrl),
      mode: LaunchMode.externalApplication,
    );
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gizlilik politikası açılamadı.')),
      );
    }
  }

  Future<void> _clearAllLocalData(BuildContext context) async {
    final approved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Tüm yerel veriler silinsin mi?'),
        content: const Text(
          'Kayıtlı Riot oturumları, mağaza geçmişi, istek listesi ve bildirim ayarları bu telefondan kalıcı olarak silinecek.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Tümünü Sil'),
          ),
        ],
      ),
    );
    if (approved != true || !context.mounted) return;

    context.read<StoreProvider>().reset();
    context.read<MatchProvider>().reset();
    context.read<CollectionProvider>().reset();
    context.read<CompetitiveProvider>().reset();
    await context.read<StoreHistoryService>().clearAllHistory();
    if (!context.mounted) return;
    await context.read<WishlistProvider>().clear();
    if (!context.mounted) return;
    await context.read<NotificationService>().clearLocalSettings();
    if (!context.mounted) return;
    await context.read<AuthProvider>().logout();
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<AuthProvider>().session;
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Hesap & Güvenlik',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.surfaceBright),
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: const BoxDecoration(
                    color: AppColors.accent,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.shield_rounded, color: Colors.white),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Riot hesabın bağlı',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 17,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Bölge: ${session?.region.toUpperCase() ?? '—'} • Shard: ${session?.shard.toUpperCase() ?? '—'}',
                        style: const TextStyle(color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'HESAPLAR',
            style: TextStyle(
              color: AppColors.muted,
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          _InfoTile(
            icon: Icons.manage_accounts_outlined,
            title: 'Hesapları yönet',
            detail:
                'Bu cihazdaki Riot oturumlarını güvenli depoda tut, hesap ekle veya etkin hesabı değiştir.',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const AccountManagementScreen(),
              ),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'BİLDİRİMLER & ÖZELLİKLER',
            style: TextStyle(
              color: AppColors.muted,
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          FutureBuilder<bool>(
            future: context.read<NotificationService>().isNotificationsEnabled(),
            builder: (context, snapshot) {
              final isEnabled = snapshot.data ?? true;
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.surfaceBright),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.notifications_active_outlined, color: AppColors.accent),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'İstek Listesi Bildirimleri',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Uygulamayı açtığında veya mağazayı yenilediğinde eşleşme varsa günde bir kez bildir.',
                            style: TextStyle(color: AppColors.muted, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: isEnabled,
                      activeThumbColor: Colors.white,
                      activeTrackColor: AppColors.accent,
                      onChanged: (val) async {
                        final notifService = context.read<NotificationService>();
                        var enabled = val;
                        if (val) {
                          enabled = await notifService.requestPermissions();
                        }
                        await notifService.setNotificationsEnabled(enabled);
                        if (context.mounted) {
                          (context as Element).markNeedsBuild();
                          if (val && !enabled) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Bildirim izni verilmediği için özellik açılmadı.',
                                ),
                              ),
                            );
                          }
                        }
                      },
                    ),
                  ],
                ),
              );
            },
          ),
          _InfoTile(
            icon: Icons.history_rounded,
            title: 'Mağaza Geçmişi',
            detail: 'Önceki günlerde mağazana gelen teklifleri incele.',
            onTap: () => StoreHistorySheet.show(context),
          ),
          _InfoTile(
            icon: Icons.search_rounded,
            title: 'Katalogda Skin Ara',
            detail: 'Tüm VALORANT kaplamalarını ara ve istek listene ekle.',
            onTap: () => SkinSearchSheet.show(context),
          ),
          const SizedBox(height: 18),
          const Text(
            'GÜVENLİK',
            style: TextStyle(
              color: AppColors.muted,
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          const _InfoTile(
            icon: Icons.key_outlined,
            title: 'Tokenlar cihazda korunur',
            detail:
                'Oturum verileri Android Keystore korumalı alanda saklanır; uygulama dışına gönderilmez.',
          ),
          const _InfoTile(
            icon: Icons.visibility_off_outlined,
            title: 'Yalnızca kişisel verilerin',
            detail:
                'Mağaza ve maçların yalnızca bu cihazdaki bağlı hesap için görüntülenir.',
          ),
          const SizedBox(height: 18),
          const Text(
            'YASAL BİLGİ',
            style: TextStyle(
              color: AppColors.muted,
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          _InfoTile(
            icon: Icons.privacy_tip_outlined,
            title: 'Gizlilik Politikası',
            detail:
                'İşlenen verileri, cihazda saklama şeklini ve silme seçeneklerini incele.',
            onTap: () => _openPrivacyPolicy(context),
          ),
          Text(AppConstants.legalNotice, style: const TextStyle(height: 1.45)),
          const SizedBox(height: 28),
          OutlinedButton.icon(
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Bu Cihazdan Çıkış Yap'),
          ),
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: () => _clearAllLocalData(context),
            icon: const Icon(Icons.delete_forever_outlined),
            label: const Text('Tüm Yerel Verileri Sil'),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.title,
    required this.detail,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String detail;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: AppColors.blue),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      detail,
                      style: const TextStyle(
                        color: AppColors.muted,
                        height: 1.35,
                      ),
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
}

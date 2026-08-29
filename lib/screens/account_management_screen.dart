import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_theme.dart';
import '../core/secure_clipboard.dart';
import '../models/auth_session.dart';
import '../providers/auth_provider.dart';
import '../providers/collection_provider.dart';
import '../providers/competitive_provider.dart';
import '../providers/match_provider.dart';
import '../providers/store_provider.dart';

class AccountManagementScreen extends StatelessWidget {
  const AccountManagementScreen({super.key});

  void _resetAccountData(BuildContext context) {
    context.read<StoreProvider>().reset();
    context.read<MatchProvider>().reset();
    context.read<CollectionProvider>().reset();
    context.read<CompetitiveProvider>().reset();
  }

  Future<void> _importFromClipboard(BuildContext context) async {
    final text = await SecureClipboard.readAndClearText();
    if (!context.mounted) return;
    await context.read<AuthProvider>().authenticateFromRedirect(text);
    if (!context.mounted) return;
    final auth = context.read<AuthProvider>();
    if (auth.errorMessage == null) {
      _resetAccountData(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Hesap güvenli cihaz deposuna eklendi ve etkinleştirildi.',
          ),
        ),
      );
    }
  }

  Future<void> _select(BuildContext context, SavedAccount account) async {
    final selected = await context.read<AuthProvider>().selectAccount(
      account.puuid,
    );
    if (!context.mounted || !selected) return;
    _resetAccountData(context);
    Navigator.pop(context);
  }

  Future<void> _remove(BuildContext context, SavedAccount account) async {
    final approved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hesap kaldırılsın mı?'),
        content: Text(
          '${account.label} için bu cihazda saklanan oturum silinir.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Kaldır'),
          ),
        ],
      ),
    );
    if (approved == true && context.mounted) {
      await context.read<AuthProvider>().removeAccount(account.puuid);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final activePuuid = auth.session?.puuid.toLowerCase();
    return Scaffold(
      appBar: AppBar(title: const Text('Hesapları Yönet')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Her oturum Android Keystore korumalı ayrı bir kayıtta tutulur. Parola tutulmaz; bir hesabı kaldırmak yalnızca bu cihazdaki oturumunu siler.',
            style: TextStyle(color: AppColors.muted, height: 1.4),
          ),
          const SizedBox(height: 18),
          for (final account in auth.accounts) ...[
            _AccountTile(
              account: account,
              active: account.puuid.toLowerCase() == activePuuid,
              onTap: auth.isBusy ? null : () => _select(context, account),
              onRemove: account.puuid.toLowerCase() == activePuuid
                  ? null
                  : () => _remove(context, account),
            ),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: auth.isBusy ? null : auth.openRiotLogin,
            icon: const Icon(Icons.person_add_alt_1_rounded),
            label: const Text('Başka Riot Hesabı Ekle'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: auth.isBusy ? null : () => _importFromClipboard(context),
            icon: auth.isBusy
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.content_paste_go_rounded),
            label: Text(
              auth.isBusy ? 'Hesap ekleniyor…' : 'Panodaki Yeni Hesabı Ekle',
            ),
          ),
          if (auth.errorMessage != null) ...[
            const SizedBox(height: 14),
            Text(
              auth.errorMessage!,
              style: const TextStyle(color: AppColors.accent),
            ),
          ],
        ],
      ),
    );
  }
}

class _AccountTile extends StatelessWidget {
  const _AccountTile({
    required this.account,
    required this.active,
    this.onTap,
    this.onRemove,
  });
  final SavedAccount account;
  final bool active;
  final VoidCallback? onTap;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(16),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: active
                ? AppColors.blue.withValues(alpha: .7)
                : AppColors.surfaceBright,
          ),
        ),
        child: Row(
          children: [
            Icon(
              active
                  ? Icons.verified_user_rounded
                  : Icons.person_outline_rounded,
              color: active ? AppColors.blue : AppColors.muted,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    account.label,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${account.region.toUpperCase()} • ${account.shard.toUpperCase()}',
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (active)
              const Text(
                'ETKİN',
                style: TextStyle(
                  color: AppColors.blue,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              )
            else if (onRemove != null)
              IconButton(
                tooltip: 'Bu hesabı kaldır',
                onPressed: onRemove,
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: AppColors.muted,
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

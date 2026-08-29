import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/app_theme.dart';
import '../core/constants.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  Future<void> _readClipboard(BuildContext context) async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (!context.mounted) return;
    await context.read<AuthProvider>().authenticateFromRedirect(
      data?.text ?? '',
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: Image.asset(
                        'assets/icon/valo_magaza_icon.png',
                        width: 76,
                        height: 76,
                      ),
                    ),
                  ),
                  const SizedBox(height: 26),
                  const Text(
                    AppConstants.appName,
                    style: TextStyle(
                      color: AppColors.ivory,
                      fontSize: 38,
                      height: 1,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Kişisel günlük mağazanı güvenli biçimde telefonundan gör.',
                    style: TextStyle(
                      color: AppColors.muted,
                      fontSize: 17,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 30),
                  _SecurityNote(
                    icon: Icons.shield_outlined,
                    text:
                        'Giriş, telefonunuzdaki gerçek tarayıcıda Riot üzerinden yapılır. Şifreniz bu uygulamaya gönderilmez.',
                  ),
                  const SizedBox(height: 18),
                  FilledButton.icon(
                    onPressed: auth.isBusy ? null : auth.openRiotLogin,
                    icon: const Icon(Icons.open_in_browser_rounded),
                    label: const Text('Riot Hesabımla Giriş Yap'),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.surfaceBright),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Giriş tamamlandığında',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Tarayıcıda Riot girişi tamamlandığında uygulama otomatik olarak öne gelir ve oturumunuz açılır. Otomatik geçiş gerçekleşmezse tarayıcının adres çubuğundaki bağlantıyı kopyalayıp aşağıdaki butona basın.',
                          style: TextStyle(
                            color: AppColors.muted,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  OutlinedButton.icon(
                    onPressed: auth.isBusy
                        ? null
                        : () => _readClipboard(context),
                    icon: auth.isBusy
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.content_paste_go_rounded),
                    label: Text(
                      auth.isBusy
                          ? 'Oturum hazırlanıyor…'
                          : 'Panodan Bağlantıyı Al',
                    ),
                  ),
                  if (auth.accounts.isNotEmpty) ...[
                    const SizedBox(height: 22),
                    const Text(
                      'BU CİHAZDAKİ HESAPLAR',
                      style: TextStyle(
                        color: AppColors.muted,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    for (final account in auth.accounts)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: OutlinedButton.icon(
                          onPressed: auth.isBusy
                              ? null
                              : () => auth.selectAccount(account.puuid),
                          icon: const Icon(Icons.person_outline_rounded),
                          label: Text(
                            '${account.label} • ${account.region.toUpperCase()}',
                          ),
                        ),
                      ),
                  ],
                  if (auth.errorMessage != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.error_outline_rounded,
                            color: AppColors.accent,
                          ),
                          const SizedBox(width: 10),
                          Expanded(child: Text(auth.errorMessage!)),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  const Text(
                    'Tokenlar Android Keystore korumalı alanda yalnızca bu cihazda saklanır. Uygulama satın alma işlemi yapmaz.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Riot Mobile, bu web giriş bağlantısını uygulamaya geri döndüren belgelenmiş bir OAuth bağlantısı sunmadığı için giriş güvenli tarayıcı sayfasında tamamlanır.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.muted,
                      fontSize: 11,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SecurityNote extends StatelessWidget {
  const _SecurityNote({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.blue, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: AppColors.ivory, height: 1.45),
          ),
        ),
      ],
    );
  }
}

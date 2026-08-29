import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:valo_magaza/models/auth_session.dart';
import 'package:valo_magaza/providers/auth_provider.dart';
import 'package:valo_magaza/services/riot_auth_service.dart';
import 'package:valo_magaza/services/secure_storage_service.dart';

class _MemoryStore implements SecureKeyValueStore {
  final values = <String, String>{};

  @override
  Future<void> delete(String key) async => values.remove(key);

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;
}

void main() {
  test(
    'süresi geçmiş saklı oturum açılışta giriş ekranına yönlendirir',
    () async {
      final storage = SecureStorageService(store: _MemoryStore());
      final expiredToken = _jwtWithExpiration(
        DateTime.now().subtract(const Duration(minutes: 2)),
      );
      await storage.saveSession(
        AuthSession(
          accessToken: expiredToken,
          idToken: expiredToken,
          entitlementsToken: 'not-a-real-entitlement-token',
          puuid: 'mock-puuid',
          region: 'eu',
          shard: 'eu',
        ),
      );
      final provider = AuthProvider(RiotAuthService(storage));

      await provider.initialize();

      expect(provider.status, AuthStatus.signedOut);
      expect(provider.session, isNull);
      expect(await storage.readSession(), isNull);
    },
  );

  test('henüz geçerli token saklı oturum olarak kullanılabilir', () {
    final token = _jwtWithExpiration(
      DateTime.now().add(const Duration(minutes: 5)),
    );
    final session = AuthSession(
      accessToken: token,
      idToken: token,
      entitlementsToken: 'not-a-real-entitlement-token',
      puuid: 'mock-puuid',
      region: 'eu',
      shard: 'eu',
    );

    expect(session.isExpired, isFalse);
  });

  test('kullanıcı çıkışı bütün kayıtlı hesap oturumlarını siler', () async {
    final storage = SecureStorageService(store: _MemoryStore());
    for (final puuid in ['first-puuid', 'second-puuid']) {
      await storage.saveSession(
        AuthSession(
          accessToken: '$puuid-access',
          idToken: '$puuid-id',
          entitlementsToken: '$puuid-entitlement',
          puuid: puuid,
          region: 'eu',
          shard: 'eu',
        ),
      );
    }
    final provider = AuthProvider(RiotAuthService(storage));
    await provider.initialize();

    await provider.logout();

    expect(provider.status, AuthStatus.signedOut);
    expect(provider.accounts, isEmpty);
    expect(await storage.listAccounts(), isEmpty);
  });
}

String _jwtWithExpiration(DateTime expiration) {
  final payload = base64Url
      .encode(
        utf8.encode(
          jsonEncode({'exp': expiration.millisecondsSinceEpoch ~/ 1000}),
        ),
      )
      .replaceAll('=', '');
  return 'not-a-real-header.$payload.not-a-real-signature';
}

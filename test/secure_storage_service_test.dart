import 'package:flutter_test/flutter_test.dart';
import 'package:valo_magaza/models/auth_session.dart';
import 'package:valo_magaza/services/secure_storage_service.dart';

class MemorySecureStore implements SecureKeyValueStore {
  final values = <String, String>{};

  @override
  Future<void> delete(String key) async => values.remove(key);

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;
}

void main() {
  test('çıkışta bütün token ve oturum alanları temizlenir', () async {
    final memory = MemorySecureStore();
    final storage = SecureStorageService(store: memory);
    const session = AuthSession(
      accessToken: 'not-a-real-access-token',
      idToken: 'not-a-real-id-token',
      entitlementsToken: 'not-a-real-entitlement-token',
      puuid: 'mock-puuid',
      region: 'eu',
      shard: 'eu',
    );

    await storage.saveSession(session);
    expect(memory.values, isNotEmpty);
    await storage.clearSession();

    expect(memory.values, isEmpty);
    expect(await storage.readSession(), isNull);
  });

  test('birden fazla hesap şifreli depoda ayrı tutulur ve seçilir', () async {
    final storage = SecureStorageService(store: MemorySecureStore());
    const first = AuthSession(
      accessToken: 'first-access',
      idToken: 'first-id',
      entitlementsToken: 'first-entitlement',
      puuid: 'first-puuid',
      region: 'eu',
      shard: 'eu',
    );
    const second = AuthSession(
      accessToken: 'second-access',
      idToken: 'second-id',
      entitlementsToken: 'second-entitlement',
      puuid: 'second-puuid',
      region: 'na',
      shard: 'na',
    );

    await storage.saveSession(first);
    await storage.saveSession(second);

    expect(await storage.listAccounts(), hasLength(2));
    expect((await storage.readSession())?.puuid, 'second-puuid');
    expect((await storage.selectAccount('first-puuid'))?.region, 'eu');

    await storage.clearSession();
    expect(await storage.listAccounts(), hasLength(1));
    expect(
      (await storage.selectAccount('second-puuid'))?.puuid,
      'second-puuid',
    );
  });
}

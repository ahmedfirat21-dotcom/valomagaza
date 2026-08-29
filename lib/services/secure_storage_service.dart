import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/auth_session.dart';

abstract interface class SecureKeyValueStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

class FlutterSecureKeyValueStore implements SecureKeyValueStore {
  FlutterSecureKeyValueStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}

class SecureStorageService {
  SecureStorageService({SecureKeyValueStore? store})
    : _store = store ?? FlutterSecureKeyValueStore();

  static const _prefix = 'valo_magaza_session_';
  static const _accountPrefix = 'valo_magaza_account_';
  static const _accountIdsKey = 'valo_magaza_account_ids';
  static const _activeAccountKey = 'valo_magaza_active_account';
  static const _fields = <String>[
    'accessToken',
    'idToken',
    'entitlementsToken',
    'puuid',
    'region',
    'shard',
  ];

  final SecureKeyValueStore _store;

  Future<void> saveSession(AuthSession session) async {
    final accountId = _normalizeAccountId(session.puuid);
    for (final entry in session.toStorageMap().entries) {
      await _store.write(
        '$_accountPrefix${accountId}_${entry.key}',
        entry.value,
      );
    }
    final accountIds = await _readAccountIds();
    if (!accountIds.contains(accountId)) {
      accountIds.add(accountId);
      await _writeAccountIds(accountIds);
    }
    await _store.write(_activeAccountKey, accountId);
  }

  Future<AuthSession?> readSession() async {
    final activeId = await _store.read(_activeAccountKey);
    if (activeId != null && activeId.isNotEmpty) {
      return _readAccount(activeId);
    }
    // 1.2 ve önceki sürümlerdeki tek-hesap oturumu sorunsuz taşınır.
    final values = <String, String?>{};
    for (final field in _fields) {
      values[field] = await _store.read('$_prefix$field');
    }
    final legacy = AuthSession.fromStorageMap(values);
    if (legacy != null) {
      await saveSession(legacy);
      await _clearLegacySession();
    }
    return legacy;
  }

  Future<List<SavedAccount>> listAccounts() async {
    final accounts = <SavedAccount>[];
    for (final id in await _readAccountIds()) {
      final session = await _readAccount(id);
      if (session != null) accounts.add(SavedAccount.fromSession(session));
    }
    return accounts;
  }

  Future<AuthSession?> selectAccount(String puuid) async {
    final id = _normalizeAccountId(puuid);
    final session = await _readAccount(id);
    if (session != null) await _store.write(_activeAccountKey, id);
    return session;
  }

  Future<void> removeAccount(String puuid) async {
    final accountId = _normalizeAccountId(puuid);
    final activeId = await _store.read(_activeAccountKey);
    if (activeId == accountId) {
      await clearSession();
      return;
    }
    for (final field in _fields) {
      await _store.delete('$_accountPrefix${accountId}_$field');
    }
    final accountIds = await _readAccountIds()
      ..remove(accountId);
    if (accountIds.isEmpty) {
      await _store.delete(_accountIdsKey);
    } else {
      await _writeAccountIds(accountIds);
    }
  }

  /// Etkin hesabı kaldırır; cihazdaki diğer hesapların şifreli oturumları kalır.
  Future<void> clearSession() async {
    final activeId = await _store.read(_activeAccountKey);
    if (activeId == null || activeId.isEmpty) {
      await _clearLegacySession();
      return;
    }
    for (final field in _fields) {
      await _store.delete('$_accountPrefix${activeId}_$field');
    }
    final accountIds = await _readAccountIds()
      ..remove(activeId);
    if (accountIds.isEmpty) {
      await _store.delete(_accountIdsKey);
    } else {
      await _writeAccountIds(accountIds);
    }
    await _store.delete(_activeAccountKey);
  }

  Future<void> clearAllSessions() async {
    for (final id in await _readAccountIds()) {
      for (final field in _fields) {
        await _store.delete('$_accountPrefix${id}_$field');
      }
    }
    await _store.delete(_accountIdsKey);
    await _store.delete(_activeAccountKey);
    await _clearLegacySession();
  }

  Future<AuthSession?> _readAccount(String accountId) async {
    final values = <String, String?>{};
    for (final field in _fields) {
      values[field] = await _store.read('$_accountPrefix${accountId}_$field');
    }
    return AuthSession.fromStorageMap(values);
  }

  Future<List<String>> _readAccountIds() async {
    final raw = await _store.read(_accountIdsKey);
    if (raw == null) return <String>[];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return <String>[];
      return decoded
          .map((value) => _normalizeAccountId(value.toString()))
          .where((value) => value.isNotEmpty)
          .toSet()
          .toList(growable: true);
    } on FormatException {
      return <String>[];
    }
  }

  Future<void> _writeAccountIds(List<String> accountIds) =>
      _store.write(_accountIdsKey, jsonEncode(accountIds));

  Future<void> _clearLegacySession() async {
    for (final field in _fields) {
      await _store.delete('$_prefix$field');
    }
  }

  static String _normalizeAccountId(String value) => value.toLowerCase();
}

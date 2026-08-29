import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/api_exception.dart';
import '../core/constants.dart';
import '../models/auth_session.dart';
import 'secure_storage_service.dart';

class RiotAuthService {
  RiotAuthService(this._storage, {http.Client? client})
    : _client = client ?? http.Client();

  final SecureStorageService _storage;
  final http.Client _client;

  static OAuthTokens parseRedirectUrl(String value) {
    final uri = Uri.tryParse(value.trim());
    if (uri == null ||
        uri.host.toLowerCase() != 'localhost' ||
        uri.path != '/redirect') {
      throw const ApiException(ApiErrorType.invalidLoginUrl);
    }
    final fragment = Uri.splitQueryString(uri.fragment);
    final accessToken = fragment['access_token'];
    final idToken = fragment['id_token'];
    if (accessToken == null ||
        accessToken.isEmpty ||
        idToken == null ||
        idToken.isEmpty) {
      throw const ApiException(ApiErrorType.invalidLoginUrl);
    }
    return OAuthTokens(accessToken: accessToken, idToken: idToken);
  }

  static String regionToShard(String region) {
    switch (region.toLowerCase()) {
      case 'na':
      case 'eu':
      case 'ap':
      case 'kr':
        return region.toLowerCase();
      case 'latam':
      case 'br':
        return 'na';
      default:
        throw const ApiException(ApiErrorType.serviceUnavailable);
    }
  }

  Future<AuthSession?> restoreSession() => _storage.readSession();

  Future<List<SavedAccount>> listAccounts() => _storage.listAccounts();

  Future<AuthSession?> selectAccount(String puuid) =>
      _storage.selectAccount(puuid);

  Future<void> removeAccount(String puuid) => _storage.removeAccount(puuid);

  Future<AuthSession> completeAuthentication(OAuthTokens tokens) async {
    try {
      final responses = await Future.wait([
        _client
            .post(
              Uri.parse(AppConstants.entitlementsUrl),
              headers: {
                'Authorization': 'Bearer ${tokens.accessToken}',
                'Content-Type': 'application/json',
              },
              body: '{}',
            )
            .timeout(AppConstants.requestTimeout),
        _client
            .get(
              Uri.parse(AppConstants.userInfoUrl),
              headers: {'Authorization': 'Bearer ${tokens.accessToken}'},
            )
            .timeout(AppConstants.requestTimeout),
        _client
            .put(
              Uri.parse(AppConstants.geoUrl),
              headers: {
                'Authorization': 'Bearer ${tokens.accessToken}',
                'Content-Type': 'application/json',
              },
              body: jsonEncode({'id_token': tokens.idToken}),
            )
            .timeout(AppConstants.requestTimeout),
      ]);
      for (final response in responses) {
        if (response.statusCode < 200 || response.statusCode >= 300) {
          throw ApiException.fromStatus(response.statusCode);
        }
      }

      final entitlementJson = _jsonMap(responses[0].body);
      final userJson = _jsonMap(responses[1].body);
      final geoJson = _jsonMap(responses[2].body);
      final entitlement = entitlementJson['entitlements_token']?.toString();
      final puuid = userJson['sub']?.toString();
      final affinities = _asMap(geoJson['affinities']);
      final region = affinities?['live']?.toString().toLowerCase();
      if (entitlement == null ||
          entitlement.isEmpty ||
          puuid == null ||
          puuid.isEmpty ||
          region == null ||
          region.isEmpty) {
        throw const ApiException(ApiErrorType.serviceUnavailable);
      }

      final session = AuthSession(
        accessToken: tokens.accessToken,
        idToken: tokens.idToken,
        entitlementsToken: entitlement,
        puuid: puuid,
        region: region,
        shard: regionToShard(region),
      );
      await _storage.saveSession(session);
      return session;
    } on ApiException {
      rethrow;
    } on http.ClientException {
      throw const ApiException(ApiErrorType.network);
    } on TimeoutException {
      throw const ApiException(ApiErrorType.network);
    } on FormatException {
      throw const ApiException(ApiErrorType.serviceUnavailable);
    } catch (_) {
      throw const ApiException(ApiErrorType.network);
    }
  }

  Future<void> logout() => _storage.clearSession();

  Future<void> logoutAll() => _storage.clearAllSessions();

  static Map<String, dynamic> _jsonMap(String source) {
    final value = jsonDecode(source);
    if (value is! Map) throw const FormatException();
    return Map<String, dynamic>.from(value);
  }

  static Map<String, dynamic>? _asMap(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }
}

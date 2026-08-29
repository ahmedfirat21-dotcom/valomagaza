import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/api_exception.dart';
import '../core/constants.dart';
import '../models/auth_session.dart';
import '../models/skin_offer.dart';
import '../models/wallet.dart';

class RiotStoreService {
  RiotStoreService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<StorefrontSnapshot> fetchStorefront(
    AuthSession session,
    String clientVersion,
  ) async {
    final headers = _headers(session, clientVersion);
    final v3 = Uri.parse(
      'https://pd.${session.shard}.a.pvp.net/store/v3/storefront/${session.puuid}',
    );
    try {
      var response = await _client
          .post(v3, headers: headers, body: '{}')
          .timeout(AppConstants.requestTimeout);
      if (response.statusCode == 404 || response.statusCode == 405) {
        final v2 = Uri.parse(
          'https://pd.${session.shard}.a.pvp.net/store/v2/storefront/${session.puuid}',
        );
        response = await _client
            .get(v2, headers: headers)
            .timeout(AppConstants.requestTimeout);
      }
      _ensureSuccess(response);
      final decoded = _decodeMap(response.body);
      return StorefrontSnapshot.fromJson(decoded);
    } on ApiException {
      rethrow;
    } on http.ClientException {
      throw const ApiException(ApiErrorType.network);
    } on FormatException {
      throw const ApiException(ApiErrorType.storeData);
    } catch (_) {
      throw const ApiException(ApiErrorType.network);
    }
  }

  Future<Wallet> fetchWallet(AuthSession session, String clientVersion) async {
    final uri = Uri.parse(
      'https://pd.${session.shard}.a.pvp.net/store/v1/wallet/${session.puuid}',
    );
    try {
      final response = await _client
          .get(uri, headers: _headers(session, clientVersion))
          .timeout(AppConstants.requestTimeout);
      _ensureSuccess(response);
      return Wallet.fromJson(_decodeMap(response.body));
    } on ApiException {
      rethrow;
    } on http.ClientException {
      throw const ApiException(ApiErrorType.network);
    } on TimeoutException {
      throw const ApiException(ApiErrorType.network);
    } on FormatException {
      throw const ApiException(ApiErrorType.storeData);
    } catch (_) {
      throw const ApiException(ApiErrorType.network);
    }
  }

  Map<String, String> _headers(AuthSession session, String clientVersion) => {
    'Authorization': 'Bearer ${session.accessToken}',
    'X-Riot-Entitlements-JWT': session.entitlementsToken,
    'X-Riot-ClientVersion': clientVersion,
    'X-Riot-ClientPlatform': AppConstants.riotClientPlatform,
    'Content-Type': 'application/json',
  };

  static void _ensureSuccess(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException.fromStatus(response.statusCode);
    }
  }

  static Map<String, dynamic> _decodeMap(String source) {
    final value = jsonDecode(source);
    if (value is! Map) throw const FormatException();
    return Map<String, dynamic>.from(value);
  }
}

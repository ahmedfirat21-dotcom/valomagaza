import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/api_exception.dart';
import '../core/constants.dart';
import '../models/auth_session.dart';

class RiotCompetitiveService {
  RiotCompetitiveService({http.Client? client})
    : _client = client ?? http.Client();

  final http.Client _client;

  Future<Map<String, dynamic>> fetchCurrentRank(
    AuthSession session,
    String clientVersion,
  ) => _get(
    session,
    clientVersion,
    'https://pd.${session.shard}.a.pvp.net/mmr/v1/players/${session.puuid}',
  );

  Future<List<Map<String, dynamic>>> fetchRecentUpdates(
    AuthSession session,
    String clientVersion, {
    int count = 10,
  }) async {
    final json = await _get(
      session,
      clientVersion,
      'https://pd.${session.shard}.a.pvp.net/mmr/v1/players/${session.puuid}/'
      'competitiveupdates?startIndex=0&endIndex=$count',
    );
    final raw = json['Matches'] ?? json['matches'];
    if (raw is! List) throw const FormatException('Rank geçmişi bulunamadı.');
    return raw
        .map(_map)
        .whereType<Map<String, dynamic>>()
        .take(count)
        .toList(growable: false);
  }

  Future<Map<String, dynamic>> _get(
    AuthSession session,
    String clientVersion,
    String url,
  ) async {
    try {
      final response = await _client
          .get(Uri.parse(url), headers: _headers(session, clientVersion))
          .timeout(AppConstants.requestTimeout);
      _ensureSuccess(response);
      return _decodeMap(response.body);
    } on ApiException {
      rethrow;
    } on http.ClientException {
      throw const ApiException(ApiErrorType.network);
    } on TimeoutException {
      throw const ApiException(ApiErrorType.network);
    } on FormatException {
      throw const ApiException(ApiErrorType.competitiveData);
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

  static Map<String, dynamic>? _map(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }
}

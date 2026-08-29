import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/api_exception.dart';
import '../core/constants.dart';
import '../models/auth_session.dart';

class RiotMatchService {
  RiotMatchService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<List<String>> fetchRecentMatchIds(
    AuthSession session,
    String clientVersion, {
    int count = 10,
  }) async {
    final uri = Uri.parse(
      'https://pd.${session.shard}.a.pvp.net/match-history/v1/history/'
      '${session.puuid}?startIndex=0&endIndex=$count',
    );
    try {
      final response = await _client
          .get(uri, headers: _headers(session, clientVersion))
          .timeout(AppConstants.requestTimeout);
      _ensureSuccess(response);
      final json = _decodeMap(response.body);
      final history = json['History'] ?? json['history'];
      if (history is! List) throw const FormatException();
      return history
          .map(_map)
          .whereType<Map<String, dynamic>>()
          .map(
            (entry) =>
                _map(entry['MatchDetails'] ?? entry['matchDetails']) ?? entry,
          )
          .map(
            (entry) => (entry['MatchID'] ?? entry['matchId'] ?? '').toString(),
          )
          .where((id) => id.isNotEmpty)
          .take(count)
          .toList(growable: false);
    } on ApiException {
      rethrow;
    } on http.ClientException {
      throw const ApiException(ApiErrorType.network);
    } on TimeoutException {
      throw const ApiException(ApiErrorType.network);
    } on FormatException {
      throw const ApiException(ApiErrorType.matchData);
    } catch (_) {
      throw const ApiException(ApiErrorType.network);
    }
  }

  Future<Map<String, dynamic>> fetchMatchDetail(
    AuthSession session,
    String clientVersion,
    String matchId,
  ) async {
    final uri = Uri.parse(
      'https://pd.${session.shard}.a.pvp.net/match-details/v1/matches/$matchId',
    );
    try {
      final response = await _client
          .get(uri, headers: _headers(session, clientVersion))
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
      throw const ApiException(ApiErrorType.matchData);
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

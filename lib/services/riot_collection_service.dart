import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/api_exception.dart';
import '../core/constants.dart';
import '../models/auth_session.dart';
import '../models/collection_item.dart';

class RiotCollectionService {
  RiotCollectionService({http.Client? client})
    : _client = client ?? http.Client();

  final http.Client _client;

  Future<List<String>> fetchOwnedSkinIds(
    AuthSession session,
    String clientVersion,
  ) async {
    final uri = Uri.parse(
      'https://pd.${session.shard}.a.pvp.net/store/v1/entitlements/'
      '${session.puuid}/${AppConstants.weaponSkinItemTypeId}',
    );
    try {
      final response = await _client
          .get(uri, headers: _headers(session, clientVersion))
          .timeout(AppConstants.requestTimeout);
      _ensureSuccess(response);
      return parseOwnedSkinIds(_decodeMap(response.body));
    } on ApiException {
      rethrow;
    } on http.ClientException {
      throw const ApiException(ApiErrorType.network);
    } on TimeoutException {
      throw const ApiException(ApiErrorType.network);
    } on FormatException {
      throw const ApiException(ApiErrorType.collectionData);
    } catch (_) {
      throw const ApiException(ApiErrorType.network);
    }
  }

  Future<List<PlayerLoadoutItem>> fetchLoadout(
    AuthSession session,
    String clientVersion,
  ) async {
    final uri = Uri.parse(
      'https://pd.${session.shard}.a.pvp.net/personalization/v2/players/'
      '${session.puuid}/playerloadout',
    );
    try {
      final response = await _client
          .get(uri, headers: _headers(session, clientVersion))
          .timeout(AppConstants.requestTimeout);
      _ensureSuccess(response);
      return parseLoadout(_decodeMap(response.body));
    } on ApiException {
      rethrow;
    } on http.ClientException {
      throw const ApiException(ApiErrorType.network);
    } on TimeoutException {
      throw const ApiException(ApiErrorType.network);
    } on FormatException {
      throw const ApiException(ApiErrorType.collectionData);
    } catch (_) {
      throw const ApiException(ApiErrorType.network);
    }
  }

  static List<String> parseOwnedSkinIds(Map<String, dynamic> json) {
    final raw = json['Entitlements'] ?? json['entitlements'];
    if (raw is! List) throw const FormatException('Envanter bulunamadı.');
    final result = <String>{};
    for (final value in raw) {
      final entry = _map(value);
      final id = (entry?['ItemID'] ?? entry?['itemId'] ?? '').toString();
      if (id.isNotEmpty) result.add(id.toLowerCase());
    }
    return result.toList(growable: false);
  }

  static List<PlayerLoadoutItem> parseLoadout(Map<String, dynamic> json) {
    final raw = json['Guns'] ?? json['guns'];
    if (raw is! List) throw const FormatException('Aktif loadout bulunamadı.');
    final result = <PlayerLoadoutItem>[];
    for (final value in raw) {
      final gun = _map(value);
      if (gun == null) continue;
      final weaponId = (gun['ID'] ?? gun['id'] ?? '').toString();
      final skinId = (gun['SkinID'] ?? gun['skinId'] ?? '').toString();
      final levelId = (gun['SkinLevelID'] ?? gun['skinLevelId'] ?? '')
          .toString();
      if (weaponId.isEmpty || (skinId.isEmpty && levelId.isEmpty)) continue;
      result.add(
        PlayerLoadoutItem(
          weaponId: weaponId,
          skinId: skinId,
          skinLevelId: levelId,
        ),
      );
    }
    return result;
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

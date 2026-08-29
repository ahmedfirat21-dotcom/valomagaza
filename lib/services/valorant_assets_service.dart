import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/api_exception.dart';
import '../core/constants.dart';
import '../models/collection_item.dart';
import '../models/competitive_rank.dart';
import '../models/match_summary.dart';
import '../models/skin_offer.dart';

class ValorantAssetsService {
  ValorantAssetsService({http.Client? client})
    : _client = client ?? http.Client();

  final http.Client _client;
  String? _clientVersion;
  Map<String, SkinCatalogEntry>? _catalog;
  Map<String, ContentTierInfo>? _tiers;
  Map<String, AgentCatalogEntry>? _agents;
  Map<String, MapCatalogEntry>? _maps;
  Map<String, WeaponSkinCatalogEntry>? _weaponSkins;
  Map<int, CompetitiveTierInfo>? _competitiveTiers;

  Future<String> getClientVersion() async {
    if (_clientVersion != null) return _clientVersion!;
    final json = await _getJson(AppConstants.versionUrl);
    final data = _asMap(json['data']);
    final version = data?['riotClientVersion']?.toString();
    if (version == null || version.isEmpty) {
      throw const ApiException(ApiErrorType.serviceUnavailable);
    }
    _clientVersion = version;
    return version;
  }

  Future<Map<String, SkinCatalogEntry>> getSkinCatalog() async {
    if (_catalog != null) return _catalog!;
    final json = await _getJson(AppConstants.skinsUrl);
    final data = json['data'];
    if (data is! List) {
      throw const ApiException(ApiErrorType.serviceUnavailable);
    }
    final result = <String, SkinCatalogEntry>{};
    for (final value in data) {
      final skin = _asMap(value);
      if (skin == null) continue;
      final skinId = skin['uuid']?.toString().toLowerCase();
      final skinName = skin['displayName']?.toString() ?? 'Bilinmeyen Kaplama';
      final skinImage = skin['displayIcon']?.toString() ?? '';
      final tierId = skin['contentTierUuid']?.toString();
      final wallpaper = skin['wallpaper']?.toString();

      final parsedLevels = <SkinLevel>[];
      final rawLevels = skin['levels'];
      if (rawLevels is List) {
        for (final lvlVal in rawLevels) {
          final lvl = _asMap(lvlVal);
          if (lvl == null) continue;
          final lvlUuid = lvl['uuid']?.toString().toLowerCase();
          if (lvlUuid == null) continue;
          parsedLevels.add(
            SkinLevel(
              uuid: lvlUuid,
              displayName: lvl['displayName']?.toString() ?? skinName,
              levelItem: lvl['levelItem']?.toString(),
              displayIcon: lvl['displayIcon']?.toString() ?? skinImage,
              streamedVideo: lvl['streamedVideo']?.toString(),
            ),
          );
        }
      }

      final parsedChromas = <SkinChroma>[];
      final rawChromas = skin['chromas'];
      if (rawChromas is List) {
        for (final chVal in rawChromas) {
          final ch = _asMap(chVal);
          if (ch == null) continue;
          final chUuid = ch['uuid']?.toString().toLowerCase();
          if (chUuid == null) continue;
          parsedChromas.add(
            SkinChroma(
              uuid: chUuid,
              displayName: ch['displayName']?.toString() ?? skinName,
              displayIcon: ch['displayIcon']?.toString(),
              fullRender: ch['fullRender']?.toString(),
              swatch: ch['swatch']?.toString(),
              streamedVideo: ch['streamedVideo']?.toString(),
            ),
          );
        }
      }

      final baseEntry = SkinCatalogEntry(
        name: skinName,
        imageUrl: skinImage,
        contentTierId: tierId,
        wallpaper: wallpaper,
        levels: List.unmodifiable(parsedLevels),
        chromas: List.unmodifiable(parsedChromas),
      );
      if (skinId != null) result[skinId] = baseEntry;

      final levels = skin['levels'];
      if (levels is List) {
        for (final levelValue in levels) {
          final level = _asMap(levelValue);
          final levelId = level?['uuid']?.toString().toLowerCase();
          if (levelId == null) continue;
          result[levelId] = SkinCatalogEntry(
            name: level?['displayName']?.toString() ?? skinName,
            imageUrl: level?['displayIcon']?.toString() ?? skinImage,
            contentTierId: tierId,
            wallpaper: wallpaper,
            levels: List.unmodifiable(parsedLevels),
            chromas: List.unmodifiable(parsedChromas),
          );
        }
      }
    }
    _catalog = Map.unmodifiable(result);
    return _catalog!;
  }

  Future<Map<String, ContentTierInfo>> getContentTiers() async {
    if (_tiers != null) return _tiers!;
    final json = await _getJson(AppConstants.contentTiersUrl);
    final data = json['data'];
    if (data is! List) {
      throw const ApiException(ApiErrorType.serviceUnavailable);
    }
    final result = <String, ContentTierInfo>{};
    for (final value in data) {
      final tier = _asMap(value);
      final id = tier?['uuid']?.toString().toLowerCase();
      if (id == null) continue;
      result[id] = ContentTierInfo(
        name: tier?['displayName']?.toString() ?? 'Bilinmeyen Seviye',
        colorHex: tier?['highlightColor']?.toString(),
      );
    }
    _tiers = Map.unmodifiable(result);
    return _tiers!;
  }

  Future<Map<String, AgentCatalogEntry>> getAgentCatalog() async {
    if (_agents != null) return _agents!;
    final json = await _getJson(AppConstants.agentsUrl);
    final data = json['data'];
    if (data is! List) {
      throw const ApiException(ApiErrorType.serviceUnavailable);
    }
    final result = <String, AgentCatalogEntry>{};
    for (final value in data) {
      final agent = _asMap(value);
      final id = agent?['uuid']?.toString().toLowerCase();
      if (id == null) continue;
      result[id] = AgentCatalogEntry(
        name: agent?['displayName']?.toString() ?? 'Bilinmeyen Ajan',
        imageUrl: agent?['displayIcon']?.toString() ?? '',
      );
    }
    _agents = Map.unmodifiable(result);
    return _agents!;
  }

  Future<Map<String, MapCatalogEntry>> getMapCatalog() async {
    if (_maps != null) return _maps!;
    final json = await _getJson(AppConstants.mapsUrl);
    final data = json['data'];
    if (data is! List) {
      throw const ApiException(ApiErrorType.serviceUnavailable);
    }
    final result = <String, MapCatalogEntry>{};
    for (final value in data) {
      final map = _asMap(value);
      final id = map?['uuid']?.toString().toLowerCase();
      if (id == null) continue;
      result[id] = MapCatalogEntry(
        name: map?['displayName']?.toString() ?? 'Bilinmeyen Harita',
        splashUrl: map?['splash']?.toString(),
      );
    }
    _maps = Map.unmodifiable(result);
    return _maps!;
  }

  Future<Map<String, WeaponSkinCatalogEntry>> getWeaponSkinCatalog() async {
    if (_weaponSkins != null) return _weaponSkins!;
    final json = await _getJson(AppConstants.weaponsUrl);
    final data = json['data'];
    if (data is! List) {
      throw const ApiException(ApiErrorType.serviceUnavailable);
    }
    final result = <String, WeaponSkinCatalogEntry>{};
    for (final value in data) {
      final weapon = _asMap(value);
      if (weapon == null) continue;
      final weaponName = weapon['displayName']?.toString() ?? 'Silah';
      final category = weapon['category']?.toString() ?? '';
      final skins = weapon['skins'];
      if (skins is! List) continue;
      for (final skinValue in skins) {
        final skin = _asMap(skinValue);
        final skinId = skin?['uuid']?.toString().toLowerCase();
        if (skin == null || skinId == null) continue;
        final name = skin['displayName']?.toString() ?? 'Bilinmeyen kaplama';
        final imageUrl = skin['displayIcon']?.toString() ?? '';
        final tierId = skin['contentTierUuid']?.toString();
        final base = WeaponSkinCatalogEntry(
          skinId: skinId,
          name: name,
          weaponName: weaponName,
          weaponCategory: category,
          imageUrl: imageUrl,
          contentTierId: tierId,
        );
        result[skinId] = base;
        final levels = skin['levels'];
        if (levels is List) {
          for (final levelValue in levels) {
            final level = _asMap(levelValue);
            final levelId = level?['uuid']?.toString().toLowerCase();
            if (levelId == null) continue;
            result[levelId] = WeaponSkinCatalogEntry(
              skinId: skinId,
              name: level?['displayName']?.toString() ?? name,
              weaponName: weaponName,
              weaponCategory: category,
              imageUrl: level?['displayIcon']?.toString() ?? imageUrl,
              contentTierId: tierId,
            );
          }
        }
      }
    }
    _weaponSkins = Map.unmodifiable(result);
    return _weaponSkins!;
  }

  Future<Map<int, CompetitiveTierInfo>> getCompetitiveTiers() async {
    if (_competitiveTiers != null) return _competitiveTiers!;
    final json = await _getJson(AppConstants.competitiveTiersUrl);
    final data = json['data'];
    if (data is! List) {
      throw const ApiException(ApiErrorType.serviceUnavailable);
    }
    final result = <int, CompetitiveTierInfo>{};
    // API verileri kronolojik sırada döner (Episode 1 en başta). Güncel sezonun
    // rank isimlerini (ör. Ascendant, güncel Immortal) kullanmak için sondan
    // başa iterasyon yapılır; ilk görülen (=en güncel) eşleme korunur.
    for (final seasonValue in data.reversed) {
      final season = _asMap(seasonValue);
      final tiers = season?['tiers'];
      if (tiers is! List) continue;
      for (final tierValue in tiers) {
        final tier = _asMap(tierValue);
        final id = _int(tier?['tier']);
        if (id == null || result.containsKey(id)) continue;
        final tierName = tier?['tierName']?.toString();
        if (tierName == null || tierName.isEmpty) continue;
        result[id] = CompetitiveTierInfo(
          tier: id,
          name: tierName,
          iconUrl: tier?['largeIcon']?.toString(),
        );
      }
    }
    _competitiveTiers = Map.unmodifiable(result);
    return _competitiveTiers!;
  }

  Future<Map<String, dynamic>> _getJson(String url) async {
    try {
      final response = await _client
          .get(Uri.parse(url))
          .timeout(AppConstants.requestTimeout);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ApiException.fromStatus(response.statusCode);
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! Map) throw const FormatException();
      return Map<String, dynamic>.from(decoded);
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

  static Map<String, dynamic>? _asMap(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  static int? _int(Object? value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }
}

import 'dart:convert';

class OAuthTokens {
  const OAuthTokens({required this.accessToken, required this.idToken});

  final String accessToken;
  final String idToken;
}

class AuthSession {
  const AuthSession({
    required this.accessToken,
    required this.idToken,
    required this.entitlementsToken,
    required this.puuid,
    required this.region,
    required this.shard,
  });

  final String accessToken;
  final String idToken;
  final String entitlementsToken;
  final String puuid;
  final String region;
  final String shard;

  /// Token içindeki süre yalnızca kullanıcı deneyimi için yerelde okunur.
  /// Yetkilendirme kararını her zaman Riot sunucusu verir.
  bool get isExpired {
    final expiration = _jwtExpiration(accessToken) ?? _jwtExpiration(idToken);
    if (expiration == null) return false;
    return !DateTime.now().isBefore(
      expiration.subtract(const Duration(seconds: 30)),
    );
  }

  Map<String, String> toStorageMap() => {
    'accessToken': accessToken,
    'idToken': idToken,
    'entitlementsToken': entitlementsToken,
    'puuid': puuid,
    'region': region,
    'shard': shard,
  };

  static AuthSession? fromStorageMap(Map<String, String?> values) {
    final accessToken = values['accessToken'];
    final idToken = values['idToken'];
    final entitlementsToken = values['entitlementsToken'];
    final puuid = values['puuid'];
    final region = values['region'];
    final shard = values['shard'];
    if ([
      accessToken,
      idToken,
      entitlementsToken,
      puuid,
      region,
      shard,
    ].any((value) => value?.isEmpty != false)) {
      return null;
    }
    return AuthSession(
      accessToken: accessToken!,
      idToken: idToken!,
      entitlementsToken: entitlementsToken!,
      puuid: puuid!,
      region: region!,
      shard: shard!,
    );
  }

  static DateTime? _jwtExpiration(String token) {
    final parts = token.split('.');
    if (parts.length < 2) return null;
    try {
      final payload = utf8.decode(
        base64Url.decode(base64Url.normalize(parts[1])),
      );
      final json = jsonDecode(payload);
      if (json is! Map) return null;
      final rawExpiration = json['exp'];
      final seconds = rawExpiration is num
          ? rawExpiration.toInt()
          : int.tryParse(rawExpiration?.toString() ?? '');
      if (seconds == null || seconds <= 0) return null;
      return DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
    } on FormatException {
      return null;
    }
  }
}

class SavedAccount {
  const SavedAccount({
    required this.puuid,
    required this.region,
    required this.shard,
  });

  final String puuid;
  final String region;
  final String shard;

  String get label =>
      'Hesap • ${puuid.length > 8 ? puuid.substring(0, 8) : puuid}';

  factory SavedAccount.fromSession(AuthSession session) => SavedAccount(
    puuid: session.puuid,
    region: session.region,
    shard: session.shard,
  );
}

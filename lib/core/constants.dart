class AppConstants {
  AppConstants._();

  static const appName = 'Valo Mağaza';
  static const privacyPolicyUrl =
      'https://github.com/ahmedfirat21-dotcom/valomagaza/blob/main/PRIVACY.md';
  static const requestTimeout = Duration(seconds: 20);

  static const authUrl =
      'https://auth.riotgames.com/authorize?redirect_uri=http%3A%2F%2Flocalhost%2Fredirect&client_id=riot-client&response_type=token%20id_token&nonce=1&scope=openid%20link%20ban%20lol_region%20account&prompt=login';

  static const entitlementsUrl =
      'https://entitlements.auth.riotgames.com/api/token/v1';
  static const userInfoUrl = 'https://auth.riotgames.com/userinfo';
  static const geoUrl =
      'https://riot-geo.pas.si.riotgames.com/pas/v1/product/valorant';
  static const versionUrl = 'https://valorant-api.com/v1/version';
  static const skinsUrl =
      'https://valorant-api.com/v1/weapons/skins?language=tr-TR';
  static const contentTiersUrl =
      'https://valorant-api.com/v1/contenttiers?language=tr-TR';
  static const agentsUrl =
      'https://valorant-api.com/v1/agents?language=tr-TR&isPlayableCharacter=true';
  static const mapsUrl = 'https://valorant-api.com/v1/maps?language=tr-TR';
  static const weaponsUrl =
      'https://valorant-api.com/v1/weapons?language=tr-TR';
  static const competitiveTiersUrl =
      'https://valorant-api.com/v1/competitivetiers?language=tr-TR';

  // VALORANT envanterindeki silah kaplaması entitlement türü. Yalnızca
  // GET ile okunur; uygulama hiçbir envanter veya ödeme isteği göndermez.
  static const weaponSkinItemTypeId = 'e7c63390-eda7-46e0-bb7a-a6abdacd2433';

  static const vpCurrencyId = '85ad13f7-3d1b-5128-9eb2-7cd8ee0b5741';
  static const radianiteCurrencyId = 'e59aa87c-4cbf-517a-5983-6e81511be9b7';
  static const kingdomCreditsCurrencyId =
      '85ca954a-41f2-ce94-9b45-8ca3dd39a00d';

  // Riot istemcisinin mağaza isteklerinde bildirdiği Windows PC platform
  // bilgisinin Base64 kodlu JSON karşılığıdır. Kullanıcı veya token verisi
  // içermez; yalnızca sabit platform özelliklerini tanımlar.
  static const riotClientPlatform =
      'ew0KCSJwbGF0Zm9ybVR5cGUiOiAiUEMiLA0KCSJwbGF0Zm9ybU9TIjogIldpbmRvd3MiLA0KCSJwbGF0Zm9ybU9TVmVyc2lvbiI6ICIxMC4wLjE5MDQyLjEuMjU2LjY0Yml0IiwNCgkicGxhdGZvcm1DaGlwc2V0IjogIlVua25vd24iDQp9';

  static const legalNotice =
      "Valo Mağaza isn't endorsed by Riot Games and doesn't reflect the views "
      'or opinions of Riot Games or anyone officially involved in producing or '
      'managing Riot Games properties. Riot Games, and all associated '
      'properties are trademarks or registered trademarks of Riot Games, Inc.';
}

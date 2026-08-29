import 'package:flutter_test/flutter_test.dart';
import 'package:valo_magaza/core/api_exception.dart';
import 'package:valo_magaza/services/riot_auth_service.dart';

void main() {
  group('OAuth redirect URL parser', () {
    test('localhost redirect fragment içindeki tokenları çözümler', () {
      final tokens = RiotAuthService.parseRedirectUrl(
        'http://localhost/redirect#access_token=not-a-real-access-token&'
        'id_token=not-a-real-id-token&expires_in=3600',
      );

      expect(tokens.accessToken, 'not-a-real-access-token');
      expect(tokens.idToken, 'not-a-real-id-token');
    });

    test('geçersiz host içeren URL reddedilir', () {
      expect(
        () => RiotAuthService.parseRedirectUrl(
          'https://example.com/redirect#access_token=x&id_token=y',
        ),
        throwsA(
          isA<ApiException>().having(
            (error) => error.type,
            'type',
            ApiErrorType.invalidLoginUrl,
          ),
        ),
      );
    });

    test('access token eksik URL reddedilir', () {
      expect(
        () => RiotAuthService.parseRedirectUrl(
          'http://localhost/redirect#id_token=not-a-real-id-token',
        ),
        throwsA(isA<ApiException>()),
      );
    });
  });

  test('region değerleri doğru shard değerine eşlenir', () {
    expect(RiotAuthService.regionToShard('na'), 'na');
    expect(RiotAuthService.regionToShard('EU'), 'eu');
    expect(RiotAuthService.regionToShard('ap'), 'ap');
    expect(RiotAuthService.regionToShard('kr'), 'kr');
    expect(RiotAuthService.regionToShard('latam'), 'na');
    expect(RiotAuthService.regionToShard('br'), 'na');
  });
}

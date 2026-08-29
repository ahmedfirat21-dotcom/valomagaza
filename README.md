# Valo Mağaza

Valo Mağaza, kişisel VALORANT hesabının günlük mağazasındaki dört kaplama teklifini, aktif olduğunda Gece Pazarı indirimlerini, VP/Radianite/Kingdom Credits bakiyelerini, yenilenme sürelerini ve son 10 tamamlanmış maçın özetini Android telefonda gösteren Türkçe bir Flutter uygulamasıdır. Uygulama yalnızca görüntüleme yapar; satın alma, otomatik satın alma veya canlı oyuna müdahale özelliği yoktur.

## Uygulama bölümleri

- **Mağaza:** Günlük teklifler, Gece Pazarı, normal/indirimli VP fiyatları, içerik seviyeleri ve VP/RP/KC bakiyeleri.
- **Maçlar:** Son 10 maç için harita, mod, ajan, galibiyet/mağlubiyet, skor, K/D/A, ACS, kafa vuruşu oranı, süre ve tarih. Bir maça dokunulduğunda iki takımın oyuncu, ajan, K/D/A ve ACS tablosu açılır.
- **Koleksiyon:** Hesaptaki sahip olunan silah skinleri, bıçaklar, aktif loadout işaretleri; ayrıca Valorant açık varlık kataloğundaki tüm silah/bıçak skinlerini büyük görsel önizleme ile görüntüleme.
- **Rekabet:** Güncel rank, RR ve son dereceli maçlardaki RR değişimleri.
- **Hesap:** Bölge/shard özeti, Android Keystore içinde ayrı tutulan çoklu hesap oturumları, hesap seçme, yerel token güvenliği, yasal bilgi ve cihazdan çıkış.

## Çalıştırma

Geliştirme ortamında proje klasöründe şu komutları çalıştırın:

```powershell
flutter pub get
flutter run
```

Bağlı cihazları görmek için `flutter devices`, ortamı denetlemek için `flutter doctor -v` kullanılabilir.

## APK

Debug APK üretmek için:

```powershell
flutter build apk --debug
```

Üretilen dosya:

```text
build/app/outputs/flutter-apk/app-debug.apk
```

## Telefona kurulum

1. `app-debug.apk` dosyasını USB, Drive veya tercih ettiğiniz güvenli bir yöntemle telefona aktarın.
2. Telefonda dosyayı açın.
3. Android isterse yalnızca kullandığınız dosya yöneticisi için “Bilinmeyen uygulamaları yükle” iznini geçici olarak verin.
4. **Yükle** seçeneğine dokunun. Kurulum tamamlandıktan sonra geçici yükleme iznini tekrar kapatabilirsiniz.

USB hata ayıklama açık bir telefon bağlıysa terminalden de kurulabilir:

```powershell
adb install -r build/app/outputs/flutter-apk/app-debug.apk
```

## Google Play için imzalı AAB

Release derlemesi hiçbir zaman debug anahtarıyla imzalanmaz. Önce uzun süre
güvenle saklanacak bir upload keystore oluşturun ve `android/key.properties.example`
dosyasını `android/key.properties` adıyla kopyalayıp gerçek değerleri girin.
`key.properties` ve `.jks` dosyaları Git tarafından yok sayılır; bunları depoya
eklemeyin.

Yerel mağaza paketi şu komutla üretilir:

```powershell
flutter build appbundle --release
```

Çıktı:

```text
build/app/outputs/bundle/release/app-release.aab
```

GitHub Actions üzerinden üretmek için depo ayarlarında aşağıdaki Actions
secret'larını tanımlayın ve **Android release bundle** iş akışını elle çalıştırın:

- `ANDROID_KEYSTORE_BASE64`: `.jks` dosyasının Base64 içeriği
- `ANDROID_STORE_PASSWORD`: keystore şifresi
- `ANDROID_KEY_ALIAS`: anahtar takma adı
- `ANDROID_KEY_PASSWORD`: anahtar şifresi

İş akışı analiz ve testleri çalıştırdıktan sonra imzalı AAB'yi 14 gün saklanan
`valomagaza-release-aab` artifact'i olarak verir.

## Riot girişi ve bağlantıyı kopyalama

1. Uygulamada **Riot Hesabımla Giriş Yap** düğmesine dokunun.
2. Telefonun gerçek tarayıcısında açılan Riot sayfasında giriş yapın. Riot kullanıcı adı ve şifresi Valo Mağaza ekranına girilmez.
3. Girişten sonra tarayıcı `http://localhost/redirect#access_token=...` ile başlayan bir adrese gider. Localhost sayfasının açılmaması normaldir.
4. Tarayıcının adres çubuğuna dokunup bağlantının **tamamını** kopyalayın; yalnız görünen kısmı değil, fragment içeren tam URL’yi kopyaladığınızdan emin olun.
5. Valo Mağaza’ya dönüp **Panodan Bağlantıyı Al** düğmesine dokunun.

Riot Mobile yüklü olsa bile giriş tarayıcıda açılır. Riot Mobile, bu web OAuth bağlantısını Valo Mağaza’ya geri döndüren belgelenmiş bir deep-link şeması sunmadığı için uygulamayı zorla açmak giriş tokenını geri getirmez.

Uygulama yalnız host değeri `localhost`, path değeri `/redirect` olan bağlantıları kabul eder. Tokenları URL fragment bölümünden cihaz üzerinde çıkarır.

## Güvenlik yaklaşımı

- Riot şifresi uygulama tarafından istenmez, görülmez veya saklanmaz.
- Oturum tokenları `flutter_secure_storage` aracılığıyla Android Keystore korumalı alanda saklanır; SharedPreferences içine yazılmaz.
- Tokenlar loglanmaz, hata mesajlarına eklenmez ve herhangi bir geliştirici sunucusuna gönderilmez.
- Analytics, reklam ve hata takip SDK’sı yoktur.
- SSL sertifika doğrulaması kapatılmaz.
- 401/403 yanıtında oturum verileri temizlenir ve giriş ekranına dönülür.
- **Çıkış Yap** bütün yerel oturum alanlarını siler.

Kopyalanan redirect bağlantısı erişim tokenı içerdiği için başka biriyle paylaşılmamalıdır.

## Resmî olmayan uygulama bildirimi

> Valo Mağaza, Riot Games tarafından desteklenmemekte veya onaylanmamaktadır. Riot Games ve ilişkili tüm varlıklar Riot Games, Inc.’in ticari markalarıdır.

Uygulama logosu Riot Games veya VALORANT logosu değildir; proje için oluşturulmuş özgün bir V simgesidir.

## Private endpoint değişiklikleri

Riot’un belgelenmemiş/private mağaza endpoint’leri değişebilir. Storefront URL’leri, v3 POST ve tek seferlik v2 GET fallback davranışı ile cüzdan isteği şu dosyadadır:

```text
lib/services/riot_store_service.dart
```

Riot oturum/geo istekleri değişirse `lib/services/riot_auth_service.dart`; skin, içerik seviyesi, ajan, harita veya istemci sürümü kaynağı değişirse `lib/services/valorant_assets_service.dart`; kişisel maç geçmişi private endpoint'i değişirse `lib/services/riot_match_service.dart` güncellenmelidir.

Riot'un resmî VALORANT API politikası, oyuncu istatistikleri için onaylı RSO/opt-in akışını gerektirir ve kişisel API anahtarı sağlamaz. Bu kişisel uygulamadaki mağaza ve maç geçmişi istekleri belgelenmemiş/private endpoint'lere dayandığından Riot değişiklikleriyle çalışmayı durdurabilir.

## Kalite kontrolleri

```powershell
dart format .
flutter analyze
flutter test
flutter build apk --debug
```

# Valo Mağaza Gizlilik Politikası

Son güncelleme: 29 Ağustos 2026

Valo Mağaza, kişisel kullanım için geliştirilmiş, Riot Games tarafından
desteklenmeyen veya onaylanmayan bir Android uygulamasıdır. Bu politika,
uygulamanın verileri nasıl işlediğini açıklar.

## İşlenen veriler

Uygulama, kullanıcının açıkça başlattığı Riot girişinden sonra aşağıdaki
verilere erişebilir:

- Riot erişim, kimlik ve yetkilendirme tokenları;
- Riot oyuncu kimliği (PUUID), bölge ve shard bilgisi;
- kişisel mağaza teklifleri ve oyun içi para bakiyeleri;
- maç geçmişi, rekabet derecesi, koleksiyon ve aktif ekipman bilgileri.

Uygulama Riot parolasını istemez, görmez veya saklamaz. Tarayıcıdan kopyalanan
giriş bağlantısı okunduktan hemen sonra telefonun panosu temizlenir.

## Verilerin kullanımı ve aktarımı

Bu veriler yalnızca uygulamadaki mağaza, maç, koleksiyon ve rekabet ekranlarını
oluşturmak için kullanılır. İstekler cihazdan doğrudan Riot Games hizmetlerine
HTTPS üzerinden gönderilir. Kaplama, ajan, harita ve sürüm gibi herkese açık
oyun bilgileri `valorant-api.com` hizmetinden alınır.

Uygulamanın geliştiriciye ait bir sunucusu yoktur. Veriler reklam, analiz,
profil oluşturma veya satış amacıyla geliştiriciye ya da reklam şirketlerine
gönderilmez. Riot Games ve `valorant-api.com`, kendilerine yapılan bağlantıları
kendi gizlilik koşullarına göre işleyebilir.

## Cihazda saklama

- Riot oturum tokenları `flutter_secure_storage` aracılığıyla Android Keystore
  korumalı depoda tutulur.
- İstek listesi, bildirim ayarları ve en fazla 30 günlük kişisel mağaza geçmişi
  uygulamanın yerel tercihler alanında tutulur.
- Android uygulama yedeklemesi kapalıdır.

## Bildirimler

Kullanıcı izin verirse uygulama, yalnızca açıldığında veya mağaza elle
yenilendiğinde istek listesi eşleşmesi için yerel bildirim gösterebilir.
Arka planda gizli mağaza sorgusu yapılmaz.

## Saklama ve silme

Oturum tokenları süreleri dolana, ilgili hesap kaldırılana veya kullanıcı çıkış
yapana kadar cihazda tutulur. **Bu Cihazdan Çıkış Yap** bütün kayıtlı Riot
oturumlarını siler. **Tüm Yerel Verileri Sil** seçeneği oturumlarla birlikte
mağaza geçmişini, istek listesini ve bildirim ayarlarını da cihazdan siler.

## İzinler

Uygulama internet, titreşim ve Android 13 ve üzerindeki cihazlarda bildirim
izni kullanır. Kamera, mikrofon, konum, rehber veya reklam kimliği izni istemez.

## İletişim

Gizlilikle ilgili soru ve talepler için projenin
[GitHub Issues](https://github.com/ahmedfirat21-dotcom/valomagaza/issues)
sayfasından geliştiriciyle iletişim kurulabilir.

## Riot Games bildirimi

Valo Mağaza isn't endorsed by Riot Games and doesn't reflect the views or
opinions of Riot Games or anyone officially involved in producing or managing
Riot Games properties. Riot Games, and all associated properties are trademarks
or registered trademarks of Riot Games, Inc.

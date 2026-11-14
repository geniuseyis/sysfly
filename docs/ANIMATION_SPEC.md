# Animasyon belirtimi

Süreler ve eğriler `lib/core/design_system/motion.dart` içindedir. Video 30 fps olduğu için ölçümlerde ±1 kare (±33 ms) hata payı vardır.

## Navigasyon kapsülü

Videoda Home → Flights geçişinde kapsül merkezinin kat ettiği yol (hedefin yüzdesi):

| Süre | Video | Uygulama |
| --- | --- | --- |
| 33 ms | %14 | %16 |
| 67 ms | %42 | %46 |
| ~100–133 ms | %62 | %72–91 |
| ~133–167 ms | %78 | %91–100 |
| 200 ms | %103 | %103 |
| 233 ms | %106 (tepe) | %104 |

- **Ölçülen:** kapsül tek parça olarak kayar, hareket ederken genişler (en fazla ~%17), hedefi ~%5 aşar ve bar kenarlarına sıkışır.
- **Uygulanan:** sönümlü yay — kütle 1, sertlik 400, sönüm 28. Hız ve konum korunarak yeniden hedeflendiği için hızlı art arda dokunuşlarda kopmaz.
- **Fark:** videoda aşım yaklaşık 0,3 sn boyunca yerinde kalıp sonra yavaşça oturuyor; uygulamada 350 ms içinde oturuyor. Kayıtta bir kare tekrarlandığı için orta bölümdeki ölçümler kesin değil.
- İkon ve etiket rengi, beyaz ve dolu bir kopyanın kapsül biçiminde kırpılmasıyla değişir; yani renk tam kapsülün kapladığı yerde döner.

## Cam ve mercek

- Bar: gerçek kırılma yapan cam (`liquid_glass_renderer`, Impeller gerekir): bulanıklık 9, kalınlık 18, beyaz ton %66.
- Kapsül sürüklenince 150 ms içinde şeffaf merceğe dönüşür: dinlenme boyutunun 1,32 katı, altındaki ikonları büker; bar %3 büyür. Bırakılınca en yakın sekmeye yayla oturur.
- Impeller olmayan ortamlarda (testler, web) bulanık ve tonlu bir arka plan ile boyanmış mercek kullanılır.

## Splash (toplam 3,1 sn, ölçüldü)

| Aralık | Olay |
| --- | --- |
| 0,1–0,45 sn | Logo belirir |
| 0,45–1,6 sn | Uçuş izi çizilir, ucunda uçak ilerler |
| 1,55–1,85 sn | Uçak yerini dört köşeli yıldıza bırakır |
| 1,75–2,05 sn | Slogan belirir |
| 3,1 sn | Login'e 500 ms'lik geçiş |

## Yükleme katmanı (ölçüldü)

- 170 ms'de belirir, 260 ms'de kaybolur; arkası bulanıklaşır.
- Uçak saat yönünde döner, bir tur 2,4 sn; arkasında küçülen yedi nokta.
- Gerçek işlem süresince görünür; en az 1,4 sn ekranda kalır.

## Diğer

| Öğe | Süre | Durum |
| --- | --- | --- |
| Sekme içeriği geçişi (çapraz solma) | 200 ms | ölçüldü |
| Alt sayfa açılışı | 380 ms | tahmin |
| Sayfa geçişi (iOS kaydırma) | sistem | tahmin |
| Basma tepkisi (0,97 ölçek) | 140 ms | tahmin |
| Koltuk seçimi (büyüyerek oturma) | 320 ms | tahmin |

iOS'taki **Hareketi Azalt** ayarı açıkken kapsül, mercek, splash ve başarı animasyonu doğrudan son durumuna geçer.

# Tasarım sistemi

Tüm değerler `lib/core/design_system/` altında tek yerde durur; ekranlar kendi rengini veya ölçüsünü üretmez.

| Dosya | İçerik |
| --- | --- |
| `colors.dart` | `SysflyColors` |
| `gradients.dart` | `SysflyGradients` |
| `typography.dart` | `SysflyTypography` |
| `tokens.dart` | `SysflySpacing`, `SysflyRadius`, `SysflyShadows` |
| `motion.dart` | `SysflyMotion` |
| `iconography.dart` | `SysflyIcons` |
| `sysfly_icon.dart` | `SysflyIcon` çizim bileşeni |

## Renkler (referanstan ölçüldü)

| Kullanım | Değer |
| --- | --- |
| Başlık gradyanı (üst → alt) | `#121443` → `#1A2264` → `#202E7E` |
| Buton gradyanı (sol → sağ) | `#181D5A` → `#1A266E` → `#2D41A7` |
| Kapsül ve bilet butonu | `#171E61` → `#2D3EA8` |
| Splash (üst → alt) | `#0C0E2B` → `#131545` → `#243488` |
| Seçili durum | `#24348A` |
| Sayfa zemini | `#F2F3FA` |
| Alan zemini | `#F3F4FB` |
| Ana metin | `#05060F` |
| İkincil metin | `#555764` |
| Soluk metin | `#858896` |
| Başlık baloncuğu | `#7D90F3` %25 (başlık üzerinde `#354293` verir) |
| Başarı | `#1FB57E` |
| Ekstra bacak mesafeli koltuk | `#C4EDFB`, kenar `#63C9EA` |

## Tipografi

Gövde fontu **Plus Jakarta Sans** (400–800), marka yazısı **Playball**; ikisi de OFL lisanslı ve `assets/fonts/` içinde.

| Stil | Boyut / kalınlık |
| --- | --- |
| Ekran başlığı ("Where Are You Going?") | 25 / 700 |
| Sayfa başlığı ("Choose your fare") | 26 / 700 |
| Bölüm başlığı | 19 / 700 |
| Havalimanı kodu | 29 / 700 |
| Fiyat | 27 / 700 |
| Gövde | 14,5 / 600 |
| Açıklama | 12,5 / 500 |
| Bilet etiketi ("FROM") | 9,5 / 600, harf aralığı 1,3 |
| Navigasyon etiketi | 11 / 500–600 |

## Ölçüler

- Sayfa kenar boşluğu 20 pt; kart köşesi 28, alan köşesi 18–20, alt sayfa köşesi 32.
- Navigasyon: kenardan 16 pt, bar yüksekliği 62, bilet butonu 60, aralarında 14; kapsül sekmeden 6 pt geniş, bar kenarına 3,5 pt mesafede.
- Koltuk haritası: koltuk 37, aralık 5,5, koridor 41, sıra adımı 52, çıkış sıralarının önünde 16 pt ek boşluk.

## Ortak bileşenler

`lib/shared/widgets/` altında: `SysflyFloatingNavigationBar`, `SysflyNavigationIndicator`, `SysflyTicketActionButton`, `SysflyGradientButton`, `SysflyGlassCard`, `SysflyFlightTicket`, `SysflyBoardingPass`, `SysflyAirportSelector`, `SysflyDatePicker`, `SysflyFlightRouteLine`, `SysflySeatMap`, `SysflySeatWidget`, `SysflyFareCard`, `SysflyPriceSummary`, `SysflyLoadingOverlay`, `SysflySuccessAnimation`, `SysflyNotificationCard`.

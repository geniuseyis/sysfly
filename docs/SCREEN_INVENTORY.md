# Ekran envanteri

| # | Ekran | Dosya | Referans |
| --- | --- | --- | --- |
| 1 | Splash | `features/splash/splash_screen.dart` | video |
| 2 | Login, kayıt, şifre sıfırlama | `features/authentication/` | video, görsel 1 |
| 3 | Home | `features/home/home_screen.dart` | video, görsel 1 |
| 4 | Havalimanı seçimi | `features/airports/airport_sheet.dart` | görsel 3 |
| 5 | Takvim | `shared/widgets/sysfly_date_picker.dart` | görsel 3 |
| 6 | Uçuş sonuçları | `features/flight_search/flight_results_screen.dart` | görsel 3 |
| 7 | Filtre ve sıralama | `features/flight_filters/filter_sheet.dart` | görsel 8 |
| 8 | Fare seçimi | `features/booking/fare_screen.dart` | görsel 4 |
| 9 | Yolcular | `features/booking/passengers_screen.dart` | görsel 4 |
| 10 | Koltuk haritası | `features/seats/seats_screen.dart` | görsel 4, 5 |
| 11 | Ekstralar | `features/seats/seats_screen.dart` (alt bölüm) | görsel 5 |
| 12 | İnceleme ve ödeme | `features/checkout/review_screen.dart` | görsel 6 |
| 13 | Ödeme yöntemi | `features/checkout/widgets/payment_sheets.dart` | görsel 6 |
| 14 | Rezervasyon yükleme | `shared/widgets/sysfly_loading_overlay.dart` | görsel 7 |
| 15 | Rezervasyon onayı | `features/checkout/confirmation_screen.dart` | görsel 7 |
| 16 | Seyahat detayı | `features/my_flights/trip_details_screen.dart` | görsel 7 |
| 17 | My Flights | `features/my_flights/my_flights_screen.dart` | video, görsel 2 |
| 18 | Flight Status | `features/flight_status/flight_status_screen.dart` | video, görsel 2 |
| 19 | Takip edilen uçuşlar | Flight Status içinde | görsel 8 |
| 20 | Bildirimler | `features/notifications/notifications_screen.dart` | görsel 8 |
| 21 | Profile ve alt sayfaları | `features/profile/` | video, görsel 2 |

## Akış

Home → Sonuçlar → Fare → Yolcular → Koltuk ve ekstralar → İnceleme ve ödeme → Onay → Seyahat detayı.

Tüm seçimler tek bir taslakta (`BookingDraft`) tutulur; geri dönüldüğünde kaybolmaz. Fiyat her ekranda aynı fonksiyondan (`priceOf`) hesaplanır. Onaylanan rezervasyon My Flights ve Flight Status ekranlarında görünür.

## Demo olan kısımlar

Veri katmanı `lib/data/repositories/` altındaki arayüzlerin arkasındadır; gerçek servisler `providers.dart` içinde değiştirilerek bağlanır.

- Giriş: bellek içi hesaplar. Google ve Apple ile giriş yapılandırılmadığı için bunu söyleyen bir mesaj verir.
- Uçuşlar, koltuklar, uçuş durumu, bildirimler: örnek veri. Tarihler 3 Eylül 2026 19:30'a sabitlidir (`DemoClock`).
- Ödeme: simülasyon; para çekilmez. Sonu `0002` olan kart bilerek reddedilir.
- Kartlardan yalnızca marka, son dört hane ve son kullanma tarihi tutulur.
- E-bilet PDF olarak, takvim `.ics` olarak paylaşılır; e-posta gönderilmez.

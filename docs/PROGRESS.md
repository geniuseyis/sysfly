# Durum

Son güncelleme: 14 Kasım 2026

## Tamamlananlar

- 21 ekranın tamamı ve aralarındaki akış.
- Tasarım sistemi, ortak bileşenler, demo veri katmanı, Riverpod + go_router.
- Navigasyon barı: yay fizikli kapsül, gerçek cam ve sürükleme merceği.
- Referansla yan yana karşılaştırma: video ekranları ve sekiz görseldeki 17 ekran.
- Uygulama adı ve dikey kilit (iOS `Info.plist`, Android manifest).
- Gerçek havalimanı verisi: 233 ülkede 4007 havalimanı (`assets/data/airports.tsv`).
- Yedi dil: İngilizce, Türkçe, Almanca, Fransızca, İspanyolca, Rusça, Arapça (Profil → Dil).
- THY örnek verisi: İstanbul çıkışlı rotalar, EcoFly / ExtraFly / PrimeFly tarife aileleri, THY tarzı yolcu formu (unvan, T.C. kimlik, Miles&Smiles; iç hatlarda pasaport isteğe bağlı).
- Güvenlik: Android yedekleme kapalı, sürüm imzası `key.properties` ile, R8 küçültme, hassas alanlarda klavye önerisi kapalı.
- Uygulama ikonu (Android ve iOS) ve README görselleri.

## Doğrulama

| Kontrol | Sonuç |
| --- | --- |
| `flutter analyze` | Sorun yok |
| `flutter test` | 80 testin 80'i geçti |
| `flutter test integration_test/app_test.dart` (Android emülatör) | Geçti |
| Android derleme ve çalıştırma (Pixel 6 Pro emülatör) | Çalışıyor |
| Android sürüm derlemesi (`flutter build apk --release`) | Başarılı |
| iOS derleme | **Doğrulanmadı** — Windows'ta yapılamaz, Mac ve Xcode gerekir |

Testler: `test/unit` (fiyat, filtre, tarife, doğrulayıcılar, PDF), `test/widgets` (navigasyon barı), `test/flows` (aramadan My Flights'a uçtan uca rezervasyon), `test/visual` (20 ekranın görüntü karşılaştırması), `test/l10n` (çeviri tablosu, çeviri motoru, havalimanı kataloğu, her dilde ekranların taşmadan çizilmesi).

## Açık kalanlar

- iOS'ta derleme ve gerçek cihazda cam efektinin, haptic'in ve güvenli alanların kontrolü.
- Kapsülün aşım sonrası oturma süresi videodakinden kısa (bkz. `ANIMATION_SPEC.md`).
- Splash ve yükleme animasyonlarının ara kareleri videoyla kare kare karşılaştırılmadı; zamanlamalar ölçümden alındı.
- Çok şehirli (multi-city) arama yok; seçilince bunu söyleyen bir sayfa açılır.
- Gidiş-dönüşte dönüş uçuşu için koltuk seçimi yok; check-in'de atanır.

## Çeviri ve veri hakkında

- Ekranlar İngilizce yazılıdır; metin çizilirken seçili dile çevrilir (`lib/core/l10n/`). Yeni bir metin eklenince `translations.dart` dosyasına altı dildeki karşılığı eklenir; eklenmezse İngilizce görünür.
- Arapçada metinler sağdan sola okunur ama ekran yerleşimi aynalanmaz (soldan sağa kalır).
- Saatler tüm dillerde 12 saatlik (AM/PM) biçimdedir; ekran okuyucu etiketleri ve paylaşılan PDF/takvim dosyaları İngilizcedir.
- Çeviriler makine yardımıyla hazırlandı; ana dili konuşan biri tarafından gözden geçirilmedi.
- Havalimanları OurAirports (kamu malı), saat dilimleri OpenFlights (Open Database License), ülke adları Unicode CLDR verisinden üretilir: `node tool/build_airport_data.js`. Uçuşlar ve fiyatlar yine örnek veridir.
- Havalimanı listesinde elle çizilen 11 bayrak dışındaki ülkeler emoji bayrakla gösterilir.

## Çalıştırma

```
flutter emulators --launch Pixel_6_Pro
flutter run
```

Giriş için herhangi bir e-posta ve en az 6 karakterlik şifre yeterlidir.

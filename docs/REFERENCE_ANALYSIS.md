# Referans analizi

Kaynaklar `references/` altında: 21 saniyelik ekran kaydı (716×930, 30 fps, 629 kare) ve her biri üç telefon içeren sekiz görsel.

## Ölçüm yöntemi

- Videodaki her kare PNG olarak çıkarıldı. Telefon ekranı karede x 69–406, y 105–839 aralığında; 440 pt genişliğindeki ekrana (iPhone 17 Pro Max, 440×956) göre ölçek **0,765 px/pt**.
- Görsellerde her telefon ekranı 244 px genişliğinde; ölçek **0,555 px/pt**.
- Renkler karelerden piksel örnekleyerek alındı. Video H.264 sıkıştırmalı olduğu için kanal başına yaklaşık ±3 hata payı var; görseller JPEG olduğu için ince yazılarda renkler olduğundan açık okunur.
- Karşılaştırma: her ekran Flutter testinde 440×956 olarak çizildi (`test/visual/`), referansla aynı ölçeğe getirilip yan yana kondu.

## Videonun akışı

| Zaman | Kare | Ne oluyor |
| --- | --- | --- |
| 0,0–1,0 sn | 1–30 | Boş simülatör |
| 1,0–4,5 sn | 31–135 | Splash: logo belirir, uçuş izi çizilir, yıldız parlar, slogan gelir |
| 4,5–11,0 sn | 136–330 | Login ekranı; e-posta alanına odaklanılır |
| 11,0–14,8 sn | 331–445 | "Logging you in" yükleme katmanı |
| 14,8–16,1 sn | 446–485 | Home |
| 16,1–17,0 sn | 486–511 | Home → Flights |
| 17,0–17,7 sn | 512–532 | Flights → Status |
| 17,7–18,5 sn | 533–556 | Status → Profile |
| 18,5–19,4 sn | 557–582 | Kapsül sürüklenerek Profile → Home (cam mercek) |
| 19,4–21,0 sn | 583–629 | Home |

## Doğrulananlar ve tahminler

**Ölçülerek doğrulananlar:** ekran yerleşimleri, bar ve kapsül ölçüleri, renk paleti, splash ve yükleme zamanlamaları, sekme geçiş süresi, kapsülün hareket eğrisinin genel biçimi.

**Tahmin edilenler:** videoda görünmeyen her etkileşim (alt sayfaların açılışı, buton basma tepkisi, koltuk seçimi, takvim ayı geçişi). Bunlar aynı tasarım diline uygun, kısa ve sade tutuldu.

**Referanstan bilinçli sapmalar:**

- Login illüstrasyonu ve profil fotoğrafı: özgün dosyalar elde olmadığı için vektör olarak yeniden çizildi.
- Marka yazısı: referanstaki el yazısı fonta en yakın açık lisanslı font (Playball) kullanıldı.
- İkonlar: referansla eşleşen Hugeicons (rounded stroke) ailesi; seçili durumdaki dolu ikonlar aynı çizimlerin içi doldurularak üretildi.

// Builds the README images and the launcher icons from the visual test renders.
//
//   flutter test test/visual --update-goldens
//   npm install --no-save sharp
//   node tool/build_readme_screens.js
//
// Inputs:  test/visual/goldens/*.png (440 x 956 pt screens rendered at 2x)
//          docs/screenshots/source/*.png (screens captured on the emulator)
// Outputs: docs/screenshots/*.png, Android mipmaps, iOS AppIcon set.
const fs = require('fs');
const path = require('path');
const sharp = require('sharp');

const root = path.join(__dirname, '..');
const goldens = path.join(root, 'test/visual/goldens');
const captured = path.join(root, 'docs/screenshots/source');
const out = path.join(root, 'docs/screenshots');

const W = 2400;
const H = 1350;
const escape = (s) => s.replace(/&/g, '&amp;').replace(/</g, '&lt;');

function screen(name) {
  const own = path.join(captured, `${name}.png`);
  return fs.existsSync(own) ? own : path.join(goldens, `${name}.png`);
}

/// One screen in a rounded device outline with a soft shadow.
async function phone(name, height) {
  const width = Math.round(height * 440 / 956);
  const radius = Math.round(width * 0.11);
  const body = await sharp(screen(name)).resize(width, height, { fit: 'cover', position: 'top' }).png().toBuffer();
  const mask = Buffer.from(`<svg width="${width}" height="${height}"><rect width="${width}" height="${height}" rx="${radius}" fill="#fff"/></svg>`);
  const clipped = await sharp(body).composite([{ input: mask, blend: 'dest-in' }]).png().toBuffer();
  const pad = 40;
  const frame = Buffer.from(`<svg width="${width + pad * 2}" height="${height + pad * 2}">
    <defs><filter id="s" x="-20%" y="-20%" width="140%" height="140%"><feGaussianBlur stdDeviation="16"/></filter></defs>
    <rect x="${pad}" y="${pad + 14}" width="${width}" height="${height}" rx="${radius}" fill="#050716" opacity="0.45" filter="url(#s)"/>
    <rect x="${pad - 5}" y="${pad - 5}" width="${width + 10}" height="${height + 10}" rx="${radius + 5}" fill="#0b0e26"/>
  </svg>`);
  return sharp(frame).composite([{ input: clipped, left: pad, top: pad }]).png().toBuffer();
}

function background(title, subtitle) {
  return Buffer.from(`<svg width="${W}" height="${H}">
    <defs>
      <linearGradient id="g" x1="0" y1="0" x2="1" y2="1">
        <stop offset="0" stop-color="#0C0E2B"/><stop offset="0.55" stop-color="#151C57"/><stop offset="1" stop-color="#25369A"/>
      </linearGradient>
      <radialGradient id="glow" cx="0.82" cy="0.18" r="0.6">
        <stop offset="0" stop-color="#4D7BFF" stop-opacity="0.35"/><stop offset="1" stop-color="#4D7BFF" stop-opacity="0"/>
      </radialGradient>
    </defs>
    <rect width="${W}" height="${H}" fill="url(#g)"/>
    <rect width="${W}" height="${H}" fill="url(#glow)"/>
    <text x="110" y="560" font-family="Segoe UI, Helvetica, Arial, sans-serif" font-size="72" font-weight="700" fill="#FFFFFF">${escape(title)}</text>
    ${subtitle.map((line, i) => `<text x="110" y="${650 + i * 52}" font-family="Segoe UI, Helvetica, Arial, sans-serif" font-size="36" fill="#C9D3FF">${escape(line)}</text>`).join('')}
  </svg>`);
}

async function panel(file, title, subtitle, screens) {
  const height = 1000;
  const phones = await Promise.all(screens.map((s) => phone(s, height)));
  const meta = await sharp(phones[0]).metadata();
  const gap = -30;
  const totalWidth = phones.length * meta.width + (phones.length - 1) * gap;
  const left = W - totalWidth - 60;
  const top = Math.round((H - meta.height) / 2);
  await sharp(background(title, subtitle))
    .composite(phones.map((buffer, i) => ({ input: buffer, left: left + i * (meta.width + gap), top })))
    .png({ compressionLevel: 9, palette: true, quality: 90 })
    .toFile(path.join(out, file));
  console.log('wrote', file);
}

async function hero() {
  const names = ['splash', 'home', 'my_flights', 'flight_status', 'profile'];
  const height = 1060;
  const phones = await Promise.all(names.map((s) => phone(s, height)));
  const meta = await sharp(phones[0]).metadata();
  const gap = -18;
  const totalWidth = phones.length * meta.width + (phones.length - 1) * gap;
  const left = Math.round((W - totalWidth) / 2);
  const bg = Buffer.from(`<svg width="${W}" height="${H}">
    <defs><linearGradient id="g" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#0C0E2B"/><stop offset="1" stop-color="#25369A"/></linearGradient></defs>
    <rect width="${W}" height="${H}" fill="url(#g)"/></svg>`);
  await sharp(bg)
    .composite(phones.map((buffer, i) => ({ input: buffer, left: left + i * (meta.width + gap), top: Math.round((H - meta.height) / 2) + (i % 2 === 0 ? 30 : -30) })))
    .png({ compressionLevel: 9, palette: true, quality: 90 })
    .toFile(path.join(out, 'hero.png'));
  console.log('wrote hero.png');
}

async function icons() {
  const art = path.join(goldens, 'readme_app_icon.png');
  // README icon with rounded corners.
  const mask = Buffer.from('<svg width="512" height="512"><rect width="512" height="512" rx="112" fill="#fff"/></svg>');
  await sharp(art).resize(512, 512).composite([{ input: mask, blend: 'dest-in' }]).png().toFile(path.join(out, 'app-icon.png'));

  // Android legacy launcher icons, rounded like the platform's own.
  const android = { mdpi: 48, hdpi: 72, xhdpi: 96, xxhdpi: 144, xxxhdpi: 192 };
  for (const [density, size] of Object.entries(android)) {
    const m = Buffer.from(`<svg width="${size}" height="${size}"><rect width="${size}" height="${size}" rx="${size * 0.22}" fill="#fff"/></svg>`);
    await sharp(art).resize(size, size).composite([{ input: m, blend: 'dest-in' }]).png()
      .toFile(path.join(root, `android/app/src/main/res/mipmap-${density}/ic_launcher.png`));
  }

  // iOS: square, opaque; the system applies the mask.
  const set = path.join(root, 'ios/Runner/Assets.xcassets/AppIcon.appiconset');
  for (const file of fs.readdirSync(set).filter((f) => f.endsWith('.png'))) {
    const { width } = await sharp(path.join(set, file)).metadata();
    const buffer = await sharp(art).resize(width, width).flatten({ background: '#0C0E2B' }).png().toBuffer();
    fs.writeFileSync(path.join(set, file), buffer);
  }
  console.log('wrote launcher icons');
}

(async () => {
  fs.mkdirSync(out, { recursive: true });
  await icons();
  await hero();
  await panel('01-search.png', 'Arama', ['233 ülkede 4.000\'den fazla', 'gerçek havalimanı; tek yön veya', 'gidiş-dönüş, tarih aralığı.'], ['home', 'airport_sheet', 'date_picker']);
  await panel('02-results.png', 'Sonuçlar ve tarife', ['Uçuşları filtrele ve sırala;', 'THY uçuşlarında EcoFly, ExtraFly', 've PrimeFly arasından seç.'], ['results', 'filter_sheet', 'readme_fare_tk']);
  await panel('03-passengers.png', 'Yolcular ve koltuk', ['T.C. kimlik ve Miles&Smiles', 'alanlarıyla yolcu formu,', 'etkileşimli kabin haritası.'], ['readme_passengers_tk', 'readme_passenger_form_tk', 'seats_top']);
  await panel('04-checkout.png', 'Ekstralar ve ödeme', ['Bagaj, esnek bilet, sigorta;', 'tek kaynaktan hesaplanan', 'fiyat ve ödeme yöntemleri.'], ['seats_extras', 'review_bottom', 'payment_sheet']);
  await panel('05-trip.png', 'Onay ve seyahat', ['Rezervasyon onayı, biniş kartı,', 'check-in, PDF e-bilet', 've takvime ekleme.'], ['booking_loading', 'confirmation', 'trip_details']);
  await panel('06-status.png', 'Uçuş durumu', ['Canlı pano, takip edilen', 'uçuşlar ve uçuş bildirimleri.'], ['flight_status', 'tracked_flights', 'notifications']);
  await panel('07-navigation.png', 'Navigasyon', ['Yay fizikli kapsül, gerçek', 'kırılmalı cam bar; sürüklenince', 'cam merceğe dönüşür.'], ['nav_rest', 'my_flights', 'flight_status']);
  await panel('08-languages.png', 'Yedi dil', ['Türkçe, İngilizce, Almanca,', 'Fransızca, İspanyolca, Rusça', 've Arapça.'], ['readme_home_tr', 'readme_home_de', 'readme_language_de']);
})().catch((e) => { console.error(e); process.exit(1); });

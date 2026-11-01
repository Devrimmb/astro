# AstroApp — Tasarım ve Animasyon Yol Haritası

Kalan tasarım işleri; öncelik sırasına göre. Durum sütunu: ☐ yapılmadı · ◐ kısmen · ☑ bitti.
Tamamlananlar en altta referans için duruyor.

Genel kurallar: Liquid Glass dili (`AstroTheme` token'ları, `GlassCard`, `glassButton`), tüm hareketler
`accessibilityReduceMotion` ile kapanabilir, ödeme dili yalnızca "Doğum Haritanı Aç" (PRO/abonelik yok).
Dağıtım hedefi iOS 17: iOS 18+ API'leri (TextRenderer, zoom geçişi, MeshGradient) kullanan her maddede
iOS 17 davranışı da yazılı olmalı.

---

## A. Öncelikli

### A3. Yazılarak gelen yorumlar ☐
Yorum metinleri (doğum haritası gezegen yorumu penceresi, tarot/katina/rün/tanrı kartı panelleri, günlük yorum) daktilo gibi
değil, kelime kelime belirerek gelir. iOS 18+ `TextRenderer` ile; iOS 17'de düz göster.
- `MarkdownTextView` üstüne opsiyonel `revealed: Bool` bayrağı.
- Hız: ~40 kelime/sn, dokununca anında tamamlanır. Paylaşım görsellerinde kapalı.

---

## B. Sayfa bazlı sahneler

### B1. Transit haftası — canlı akış ☐
`TransitView` hafta şeridinde gün seçildiğinde dış halka gezegenleri yeni konumlarına yaylanır
(`TransitBiWheelView` → `LiveChartWheelModel` tabanlı bi-wheel). Şeritte parmağı sürükleyince gezegenler
gerçek zamanlı akar; retro gezegenler geri gider.
- Vurgu modu bugün var (natal gezegene dokun → gelen transitler parlar); canlı akış yok.

### B2. Ay evresi — sürüklenebilir Ay ☐
- Evre sınırlarını geçerken `AstroHaptics.selection()` çal (haptik katmanı hazır).
`MoonPhaseView`'daki `MoonDisc` yatay sürüklemeyle ileri-geri evre değiştirir; altında tarih ve evre adı
akar; bırakınca en yakın güne yaylanır. Haptik: evre sınırlarında tık.

### B3. Splash → anasayfa geçişi ☐
Splash'taki logo/çark, `matchedGeometryEffect` ile anasayfadaki Ay diskine ya da "bugünün gökyüzü"
kartına küçülerek oturur. Tek kesintisiz hareket; yıldızlar zemin olarak kalır.

### B4. Paywall — "harita uyanıyor" ☐
`PaywallView`'da bulanık ve gri bir çark; "Doğum Haritanı Aç" düğmesine dokununca (satın alma başarılı)
çark renklenir, gezegenler yerleşir, açılar çizilir (hesaplama sahnesinin kısa hali).

### B5. Sayı ve halka animasyonları ◐
Skorlar, yüzdeler, element dengesi çubukları 0'dan hedefe akar; `ScoreRing` dolarken izlenir.
- Bugün: yaşayan çarkta Büyük Üçlü kartı nabız atıyor, sayılar statik.
- Yapılacak: `ScoreRing`, `DotMeter`, element yüzdeleri, synastry skoru.

### B6. Zoom geçişleri ☐
Liste → detay geçişlerinde `navigationTransition(.zoom)` (iOS 18+): gezegen satırından yorum sheet'ine
(`PlanetInterpretationSheet`; zoom sheet'lerde de çalışır), geçmiş okuma satırından sonuç sayfasına,
tarot kategorisinden deste çarkına.
- iOS 17'de: sistemin varsayılan push / sheet geçişi.

---

## C. Zemin ve doku

### C1. MeshGradient aurora ☐
`SubtleStarsBackground` üstüne çok yavaş hareket eden lavanta-mavi `MeshGradient` (iOS 18+) katmanı;
sayfaya göre renk ağırlığı değişir (doğum haritası lavanta, transit mavi, kart falları şarap/ahşap tonu).
Pil için 20 fps ve `reduceMotion` ile sabit.
- iOS 17'de: katman yok, yalnızca `SubtleStarsBackground`.

### C2. Metal shader dokunuşları ☐
`.colorEffect` / `.layerEffect`: kart yüzünde ışık kayması (`DeckSheen` yerine gerçek shader), çark
merkezinde hafif ısı dalgası, splash'ta yıldız kayması. Önce bir tane deneyip pil ölçülür.

### C3. Doğum anı gerçek gökyüzü ☐
Sonuç sayfasının zemini o kişinin doğum anındaki gerçek yıldız konumlarından üretilir
(`FixedStarCalculator.calculatePositions(date:)` + parlak yıldız kataloğu). Statik üretilir, paylaşım
kartında da kullanılır.

---

## D. Platform özellikleri

### D1. Video paylaşım ☐
Hesaplama sahnesinin ya da kart çevirmenin 3-5 sn'lik kaydı (`ImageRenderer` kare dizisi → AVAssetWriter).
Instagram hikâye boyutu (1080×1920). Yeni bağımlılık gerekmiyor.

### D2. Live Activity ☐
Kilit ekranı / Dynamic Island: o günün Ay evresi + gezegen saati; transit yoğun günlerde bildirim.
`AstroWidget` hedefine `ActivityKit` eklenir; veri `SharedDefaults` üzerinden.

### D3. Widget kalanları ◐
- `MoonPhaseWidget` hâlâ SF Symbol ay; Kozmik Durum'daki gerçek Ay diskine (`WidgetSkyWheel` merkezi) geçirilecek.
- `AstroCalendarWidget` yeni dile taşınmadı.

---

## E. Temizlik ve belge

- Uygulama ikonu: karar kullanıcıda; mevcut ikon kalıyor. ☐
- "Yeni kişi" manuel giriş ekranını küçük ekranda (iPhone SE) ve büyük yazı boyutunda (Dynamic Type) dene;
  çark en fazla %45'e küçülüyor, sheet içeriğe göre uzuyor. ☐ (kullanıcı cihazda deneyecek)

---

## F. Ürün kararı bekleyenler

- Silinen geçmiş okuma, o kişinin haritasını yeniden açmak için yeni harita hakkı (ödeme) gerektiriyor; silme
  uyarısı bunu söylüyor. Kullanıcıyı üzebilir → "okumayı geri yükle" ya da silinen okumayı satın alma kaydı
  olarak saklayıp yalnızca listeden gizlemek düşünülebilir. ☐

---

## Tamamlananlar (referans)

- ☑ Liquid Glass tasarım yenilemesi — token'lar, `GlassCard`, `AstroComponents`, `SegmentedGlass`, `MoonDisc`,
  tüm ana sayfalar; "Pro/abonelik" dili kaldırıldı.
- ☑ Deste çarkı — tarot/katina/rün/tanrı kartı için tek motor (`DeckWheel/`), ortak akış `DeckReadingFlow`.
- ☑ Kozmik Durum widget'ı — gerçek boylamlı gökyüzü çarkı, Ay evresi, açılar, gezegen saati; burç glifleri metin sunumu.
- ☑ Yaşayan doğum haritası çarkı — `LiveWheel/` motoru, `BirthChartView` (ana/hesaplama/sonuç), manuel giriş
  sheet'i canlı Büyük Üçlü, gezegen vurgu modu (transit bi-wheel dahil). Çark yönü standartlaştırıldı.
- ☑ "Yeni kişi" manuel giriş düzeni (1 Kasım 2026) — çark üstte sabit ve kalan alana göre boyutlanıyor; sheet
  kaydırmasız, içeriğe göre yükseklik (isim başlık satırında, ülke/şehir yan yana, `LocationPickerView(compact:)`).
- ☑ Doğum haritası ana ekranı (1 Kasım 2026) — "Yeni kişi" kartı solda sabit, kişiler yanında kayıyor; geçmiş
  okumalar "Düzenle" ya da uzun basma ile onaylı siliniyor; başlık–çark çakışması giderildi.
- ☑ Sonuç sayfası sadeleşti (1 Kasım 2026) — 3 sekme (Harita / Gezegenler / Açılar); gezegen penceresinde yalnızca
  gezegen × ev × burç yorumu; burç yansıması ve Modalite Dengesi kartları Harita sekmesinde.
- ☑ Hayat Döngüleri (1 Kasım 2026) — `LifeCycleCalculator` (Jüpiter/Satürn/Uranüs/Neptün/Plüton/Kiron/Ay Düğümü,
  90 yıl, retro geçişleri gruplu), `life_cycles.json` (13 tür, gezginde), Astroloji sekmesinde sayfa, anasayfada
  "Sıradaki dönemecin" kartı; ayrıntılı yorum ödenmiş harita yoksa ödüllü reklamla.
- ☑ Kozmik kimlik hikâyesi (1 Kasım 2026) — 5 sayfa (kapak, Büyük Üçlü, element, haritanın imzası, sıradaki
  dönemeç), 1080×1920 görsel paylaşım (tek/tümü); sonuç sayfasında düğme, doğum gününe ±7 gün kala anasayfa kartı.
- ☑ Anı Haritası (1 Kasım 2026) — `MemoryStore` (kişi başına önemli günler, geçmiş + planlanan, isteğe bağlı saat),
  anı detayında doğum haritası + o günün gökyüzü (`TransitBiWheelView`), o tarihte etkin hayat döngüleri, kanonik
  geçmiş/gelecek kipli transit yorumu (`DailyCosmicCoach.memoryInterpretation`; saat yoksa Ay açıları gizli);
  anılar Hayat Döngüleri zaman çizgisinde de görünür. Yorumlar ödenmiş harita yoksa ödüllü reklamla.
- ☑ Synastry iç içe çarklar (1 Kasım 2026) — `SynastryWheelStage`: dış halka (burçlar + 2. kişi) sağdan, iç halka
  (evler + 1. kişi) soldan dönerek gelip oturur; açılar dar orb önce tek tek çizilir (her açıda hafif haptik), "Aspect
  Bazlı Uyum" `ScoreRing` içinde 0'dan sayar, bitişte orta haptik. Dokununca sahne atlanır; sonra bir gezegene dokunmak
  yalnızca onun karşı haritaya açılarını bırakır (iki halkadan da seçilebilir). Hareket azaltma açıksa doğrudan son hal.
- ☑ Haptik koreografisi (1 Kasım 2026) — `Design/AstroHaptics.swift` tek katman: `selection`, `tick`, `tap`,
  `success`, `cardEdge`/`cardSettle`, CoreHaptics desenleri `breath` (splash → anasayfa) ve `scoreFinale` (yedekli).
  Deste çarkı, yaşayan çark, manuel giriş, kişi seçimi, segment/transit tarih seçimi buraya taşındı; kart çevirmede
  kenar tıkı + yerleşme; Synastry skoru hızlanarak sayar, 5 puanda bir sıklaşan tık, sonunda güçlü vuruş.
  Ayarlar → "Titreşimler" anahtarı (`hapticsEnabled`) hepsini kapatır; `astroFeedback` modifier'ı da ona uyar.
- ☑ Temizlik (1 Kasım 2026) — "Tüm özellikler" (`allFeaturesID`) ürünü kaldırıldı (hiç satılmamıştı): `StoreManager`
  yalnızca `natalChartID` yükler, `EntitlementManager.hasFullAccess` silindi, yetkiler yalnızca doğum haritası/kredi,
  `PaywallView` tek ürün, `Products.storekit` tek ürün. `Localizable.xcstrings` içinden kodda geçmeyen 52 eski metin
  silindi (PRO, eski fal ekranları, eski rün/tanrı ekranı metinleri). `astroapp_design_2026.html` güncellendi:
  PRO/kademe dili → tek ürün + ödüllü reklam, Ayarlar'da Titreşimler, yeni bölüm 13 "Hareket ve dokunuş".
- ☑ Alt menü kaydırınca küçülmüyor (`tabBarMinimizeBehavior(.never)`); Astroloji sekmesinden "Astroloji Rehberi"
  kartı kaldırıldı (1 Kasım 2026).

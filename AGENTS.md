# AGENTS.md

This file provides guidance to Codex (Codex.ai/code) when working with code in this repository.

## Project Overview

AstroApp is a Turkish-language iOS astrology app built with SwiftUI. It's in early development (scaffold stage) with a comprehensive roadmap in `astrology-roadmap.md`. The app will include natal chart calculation, daily horoscopes, tarot, compatibility analysis, and moon phases.

## Build & Run

```bash
# Build
xcodebuild -project AstroApp.xcodeproj -scheme AstroApp -sdk iphonesimulator build

# Run tests (when added)
xcodebuild -project AstroApp.xcodeproj -scheme AstroApp -sdk iphonesimulator test
```

- **Bundle ID:** com.duygubal.AstroApp
- **Deployment Target:** iOS 17.0+
- **Xcode:** 26.3+

## Architecture

The project follows a feature-based MVVM structure as defined in the roadmap:

- **App/** — Entry point (`AstroAppApp.swift`), global state, root navigation
- **Core/** — Shared engines and services
  - `Ephemeris/` — Swiss Ephemeris C bridge, planet/house/aspect calculation
  - `Interpretation/` — JSON-based interpretation engine for astrological readings
  - `Monetization/` — StoreKit 2 IAP, Google AdMob, entitlement management
- **Features/** — Each feature is a self-contained module (BirthChart, DailyHoroscope, Tarot, Compatibility, MoonPhase, Profile)
- **Design/** — Theme, glassmorphism modifiers, starfield background, cosmic design system

## Key Dependencies

- **SwissEphemeris** (SPM: `nicklauslitworker/SwissEphemeris`) — Astronomical calculations. Requires C bridging header. GPL licensed — commercial use requires Astrodienst license (~250 CHF).
- **Google Mobile Ads SDK** — AdMob rewarded ads
- **StoreKit 2** — In-app purchases (₺200/₺300/₺400 tiers)

## Concurrency Model

The project uses Swift's structured concurrency with these Xcode settings:
- `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` (main actor by default)
- `SWIFT_APPROACHABLE_CONCURRENCY = YES`

## Localization

- Primary language: **Turkish (tr)**
- Secondary: English (en)
- String catalogs enabled (`STRING_CATALOG_GENERATE_SYMBOLS = YES`)
- All user-facing text must include Turkish translation

## Yorum Gezgini (Interpretation Viewer)

Astroloji, tarot, rün, katina, tanrı kartı vb. tüm yorumlar `AstroApp/Core/Interpretation/Data/` altındaki JSON dosyalarında tutulur. Bu yorumların tek bir yerden incelenebilmesi için `tools/generate_interpretations_html.py` script'i tüm JSON dosyalarını okuyup proje kökünde `interpretations.html` üretir.

**Kural:** Aşağıdaki durumlarda generator script'ini ÇALIŞTIR ve `interpretations.html` dosyasını yeniden üret:

- `AstroApp/Core/Interpretation/Data/` altında **yeni bir JSON dosyası** oluşturduğunda
- Mevcut bir JSON dosyasını **düzenlediğinde** (yorum ekleme/silme/güncelleme)
- Yeni bir kategori (yeni yorum türü) eklediğinde — bu durumda script içindeki `CATEGORIES` listesine de ekle

Komut:

```bash
python3 tools/generate_interpretations_html.py
```

Üretilen `interpretations.html` standalone bir dosyadır (tüm veri gömülüdür); tarayıcıda çift tıklayarak açılır. Sol menüde kategoriler, üstte arama kutusu ve TR/EN dil değişimi vardır. Yeni yorum türü eklendiğinde script'in başındaki `CATEGORIES` tuple'ına `(dosya_adi, görünür_ad, ikon, kısa_açıklama)` formatında bir satır eklemen yeterli.

### Word (.docx) gezegen yorumlarını içe aktarma

Masaüstündeki `~/Desktop/docs/*.docx` dosyaları gezegen/obje yorumlarını "Güneş 2. Evde Koç Burcunda" formatında içerir. Bunları `tools/extract_planet_docs.py` script'i okuyup `AstroApp/Core/Interpretation/Data/planet_house_sign.json` üretir (gezegen × ev × burç üçlü kombinasyonu). Dosyalar baştaki numarayla eşlenir (1=Güneş, 2=Ay, … 7=Satürn, 8=Uranüs, …). Yeni docx eklenince:

```bash
python3 tools/extract_planet_docs.py
python3 tools/generate_interpretations_html.py
```

## Development Phases

The roadmap (`astrology-roadmap.md`) defines 5 phases:
0. Project setup & Swiss Ephemeris integration
1. Core astrology engine (models, calculations, interpretation)
2. UI & birth chart (Canvas drawing, tarot, design system)
3. Monetization (StoreKit 2, AdMob, paywall)
4. Testing & App Store submission

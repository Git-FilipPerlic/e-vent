# Animator App — radne beleške (Flutter)

Dnevnik rada na projektu. Popunjava se posle svakog završenog koraka, ukratko:
šta je urađeno, šta je provereno, šta je sledeće.

Specifikacija projekta je u `CLAUDE.md`. Spisak feature-a iz prethodne React
Native verzije je u `ARCHIVE_ReactNative.md`.

---

## 8. septembar 2026 — start iz nule

- Projekat započet kao čist Flutter starter (`flutter create`), bez prenošenja
  koda iz ranijih pokušaja
- Prethodni pokušaji ostaju kao arhiva u `C:\Users\lefi\Documents\AnimatorApp`
  (React Native implementacija u git commit-u `2d06a89`)
- Preneta samo dokumentacija: `CLAUDE.md`, `ARCHIVE_ReactNative.md`, ove beleške
- Donete odluke: Flutter, `setState` + servis klase, `flutter_map`, Firebase kao
  backend, srpski jezik u UI-u

**Sledeće:** prvi git commit, pa tema i skelet sa 4 taba.

---

## 8. septembar 2026 — git, README, tema i skelet sa 4 taba

- Urađeno:
  - `git init` + prvi commit "Initial Flutter project" (čist starter + dokumentacija)
  - git identitet podešen lokalno za ovaj repo: `Git-FilipPerlic <filipclaude79@gmail.com>`
  - default `README.md` zamenjen kratkim opisom projekta (naziv aplikacije: **e-vent**)
  - telefon SM-A346B (Android 16) uparen bežično preko `adb pair` / mDNS
  - `lib/theme/app_theme.dart` — dark-first tema, `AppSpacing` konstante,
    `kMinTouchTarget = 48`, minimalne dimenzije na svim dugmadima
  - `lib/app.dart` — `EventApp` (MaterialApp, `themeMode: dark`) i `RootNavigation`
    sa 4 taba preko `IndexedStack` (stanje taba se čuva pri prebacivanju)
  - `lib/screens/` — 4 prazna ekrana (Home, Muzika, LED, Lager)
  - `lib/widgets/common/placeholder_body.dart` — privremeni sadržaj taba
  - `lib/main.dart` — samo `runApp(const EventApp())`
- Provereno: `flutter analyze` — No issues found; `flutter test` — 2/2 prolaze
- Otvoreni problemi:
  - donja navigacija je urađena preko `NavigationBar` (Material 3), a ne
    `BottomNavigationBar` kako piše u CLAUDE.md — treba potvrditi ili vratiti
  - prikazno ime aplikacije na telefonu je i dalje `event_app`
    (AndroidManifest / Info.plist još nisu promenjeni na "e-vent")
- Sledeće: modeli (`lib/models/`) i mock servis sa test podacima evt-001..evt-004

---

## Šablon za nove beleške

```
## <datum> — <šta je rađeno>

- Urađeno:
- Provereno (flutter analyze / test na telefonu):
- Otvoreni problemi:
- Sledeće:
```

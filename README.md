# e-vent

Mobilna aplikacija za profesionalne animatore i izvođače koji rade na
proslavama, ceremonijama i događajima (Novi Sad / Srbija). Jedan kod za Android
i iOS, pisan u Flutter-u.

Prikazno ime aplikacije na telefonu je **e-vent**; naziv Dart paketa je
`event_app` (Dart ne dozvoljava crticu u nazivu paketa).

## Šta aplikacija radi

Četiri taba u donjoj navigaciji:

- **Home** — priprema i polazak na događaj: slavljenik, organizator i telefon,
  adresa sa mapom i navigacijom, datum, sat uživo, vreme polaska, vozilo,
  učesnici sa ulogama, status spremnosti, podsetnik i scenario
- **Muzika** — plejer za nastup: lista fajlova, tajmer, fade-in/fade-out
- **LED** — kontrola LED rasvete preko Bluetooth-a: boje, scene, efekti
- **Lager** — checklist opreme po sekcijama, pakovanje pre i raspakivanje posle
  događaja

## Tehnički okvir

- **Flutter** (Android + iOS), stanje preko `setState` + servis klase
- **Dark mode je podrazumevan**, dodirne mete minimum 48 dp
- Podaci prvo iz lokalnog mock servisa, kasnije **Firebase** (Firestore + Auth)
- Mapa preko `flutter_map` (OpenStreetMap), navigacija se otvara u aplikaciji
  koju korisnik već ima na telefonu
- Jezik u aplikaciji je srpski (latinica), kod je na engleskom

## Pokretanje

```powershell
cd "D:\All Work\event_app"
flutter pub get
flutter devices
flutter run
```

Flutter SDK je na `C:\src\flutter\bin`.

## Dokumentacija

- `CLAUDE.md` — specifikacija projekta, donete odluke i pravila rada (izvor istine)
- `APP_NOTES.md` — radne beleške, šta je urađeno i šta je sledeće
- `ARCHIVE_ReactNative.md` — spisak feature-a iz ranije React Native verzije

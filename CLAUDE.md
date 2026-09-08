# Animator App (Performer App) — Flutter

Mobilna aplikacija za profesionalne animatore/izvođače koji rade na proslavama,
ceremonijama i događajima (Novi Sad / Srbija). Jedan kod za Android i iOS.

## Status projekta (8. septembar 2026)

Ovo je **čist Flutter projekat, započet iz nule**. Kreće se od praznog startera —
nijedan fajl koda nije prenet iz ranijih pokušaja.

Istorija projekta ukratko:

1. prva verzija je pisana u **React Native + Expo** (Home tab praktično završen)
2. zatim je prebačena na Flutter, ali u zatrpanom folderu sa ostacima
3. sada se kreće ispočetka, u čistom folderu — jedino što se prenosi je
   **dokumentacija**, ne kod

**Stari folder `C:\Users\lefi\Documents\AnimatorApp` se ne dira** — u njemu je git
istorija sa kompletnom React Native implementacijom (commit `2d06a89`) i služi
samo kao arhiva. Ako zatreba stari kod:

```
cd C:\Users\lefi\Documents\AnimatorApp
git show 2d06a89:App.js                 # pogledati stari fajl
git show 2d06a89:src/screens/HomeScreen.jsx
```

Opis šta je sve bilo urađeno u RN verziji stoji u `ARCHIVE_ReactNative.md`
(prekopiran ovde) — koristi se kao spisak feature-a i redosled prenošenja, ne kao
kod za kopiranje.

---

## Pravila rada za AI asistenta na ovom projektu

Ovaj fajl je izvor istine o projektu. Pre bilo kakve izmene koda pročitati ga u
celini.

1. **Radi u malim koracima.** Jedan feature = jedna izmena = jedna provera.
   Ne pisati pet ekrana odjednom.
2. **Posle svake izmene pokrenuti `flutter analyze`** i prijaviti rezultat.
   Ako ne prolazi, popraviti pre nego što se ide dalje.
3. **Ne dodavati pakete bez pitanja.** Spisak dozvoljenih paketa je u tabeli
   niže. Svaki novi paket je odluka korisnika, ne asistenta.
4. **Ne izmišljati feature-e.** Radi se samo ono što je u spisku (HOME/MUSIC/
   LED/LAGER ID-jevi) ili što korisnik izričito traži. Ako nešto nedostaje u
   specifikaciji — pitati, ne pretpostaviti.
5. **Ne dirati arhitekturu usput.** Struktura foldera i donete odluke niže se
   poštuju; predlog za promenu se iznosi kao predlog, pa se čeka odgovor.
6. **Ne refaktorisati kod koji nije tema trenutnog zadatka.**
7. **Widgeti su "glupi"** — primaju podatke kroz konstruktor, ne zovu servis ni
   bazu. Samo ekrani u `lib/screens/` pričaju sa servisom.
8. **Svako polje može biti prazno.** Za svaki podatak predvideti prazno stanje i
   tekst tipa "Datum nije unet" — aplikacija nikad ne sme da pukne na praznom
   podatku.
9. **Posle završenog feature-a upisati kratku belešku u `APP_NOTES.md`**
   (šta je urađeno, šta je testirano, šta je sledeće).
10. **Objašnjavati jednostavno.** Korisnik nije profesionalni programer — kad se
    predlaže rešenje, reći šta radi i zašto, bez nepotrebnog žargona.

---

## Šta aplikacija radi (nezavisno od tehnologije)

Četiri taba u donjoj navigaciji:

1. **Home** — priprema i polazak na događaj: naziv slavljenika, organizator i
   telefon, adresa sa mapom i navigacijom, datum, sat uživo, vreme polaska,
   izbor vozila, učesnici sa ulogama, status spremnosti, podsetnik, scenario
2. **Muzika** — plejer za nastup: lista fajlova (folder/plejlista), izbor pa
   pokretanje, tajmer, fade-in/fade-out, kasnije queue i EQ
3. **LED** — kontrola LED rasvete preko Bluetooth-a: boje, scene, efekti,
   kasnije sinhronizacija sa muzikom
4. **Lager** — checklist opreme po sekcijama (Tehnika, Animacija, Specijalni
   efekti, Vatreni rekviziti, Svila, Hoop), pakovanje pre i raspakivanje posle
   događaja, limit 90 stavki

Planirano ukupno 101 feature (HOME-001..025, MUSIC-001..026, LED-001..024,
LAGER-001..026).

### Uloge i dozvole

- `glavni` — vodi ekipu; sme da menja logo tima, bira vozilo, upravlja checklistom
- `user` — izvođač; vidi sve, ali bez akcija koje menjaju podatke tima

UI uvek proverava **dozvolu**, nikada naziv uloge direktno — tako backend kasnije
može da doda nove uloge bez menjanja ekrana.

### Pravila dizajna

- **Dark mode je podrazumevan** (čuva noćni vid i bateriju na večernjim nastupima)
- Minimalna dodirna meta **48x48 dp** — rad jednom rukom tokom nastupa
- Visok kontrast, krupan tekst za ključne informacije (naziv, vreme, adresa)
- Minimalistički UI: na ekranu samo ono što treba u tom trenutku

---

## Ciljna struktura projekta (Flutter)

```
lib/
  main.dart              - runApp + inicijalizacija (kasnije Firebase.initializeApp)
  app.dart               - MaterialApp, tema, root sa BottomNavigationBar (4 taba)
  theme/
    app_theme.dart       - dark/light ColorScheme, spacing konstante, minTouchTarget = 48
  models/
    event.dart           - Event, Participant
    vehicle.dart         - Vehicle
    checklist.dart       - ChecklistSection, ChecklistItem
  services/
    event_service.dart   - apstrakcija nad izvorom podataka (interfejs)
    mock_event_service.dart   - lokalni mock podaci za razvoj
    firestore_event_service.dart - Firebase implementacija (kasnije)
    auth_service.dart    - uloge i dozvole (mock -> Firebase Auth)
  screens/
    home_screen.dart
    music_screen.dart
    led_screen.dart
    lager_screen.dart
  widgets/
    home/                - widgeti Home taba (naziv, organizator, adresa, sat...)
    common/              - deljeni widgeti (kartica, prazno stanje, greška + retry)
```

Ključno pravilo koje se prenosi iz RN verzije: **ekrani pričaju sa servisom,
widgeti primaju podatke kroz konstruktor.** Nijedan widget ne poziva bazu
direktno — zato zamena mock servisa Firebase servisom kasnije ne dira UI.

### Donete odluke (ne menjati bez dogovora)

- **State management: `setState` + servis klase.** Bez Riverpod-a/Provider-a u
  MVP fazi. Ekran drži stanje, servis vraća podatke. Ako se kasnije pokaže da je
  potrebno deljeno stanje između tabova, prelazi se na Riverpod — ali tek tada i
  kao svesna odluka, ne usput.
- **Mape: `flutter_map`** (OpenStreetMap). Ne traži Google Maps API ključ ni
  naplatu, a za mini pregled adrese na Home tabu je sasvim dovoljan. Otvaranje
  prave navigacije ide preko `url_launcher` u aplikaciju koju korisnik već ima na
  telefonu (Google Maps / Waze).
- **Jezik u aplikaciji: srpski (latinica).** Svi tekstovi u UI-u na srpskom,
  nazivi klasa/varijabli u kodu na engleskom.

---

## Model podataka (isti kao u RN verziji — osnova za Firestore)

```dart
class Event {
  final String id;              // 'evt-001'
  final String title;           // 'Rođendan - Mia (7 godina)'
  final List<String> scenario;  // ['Doček gostiju', 'Igre za decu', ...]
  final String organizerName;   // ime roditelja/organizatora
  final String organizerPhone;  // '+381641234567'
  final String address;         // 'Bulevar Oslobođenja 45, Novi Sad'
  final double? latitude;       // 45.2671
  final double? longitude;      // 19.8335
  final DateTime? eventDate;    // početak događaja
  final DateTime? departureTime;// vreme polaska
  final int? travelDurationMinutes;
  final String? vehicleId;
  final List<Participant> participants;
}

class Participant { final String name; final String role; } // glavni | vozač | pomoćni
class Vehicle { final String id; final String name; }        // 'Beli kombi'
class ChecklistSection { final String id, name; final List<ChecklistItem> items; }
class ChecklistItem { final String id, name; }
```

Pravila preneta iz RN adaptera:

- učesnik bez eksplicitne uloge dobija ulogu po redosledu: 1. `glavni`,
  2. `vozač`, ostali `pomoćni`; eksplicitno navedena uloga ima prednost
- checklist ima limit od **90 stavki** po događaju
- svako polje može da nedostaje — UI mora da prikaže razuman fallback
  ("Datum nije unet", "Telefon nije unet"), nikad da pukne

Test podaci iz RN verzije (evt-001..evt-004, uključujući namerno prazan evt-004
za proveru praznih stanja) mogu da posluže kao seed za Firestore.

---

## Paketi koji će trebati (zamene za RN zavisnosti)

| Namena | RN verzija | Flutter paket |
|---|---|---|
| Poziv, SMS, otvaranje mapa | `Linking` | `url_launcher` |
| Mapa u kartici adrese | `react-native-maps` | `flutter_map` ili `google_maps_flutter` |
| Datum/vreme na srpskom | `Intl.DateTimeFormat('sr-Latn-RS')` | `intl` (`DateFormat.yMMMMd('sr')`) |
| Kopiranje u clipboard | `expo-clipboard` | ugrađeno: `Clipboard.setData` |
| Logo tima iz galerije | `expo-image-picker` | `image_picker` |
| Trajno čuvanje loga | *nije radilo u Expo Go* | `shared_preferences` |
| Ikonice | Feather (`@expo/vector-icons`) | ugrađene Material ikonice |
| Audio (Muzika tab) | planirano `expo-av` | `just_audio` ili `audioplayers` |
| Bluetooth (LED tab) | planirano `react-native-ble-plx` | `flutter_blue_plus` |
| Dozvole (Bluetooth, fajlovi) | Expo permissions | `permission_handler` |

---

## Firebase (sledeći veliki korak)

Odluka: produkcioni backend je **Firebase** — Firestore za podatke, Firebase
Authentication za login i uloge. Raniji plan sa Google Sheets tabelom kao
izvorom podataka se **napušta**.

Koraci:

1. `flutter pub add firebase_core cloud_firestore firebase_auth`
2. `dart pub global activate flutterfire_cli` pa `flutterfire configure` —
   generiše `lib/firebase_options.dart` i povezuje Android/iOS aplikaciju
3. `Firebase.initializeApp()` u `main()` pre `runApp()`
4. Kolekcije:
   - `events/{eventId}` — polja iz modela iznad
   - `vehicles/{vehicleId}` — `{ name }`
   - `checklistTemplates/{sectionId}` — sekcije i stavke (ili subkolekcija po timu)
   - `users/{uid}` — `{ name, role, teamId }` za uloge
5. `FirestoreEventService` implementira isti interfejs kao mock servis, pa se
   menja jedna linija na mestu gde se servis kreira
6. **Security Rules** po istom modelu dozvola: `glavni` piše, `user` samo čita.
   Ovo je jedina prava zaštita podataka — `firebase_options.dart` sadrži javne
   identifikatore projekta i sam po sebi ne štiti bazu.

---

## Kako pokrenuti

```powershell
cd C:\Users\lefi\AndroidStudioProjects\animator_app
flutter pub get
flutter devices          # spisak povezanih uređaja/emulatora
flutter run              # pokretanje na izabranom uređaju
```

Flutter SDK je na `C:\src\flutter\bin`.

Za telefon: uključiti USB debugging na Androidu i povezati kablom, ili pokrenuti
emulator iz Android Studija.

---

## Konvencije za dalji rad

- Raditi redom po feature ID-jevima unutar taba, bez preskakanja
- Svaki widget: dark-first, koristi temu iz `app_theme.dart`, nikad hardkodovane boje
- Dodirne mete minimum 48 dp
- Posle svake izmene pokrenuti `flutter analyze` (i `flutter run` za vizuelnu proveru)
- Napredak i odluke upisivati u `APP_NOTES.md`

## Sledeći konkretni koraci

0. Prvi git commit odmah na čistom starteru (`git init`, `git add .`,
   `git commit -m "Initial Flutter project"`) — da uvek postoji tačka povratka
1. Zameniti default Flutter `README.md` kratkim opisom projekta
2. Postaviti temu (`lib/theme/app_theme.dart`, dark-first) i skelet sa 4 taba
   u `lib/app.dart` — tabovi mogu prvo biti prazni ekrani sa naslovom
3. Napraviti modele (`lib/models/`) i mock servis (`lib/services/mock_event_service.dart`)
   sa istim test podacima kao u RN verziji (evt-001..evt-004)
4. Preneti Home tab redom: naziv → organizator → telefon → adresa → datum →
   sat → vreme polaska → vozilo → učesnici → status → podsetnik → scenario
   (isti redosled kao u RN verziji, opis u `ARCHIVE_ReactNative.md`)
5. Lager tab: checklist po sekcijama
6. Tek kada Home i Lager rade na mock podacima — povezati Firebase

Posle svakog završenog koraka: `flutter analyze`, kratka provera na telefonu i
beleška u `APP_NOTES.md`.

# e-vent (ranije Animator App) — Flutter

Mobilna aplikacija za profesionalne animatore/izvođače koji rade na proslavama,
ceremonijama i događajima (Novi Sad / Srbija). Jedan kod za Android i iOS.

**Nazivi:**

- folder projekta: `D:\All Work\event_app`
- naziv Dart paketa: `event_app` (bez crtice — Dart ne dozvoljava `-` u nazivu paketa)
- prikazno ime aplikacije na telefonu: **e-vent** (podešava se u
  `android/app/src/main/AndroidManifest.xml` i `ios/Runner/Info.plist`)

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

Četiri taba u **gornjoj** navigaciji, odmah ispod headera:

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

### Home tab — tačan spisak elemenata, odozgo nadole

Ovo je redosled proveren u prethodnoj verziji aplikacije i prenosi se isti.
Ne treba ga ponovo dogovarati — radi se odozgo nadole, jedan po jedan element.

| # | Element | Šta radi | ID |
|---|---|---|---|
| 1 | Kartica događaja | dva reda: `Događaj  12. septembar  16:00` i `7 Mia / 2h` | HOME-001/005 |
| 2 | Organizator | ime roditelja/organizatora + dugme za kopiranje | HOME-002 |
| 3 | Telefon organizatora | **ikonice** u jednom redu: pozovi, SMS, kopiraj | HOME-004 |
| 4 | Adresa | grad uz naslov (`Adresa · Novi Sad`) + ulica bez grada + "Navigacija" | HOME-003 |


| 7 | Vreme polaska | planirano vreme kretanja na događaj | HOME-007 |
| 8 | Vozilo | izbor vozila iz liste + dodavanje novog vozila | zamena za HOME-008/009/010 |
| 9 | Učesnici | spisak ekipe sa ulogama (glavni, vozač, pomoćni) | HOME-012 |
| 10 | Status tima | provera da li su popunjene obavezne uloge glavni i vozač | HOME-013 |
| 11 | Spremnost podataka | šta od podataka o događaju nedostaje | HOME-011 |
| 12 | Status događaja | izveden iz vremena: planirano / polazak / u toku / završeno | HOME-018 |
| 13 | Podsetnik | koliko je ostalo do polaska ili početka događaja | HOME-019 |
| 14 | Scenario | tačke programa; stavke iz baze + korisnik može da doda svoje | HOME-025 |

Uz to na Home ekranu:

- **pull-to-refresh** (povlačenje nadole ponovo učitava podatke o događaju)
- **greška pri učitavanju**: poruka + dugme "Pokušaj ponovo" umesto praznog ekrana (HOME-021)
- **header sa logotipom tima** (iznad tabova): logo bira korisnik sa ulogom `glavni`,
  ostali ga samo vide

### Lager tab

Checklist opreme po sekcijama (Tehnika, Animacija, Specijalni efekti, Vatreni
rekviziti, Svila, Hoop): sekcije se otvaraju/zatvaraju, stavke se čekiraju,
korisnik može da doda svoju stavku, traka napretka i limit od 90 stavki.

**Dva režima, sa odvojenim kvačicama:** *Pakovanje* pre događaja i
*Raspakivanje* posle. Odvojeni su namerno — kad se posle događaja proverava
šta se vratilo, ne sme da se poništi ono što je pre bilo spakovano.

**Sekcije i stavke nisu ugrađene u aplikaciju** (odluka od 8. septembra 2026).
Šest sekcija koje sada stoje su samo početni šablon. Različite firme imaju
različit lager, pa i **sekcije i stavke unutar njih određuje admin iz login
konzole**, po timu odnosno firmi. Aplikacija ih samo prikazuje.

Iz toga sledi:

- broj sekcija nije fiksan — ekran mora da radi i sa tri i sa petnaest sekcija
- šablon se čita iz baze (`checklistTemplates`), ne iz koda
- limit od **90 stavki** po događaju ostaje bez obzira na broj sekcija
- stavke koje sada stoje u `mock_event_service.dart` su privremene i služe
  samo dok se ne poveže baza

### Muzika tab

Lista muzičkih fajlova sa izvorom (Folder / Playlista). Izbor fajla **ne**
pokreće reprodukciju — pokreće se tek u playback meniju sa velikim dugmetom;
tajmer i opcija "fade in 10 sec".

#### Prsten talasnog oblika (glavni vizuelni element)

Prikaz dokle je stigla reprodukcija ne radi se klasičnom trakom, nego
**linijom koja obilazi ivicu ekrana**:

- kreće iz **gornjeg levog ugla**, ide desno duž gornje ivice
- niz **desnu ivicu** nadole
- duž **donje ivice** nalevo
- uz **levu ivicu** nagore, nazad u gornji levi ugao

Kraj se poklapa sa početkom, pa korisniku deluje kao krug — pesma se "zatvara".

Linija nije ravna: ona je **talasni oblik pesme** (amplituda), pa se po debljini
odnosno odstupanju od putanje vidi gde su tiši a gde glasniji delovi. Tako
izvođač jednim pogledom zna šta ga čeka — dolazi li tih uvod ili udar.

**Ponašanje:**

- pređeni deo linije je u boji `accent`, sa blagim sjajem (`gradientAccent`)
- nepređeni deo je u `accentDeep` — vidljiv, ali povučen
- na trenutnoj poziciji stoji mala tačka koja klizi po putanji
- u sredini ekrana ostaje tekstualno vreme (proteklo i ukupno) — prsten je
  dopuna, ne zamena za brojku
- kasnija faza: prevlačenjem po prstenu se premotava pesma

**Podaci i izvedba (bitno za performanse):**

- amplitude se računaju **jednom po pesmi**, pri učitavanju fajla — niz od N
  vrednosti 0..1, gde je N približno broj tačaka po obimu ekrana
- niz se kešira uz fajl; nikada se ne računa u toku crtanja
- crtanje ide kroz `CustomPainter`; putanja (zaobljeni pravougaonik uz ivicu
  ekrana) se gradi jednom po veličini ekrana, ne po kadru
- prerisavanje se okida pozicijom reprodukcije preko `Listenable`, bez
  ponovnog građenja widget stabla; ceo prsten ide u `RepaintBoundary`
- dok amplitude nisu spremne, crta se ravna linija — nikad prazan ekran
- paket za izvlačenje talasnog oblika iz audio fajla treba izabrati kad se dođe
  do ovog feature-a (kandidati: `just_waveform`, `audio_waveforms`) — odluka se
  donosi sa korisnikom, ne usput

### LED tab

Nije započet. Pre prvog feature-a treba potvrditi koji hardver/protokol se
koristi i šta se dešava kada Bluetooth nije dostupan.

### Admin konzola i login (dogovoreno 8. septembra 2026)

Aplikacija ima **dva lica istog Home ekrana**:

| | Ko vidi | Šta može |
|---|---|---|
| Home (obično) | svi članovi tima | čita podatke o događaju koji mu je dodeljen |
| Admin konzola | samo posle **logina**, uloga `glavni` | isti raspored, ali sa poljima za unos |

**Admin konzola nije poseban ekran sa svojim rasporedom** — to je isti Home
meni, samo što se do njega stiže prijavom i u njemu su polja popunjiva.
Uz to ima dugme **"Create and share (assign team)"**: `glavni` popuni tabelu
događaja i podeli je ostalim članovima tima. Član tima koji nije u
managementu tada dobije taj događaj kao svoj zadatak (assignment) u aplikaciji.

Iz toga slede dva pravila:

- **Isti widgeti služe oba lica.** Kartice na Home tabu se ne prave dvaput;
  posle logina dobijaju polja za unos, bez logina su samo za čitanje.
- **Menjanje logotipa u headeru traži login** — to je funkcija managementa,
  ne obična podešavanja.

Login ekran izgleda kao Home ekran; razlika je samo u tome što on ima
popunjavanje tabele koja se posle deli timu.

### Uloge i dozvole

- `glavni` — vodi ekipu; sme da menja logo tima, bira vozilo, upravlja checklistom
- `user` — izvođač; vidi sve, ali bez akcija koje menjaju podatke tima

UI uvek proverava **dozvolu**, nikada naziv uloge direktno — tako backend kasnije
može da doda nove uloge bez menjanja ekrana.

### Kako se piše naziv događaja

Naziv je kratak i bez odrednica koje se podrazumevaju:

| Umesto | Piše se |
|---|---|
| `Rođendan - Mia (7 godina)` | `7 Mia` |

- Reč **"rođendan" se ne piše** — iz imena slavljenika i broja se već vidi
  o čemu je reč.
- **Arapski broj ispred imena uvek znači godine slavljenika**, pa odrednica
  "godina" otpada.
- **Trajanje se prepoznaje po slovu `h`** (`2h`, `1h30`, `45min`) — to je
  jedini broj u tom redu koji nosi oznaku, pa se ne meša sa godinama ni sa
  satom početka. Piše se odmah uz ime, odvojeno kosom crtom, bledosivo:
  `7 Mia / 2h`.
- **Imena mesta idu velikim početnim slovom** (`Novi Sad`), a grad se ne
  ponavlja u redu sa ulicom.
- `Event.title` u bazi već sadrži gotov naziv u ovom obliku; aplikacija ga
  ne sklapa i ne prevodi.

### Vreme na Home tabu (odluka od 8. septembra 2026)

- **Sat uživo je uklonjen.** Trenutno vreme telefon već pokazuje u statusnoj
  traci; ponavljati ga u aplikaciji je trošenje prostora.
- Umesto njega stoji **ugovoreno trajanje** nastupa, uz izračunat kraj
  ("Od 16:00 do 18:00") — to je podatak koji izvođač inače računa u glavi.
- **Sat početka je čist podatak, ne dugme.** Nema trake za biranje časa —
  sat se unosi u admin konzoli, posle prijave. Na Home tabu se samo čita.
- **Datum i sat stoje na vrhu, iznad naziva događaja**, u jednom sitnom redu,
  bez godine: posao se planira nedeljama unapred, pa godina samo zauzima mesto.
- Ta brojka je namerno krupna i tačna: iz nje korisnik u glavi izračuna sve
  ostalo, brže nego bilo koji ekran, a preciznost u ovakvim detaljima je ono
  po čemu aplikacija deluje pedantno.
- Ugovoreno trajanje ujedno određuje i kada je status događaja "završeno" —
  ranija pretpostavka od 4 sata koristi se samo ako trajanje nije uneto.

### Navigacija (odluka od 8. septembra 2026)

Tabovi stoje **gore, odmah ispod headera** — ne dole. Odluka je korisnikova:
telefon se često koristi u držaču u vozilu i na sastanku, gde se prilazi
kažiprstom odozgo, a ne palcem odozdo.

Tabovi su izvedeni kao dugmad sa **zakošenom ivicom (bevel)**: izabrani je
izdignut, sa svetlom ivicom gore i senkom ispod, i u boji `accent`; neizabrani
su utisnuti u podlogu i mirni. Cilj je da se **sa ispružene ruke**, u vožnji
ili tokom programa, na prvi pogled vidi šta je izabrano.

Izvedba: zakošenje se pravi od dva sloja (spoljni tanak okvir sa gradijentom
svetlo→tamno, unutrašnji je lice dugmeta). Flutter ne dozvoljava zaobljen okvir
sa različitim bojama stranica, pa je ovo jedini način da bevel i zaobljeni
uglovi idu zajedno.

Prevlačenje između tabova se **ne koristi** — sadržaj stoji u `IndexedStack`,
da bi prevlačenje ostalo slobodno za prsten na Muzici.

**Header i tabovi se sklanjaju pri skrolovanju nadole** i vraćaju čim se krene
nagore. Time spisak dobija oko 150 dp, a tabovi su na dohvat jednim pokretom.

**Izuzetak od pravila o dodirnoj meti:** red u spisku numera je 36 dp, ne 48.
Odluka korisnika, zbog gustine spiska na nastupu. Red je preko cele širine
ekrana, pa je meta i dalje široka. Svuda drugde važi 48 dp.

### Pravila dizajna

- **Aplikacija je samo tamna** (čuva noćni vid i bateriju na večernjim nastupima)
- Minimalna dodirna meta **48x48 dp** — rad jednom rukom tokom nastupa
- Visok kontrast, krupan tekst za ključne informacije (naziv, vreme, adresa)
- Minimalistički UI: na ekranu samo ono što treba u tom trenutku

### Paleta (koristiti tačno ove vrednosti)

Vizuelni pravac: **skoro crno sa hladnim, tamno-tirkiznim prizvukom.** Crna je
osnova, tirkiz se pojavljuje kao nagoveštaj — u gradijentima, okvirima i sjaju,
a punom jačinom samo tamo gde nešto može da se dodirne.

Aplikacija je **samo tamna** — svetla tema se ne pravi. Događaji su uveče i
noću, a jedna tema znači i upola manje posla oko provere izgleda.

| Uloga | Hex | Gde se koristi |
|---|---|---|
| `background` | `#0A0C0C` | osnovna pozadina ekrana |
| `backgroundTop` | `#0E1312` | gornja boja pozadinskog gradijenta |
| `backgroundBottom` | `#070909` | donja boja pozadinskog gradijenta |
| `surface` | `#121716` | kartice |
| `surfaceAlt` | `#182120` | istaknute kartice, polja, aktivni red |
| `border` | `#1F2A29` | okviri kartica i razdelnici |
| `textPrimary` | `#ECECEC` | glavni tekst (namerno nije čisto belo) |
| `textSecondary` | `#8A9A98` | pomoćni tekst, hladno siva sa zelenkastim tonom |
| `accent` | `#2FA89C` | sve što se dodiruje: dugmad, ikonice, aktivni tab |
| `accentDeep` | `#14403C` | gradijenti, sjaj, neaktivni deo prstena — **nikad za tekst** |
| `success` | `#3FA46A` | spremno, završeno |
| `warning` | `#E0B341` | uskoro, nedostaje podatak |
| `danger` | `#E5645E` | greška, problem |

**Pravila za boju:**

- Boja uvek nosi značenje, nikad ukras. Tirkiz = interaktivno, zelena = spremno,
  žuta = pažnja, crvena = problem.
- Boja nikad ne stoji sama — uvek uz ikonicu ili tekst (u mraku, iz ruke, niko
  ne razaznaje nijanse).
- `accentDeep` je isključivo dekorativan. Tekst i ikonice koje nešto znače idu u
  `accent`, `textPrimary` ili `textSecondary`.
- Boje se pišu samo u `app_theme.dart`. Nijedan widget nema hex vrednost u sebi.

**Gradijenti** (deo teme, ne improvizacija po widgetima):

- `gradientBackground` — vertikalni, `backgroundTop` → `backgroundBottom`, preko
  celog ekrana
- `gradientSurface` — dijagonalni (135°), `#141A19` → `#0C1010`, za istaknute
  kartice i header
- `gradientAccent` — `accentDeep` → prozirno, za sjaj oko aktivnih elemenata
  (npr. veliko dugme za reprodukciju i pređeni deo prstena)

Gradijent ide samo na veće površine. Iza sitnog teksta nikad — tekst mora imati
ujednačenu podlogu.

### Razmaci i oblici

Razmaci: `xs = 4`, `sm = 8`, `md = 16`, `lg = 24`, `xl = 32`.
Minimalna dodirna meta: `minTouchTarget = 48`.
Kartice: zaobljenje 12, okvir 1 px u boji `border`.

### Pokret i animacije — samo neophodno

Pravilo: animira se ono što **nosi informaciju** ili **potvrđuje dodir**. Sve
ostalo se ne animira. Bez ulaznih animacija kartica, bez klizanja između tabova,
bez efekata radi efekta.

Dozvoljeno je tačno ovo:

| Šta | Kako | Zašto |
|---|---|---|
| Prsten reprodukcije na Muzici | neprekidno, 60 fps | to je sama informacija |
| Čekiranje stavke (Lager, scenario) | ~120 ms, kvačica | potvrda da je dodir pogodio |
| Pritisak dugmeta | skala 0.97, ~100 ms | povratna informacija u žurbi |
| Traka napretka pripreme | širina se animira ~300 ms | inače vrednost skače |
| Promena statusa događaja | pretapanje boje ~300 ms | naglo prebacivanje zbunjuje |

Ostala pravila:

- trajanje 100–300 ms, `Curves.easeOut`; ništa duže
- animacija nikad ne odlaže akciju — dešava se uz radnju, ne pre nje
- **sat i odbrojavanje se ne animiraju** — tekst koji se menja svake sekunde a
  pritom treperi je iritantan
- poštovati sistemsko podešavanje za smanjen pokret
  (`MediaQuery.disableAnimations`) — tada ostaje samo prsten reprodukcije

---

## Ciljna struktura projekta (Flutter)

```
lib/
  main.dart              - runApp + inicijalizacija (kasnije Firebase.initializeApp)
  app.dart               - MaterialApp, tema, root sa headerom i tabovima gore (4 taba)
  theme/
    app_theme.dart       - tamna ColorScheme, gradijenti, spacing, minTouchTarget = 48
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
- **Vremenska prognoza: Open-Meteo.** Besplatan, bez API ključa i bez
  registracije, daje prognozu po satu. Prikazuje se vreme **za sate u kojima
  nastup traje**, ne opšta dnevna prognoza — poenta je da organizator unapred
  zna da mu kiša pada na pola programa.
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
  final int? durationMinutes;   // ugovoreno trajanje nastupa
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
| Audio (Muzika tab) | planirano `expo-av` | **`just_audio`** (izabrano) |
| Bluetooth (LED tab) | planirano `react-native-ble-plx` | `flutter_blue_plus` |
| Dozvole (Bluetooth, fajlovi) | Expo permissions | `permission_handler` |
| Vremenska prognoza | — | `http` + Open-Meteo (bez ključa) |
| Biranje numera sa telefona | — | `file_picker` |

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
cd "D:\All Work\event_app"
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
4. Preneti Home tab redom: naziv → organizator → telefon → adresa → datum i
   sat početka → trajanje → vreme polaska → vozilo → učesnici → status →
   podsetnik → scenario
   (isti redosled kao u RN verziji, opis u `ARCHIVE_ReactNative.md`)
5. Lager tab: checklist po sekcijama
6. Tek kada Home i Lager rade na mock podacima — povezati Firebase

Posle svakog završenog koraka: `flutter analyze`, kratka provera na telefonu i
beleška u `APP_NOTES.md`.

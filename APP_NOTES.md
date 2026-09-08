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

## 8. septembar 2026 — paleta iz specifikacije, modeli i mock servis

- Urađeno:
  - `lib/theme/app_theme.dart` prepisan: umesto `ColorScheme.fromSeed` sa
    narandžastim seed-om, sada stoje **tačne hex vrednosti iz CLAUDE.md**
    (`AppColors`), gradijenti (`AppGradients`), `kCardRadius = 12`.
    Light tema je uklonjena — aplikacija je samo tamna, kako je dogovoreno.
  - `lib/models/event.dart` — `Event`, `Participant`, `ParticipantRole`.
    Uloga koja nije upisana dodeljuje se po redosledu (1. glavni, 2. vozač,
    ostali pomoćni); prazan tekst iz baze se tretira kao da podatka nema,
    a neispravan datum vraća `null` umesto da sruši aplikaciju.
  - `lib/models/vehicle.dart`, `lib/models/checklist.dart`
    (`kMaxChecklistItems = 90`)
  - `lib/services/event_service.dart` — interfejs koji ekrani zovu
  - `lib/services/mock_event_service.dart` — test podaci evt-001..evt-004
    (evt-004 je namerno potpuno prazan) + vozila + šablon checkliste
  - `test/mock_event_service_test.dart` — 6 testova nad mock servisom
- Provereno: `flutter analyze` — No issues found; `flutter test` — 8/8 prolaze;
  tema proverena na telefonu (SM-A346B), boje odgovaraju specifikaciji
- Otvoreni problemi:
  - **stavke unutar checklist sekcija su izmišljene kao privremene** —
    treba ih zameniti pravim spiskom opreme
  - `flutter run` visi na "Installing ..." zbog Secure Foldera na telefonu
    (dva korisnička profila, `0` i `150`). Zaobilazi se ručno:
    `flutter build apk --debug` pa
    `adb install -r -t --user 0 build/app/outputs/flutter-apk/app-debug.apk`
    pa `adb shell am start --user 0 -n com.eventapp.event_app/.MainActivity`.
    Zbog toga za sada nema hot reload-a.
  - i dalje otvoreno od ranije: `NavigationBar` umesto `BottomNavigationBar`,
    prikazno ime aplikacije na telefonu je još uvek `event_app`
- Sledeće: HOME-001 — naziv događaja na Home ekranu, iz mock servisa

---

## 8. septembar 2026 — HOME-001, naziv događaja

- Urađeno:
  - `lib/widgets/home/event_title.dart` — HOME-001. Krupan, read-only naziv
    događaja. Kad naziva nema (ili je prazan tekst) piše
    "Naziv događaja nije unet" u pomoćnoj boji, umesto praznog mesta.
  - `lib/widgets/common/error_retry.dart` — poruka o grešci sa dugmetom
    "Pokušaj ponovo" (osnova za HOME-021)
  - `lib/screens/home_screen.dart` prepisan u `StatefulWidget`: učitava
    `evt-001` preko `MockEventService`, ima tri stanja — učitavanje,
    greška sa ponovnim pokušajem, i prikaz podataka. Servis se pravi na
    jednom mestu u ekranu; kad dođe Firebase, menja se samo ta linija.
  - `test/event_title_test.dart` — 3 testa; `test/widget_test.dart` dopunjen
- Provereno: `flutter analyze` — No issues found; `flutter test` — 11/11
  prolaze; instalirano i pokrenuto na telefonu (SM-A346B)
- Sledeće: HOME-002 — organizator (ime + dugme za kopiranje)

---

## 8. septembar 2026 — HOME-002, organizator

- Urađeno:
  - `lib/widgets/common/copy_button.dart` — dugme "kopiraj": prepiše zadati
    tekst u clipboard (ugrađeni `Clipboard.setData`, bez novog paketa) i javi
    potvrdu porukom pri dnu ekrana. Poruka je oblika "Kopirano: <naziv>" —
    namerno neutralna, da ne zavisi od roda reči (telefon je *kopiran*, adresa
    *kopirana*). Isto dugme će koristiti i HOME-004 (telefon) i adresa.
  - `lib/widgets/home/organizer_name.dart` — HOME-002. Ime organizatora u redu
    sa dugmetom za kopiranje desno. Kad imena nema (ili je prazan tekst) piše
    "Organizator nije unet" i dugmeta nema — nema šta da se kopira.
  - `lib/screens/home_screen.dart` — kartica dodata ispod naziva događaja.
  - `test/organizer_name_test.dart` — 4 testa (prikaz, prazno ime, prazan
    tekst, i sam dodir na kopiranje sa presretnutim clipboard kanalom).
- Provereno: `flutter analyze` — No issues found; `flutter test` — 15/15 prolaze
- Sledeće: HOME-004 — telefon organizatora (pozovi, SMS, kopiraj); traži paket
  `url_launcher`, pa se pre toga pita korisnik

---

## 8. septembar 2026 — HOME-004, telefon organizatora

- Urađeno:
  - Dodat paket `url_launcher` (^6.3.2) — prvi paket van startera; stoji u
    tabeli paketa u `CLAUDE.md`, korisnik potvrdio.
  - `android/app/src/main/AndroidManifest.xml` — u `<queries>` dodati `tel`
    (DIAL) i `smsto` (SENDTO). Na Androidu 11+ bez ovoga dugmad "Pozovi" i
    "SMS" ne rade, jer sistem sakrije telefon i poruke od aplikacije.
  - `lib/widgets/home/organizer_phone.dart` — HOME-004. Broj + tri akcije:
    "Pozovi" (puno dugme, glavna radnja), "SMS" (okvirno dugme) i kopiranje
    (isti `CopyButton` kao kod organizatora). Broj se pre slanja telefonu
    očisti od razmaka, crtica i zagrada; vodeći `+` ostaje. Ako telefon ne
    može da otvori poziv/poruku, ide poruka pri dnu ekrana umesto dugmeta
    koje deluje pokvareno. Bez broja: "Telefon nije unet", bez dugmadi.
  - `lib/screens/home_screen.dart` — kartica dodata ispod organizatora.
  - `test/organizer_phone_test.dart` — 6 testova; poziv i SMS se proveravaju
    presretanjem kanala `plugins.flutter.io/url_launcher`, pa se vidi tačna
    adresa (`tel:+381641234567`) koja bi otišla telefonu.
- Provereno: `flutter analyze` — No issues found; `flutter test` — 21/21 prolaze.
  Poziv/SMS na pravom telefonu još nije probano (traži novi build).
- Sledeće: HOME-003 — adresa (tekst + mini mapa + dugme "Navigacija"); mapa
  traži paket `flutter_map`, pa se pre toga pita korisnik

---

## 8. septembar 2026 — HOME-003, adresa sa mini mapom

- Urađeno:
  - Dodati paketi `flutter_map` (^8.3.2) i `latlong2` (^0.10.1) — OpenStreetMap,
    bez API ključa i bez naplate, kako je dogovoreno u `CLAUDE.md`.
  - `lib/widgets/home/event_address.dart` — HOME-003. Tekst adrese sa dugmetom
    za kopiranje, ispod mini mapa (visina 160, zum 15, markerica u boji
    `accent`), pa dugme "Navigacija" preko cele širine. Mapa je zaključana —
    ne pomera se i ne zumira; ona je pregled, a snalaženje ide kroz navigaciju.
  - Navigacija otvara `https://www.google.com/maps/dir/?api=1&destination=...`
    u aplikaciji koju korisnik već ima (Google Maps / Waze / pregledač).
    Sa koordinatama ide na tačnu tačku, bez njih se prosleđuje tekst adrese.
  - `AndroidManifest.xml`: dodat `<intent>` za `https` VIEW (bez toga dugme
    "Navigacija" na Androidu 11+ ne radi) i **`INTERNET` dozvola u glavni
    manifest** — do sada je stajala samo u debug manifestu, pa mini mapa u
    pravom (release) buildu ne bi imala pločice.
  - `lib/screens/home_screen.dart` — kartica dodata ispod telefona.
  - `test/event_address_test.dart` — 7 testova (prikaz, prazna adresa, mapa
    samo kad ima koordinata, tačna adresa navigacije u oba slučaja, poruka
    kad telefon ne može da otvori mapu).
- Provereno: `flutter analyze` — No issues found; `flutter test` — 28/28 prolaze.
  Mapa i navigacija na pravom telefonu još nisu probane (traži novi build).
- Sledeće: HOME-005 — datum događaja na srpskom; traži paket `intl`

---

## 8. septembar 2026 — zajednički header, HOME-005 (datum)

- Urađeno:
  - `lib/widgets/common/app_header.dart` — **jedan zajednički header iznad
    tabova**, umesto dosadašnjih `AppBar`-ova sa nazivom taba ("Home",
    "Muzika"...). Po specifikaciji tu stoji logotip tima, a koji je tab otvoren
    vidi se u donjoj navigaciji. Dok logotipa nema, piše ime aplikacije.
  - Dodat paket `intl` (^0.20.3).
  - `lib/utils/date_format.dart` — ispis datuma i vremena na jednom mestu.
    Koristi se **`sr_Latn`**, ne `sr` — `sr` je ćirilica ("12. септембар"),
    a nama treba latinica ("12. septembar 2026.").
  - `lib/main.dart` — `AppDate.init()` pre `runApp()`; bez učitanih naziva
    meseci ispis datuma puca.
  - `lib/widgets/home/event_date.dart` — HOME-005. Bez datuma: "Datum nije unet".
  - `test/event_date_test.dart` — 3 testa; `test/widget_test.dart` dopunjen
    `setUpAll` pozivom (test podiže `EventApp` direktno, mimo `main()`).
- **Odstupanje od strukture iz `CLAUDE.md`:** dodat folder `lib/utils/`, kog
  nema u spisku. Datum i vreme trebaju na pet mesta na Home tabu (datum, sat,
  polazak, podsetnik, status), pa ispis stoji na jednom mestu. Lako se premešta
  ako ne odgovara.
- Provereno: `flutter analyze` — No issues found; `flutter test` — 31/31 prolaze
- Sledeće: HOME-006 — sat uživo

---

## 8. septembar 2026 — HOME-006 (sat uživo) i HOME-007 (vreme polaska)

- Urađeno:
  - `lib/widgets/home/live_clock.dart` — HOME-006. Vreme `14:30:07`, osvežava
    se svake sekunde. Otkucaj se poravnava sa punom sekundom, da prikaz ne
    preskače. **Bez animacije** — po pravilu iz `CLAUDE.md` sat ne treperi.
    Brojke su iste širine (`tabularFigures`), da se tekst ne pomera. Tajmer se
    gasi u `dispose()`. Sat se čita kroz `now` parametar (u aplikaciji
    `DateTime.now`), jer se u testu pravo vreme ne može ubrzati.
  - `lib/widgets/home/departure_time.dart` — HOME-007. Vreme polaska i, ako
    postoji, procenjeno trajanje puta ("Put traje oko 45 min").
  - `test/live_clock_test.dart` (3 testa) i `test/departure_time_test.dart`
    (4 testa) — uključujući proveru da tajmer ne ostane da radi posle gašenja.
- Provereno: `flutter analyze` — No issues found; `flutter test` — 38/38 prolaze
- Sledeće: vozilo (izbor iz liste + dodavanje novog)

---

## 8. septembar 2026 — vozilo (zamena za HOME-008/009/010)

- Urađeno:
  - `lib/widgets/home/vehicle_picker.dart` — kartica sa izabranim vozilom;
    dodir otvara listu odozdo, gde se bira vozilo ili se kroz "Dodaj vozilo"
    unese novo. Ima `canEdit` zastavicu (bez dozvole se vidi samo naziv) —
    spremno za trenutak kad stigne login i uloga `glavni`.
  - `EventService.setEventVehicle(eventId, vehicleId)` — nova metoda u
    interfejsu; mock je pamti u memoriji, jer su test događaji `const`.
  - `Event.withVehicle(...)` — kopija događaja sa drugim vozilom (model je
    nepromenljiv).
  - `lib/screens/home_screen.dart` — događaj i spisak vozila se učitavaju
    uporedo (`Future.wait`). Izbor vozila se odmah vidi na ekranu, a upis ide
    u pozadini; ako upis pukne, stanje se vraća i javi se porukom, da ekran
    ne laže. Novo vozilo odmah postaje izabrano.
  - `test/vehicle_picker_test.dart` — 8 testova (izbor, prazan spisak, prazan
    naziv, nepoznat id vozila, zabrana izmene).
- Provereno: `flutter analyze` — No issues found; `flutter test` — 46/46 prolaze
- Sledeće: HOME-012 — učesnici sa ulogama

---

## 8. septembar 2026 — HOME-012 (učesnici) i HOME-013 (status tima)

- Urađeno:
  - `lib/widgets/home/participants_list.dart` — spisak ekipe sa ulogama i
    brojem članova. Svaka uloga ima svoju ikonicu (glavni — zvezdica, vozač —
    auto, pomoćni — osoba), jer se u mraku nijanse boje ne razaznaju. Prazan
    spisak: "Ekipa još nije određena"; učesnik bez imena: "Ime nije uneto".
  - `lib/widgets/home/team_status.dart` — HOME-013. Proverava da li su
    popunjene obavezne uloge **glavni** i **vozač**; ako nisu, izričito piše
    koja fali. Zeleno kad je kompletno, žuto kad nešto nedostaje — i uvek uz
    ikonicu, nikad samo boja.
  - `test/participants_test.dart` — 8 testova.
- Provereno: `flutter analyze` — No issues found; `flutter test` — 54/54 prolaze
- Sledeće: HOME-011 (spremnost podataka), HOME-018 (status događaja),
  HOME-019 (podsetnik)

---

## TODO (skupljati ovde, rešavati kad dođe red)

- **OpenStreetMap pločice za mini mapu.** Koristi se javni server
  `tile.openstreetmap.org`, koji ima pravila korišćenja (nije za velike
  količine saobraćaja). Za nekoliko korisnika iz ekipe je sasvim u redu; ako
  aplikacija ikad izađe šire, prebaciti se na svoj ili plaćeni izvor pločica.
- **Prave stavke opreme za Lager checklist.** Sekcije su tačne, ali su stavke
  unutar njih izmišljene kao privremene. Zamisao: izbor jedne sekcije izlistava
  niz stavki ispod nje. Pravi spisak daje korisnik.
- Prikazno ime aplikacije na telefonu je i dalje `event_app` — treba ga
  promeniti na "e-vent" u `AndroidManifest.xml` i `Info.plist`.
- Donja navigacija koristi `NavigationBar` (Material 3), a u `CLAUDE.md` piše
  `BottomNavigationBar` — potvrditi jedno ili drugo.
- `flutter run` visi na "Installing ..." zbog Secure Foldera na telefonu
  (profili `0` i `150`), pa za sada nema hot reload-a. Zaobilazi se ručnim
  `flutter build apk --debug` + `adb install --user 0` + `am start --user 0`.

---

## Šablon za nove beleške

```
## <datum> — <šta je rađeno>

- Urađeno:
- Provereno (flutter analyze / test na telefonu):
- Otvoreni problemi:
- Sledeće:
```

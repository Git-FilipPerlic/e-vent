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
   pokretanje velikim dugmetom, tajmer, fade-in/fade-out, red čekanja,
   crossfade, prsten talasnog oblika po ivici ekrana
3. **LED** — kontrola LED rasvete preko Bluetooth-a: boje, scene, efekti,
   kasnije sinhronizacija sa muzikom (kako tačno — nije dogovoreno)
4. **Lager** — checklist opreme po sekcijama (Tehnika, Animacija, Specijalni
   efekti, Vatreni rekviziti, Svila, Hoop), pakovanje pre i raspakivanje posle
   događaja, limit 90 stavki

Feature-i se vode po tabovima: HOME-001..025, **MUSIC-001..022**
(prebrojano 9. septembra 2026, spisak je niže), LED-001..024, LAGER-001..026.

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

#### Kategorije opreme (dogovoreno 9. septembra 2026)

Lager ne prikazuje **sve** što firma poseduje, nego samo ono što ide na taj
događaj. Veza ide ovako:

1. **Manager u konzoli bira kategorije** za događaj — na primer *Vatra*,
   *LED*, *Ring*. Bira ih iz spiska kategorija koje firma ima.
2. **Lager tab prikazuje izabrane kategorije i sve delove koji im pripadaju.**
   Kategorija je sekcija u checklisti, a njeni delovi su stavke u njoj.
   Ono što nije izabrano se ne prikazuje — na nastupu ne treba prelistavati
   opremu koja se ne nosi.
3. **Delovi kategorije se takođe menjaju iz manager konzole** — kad se u
   *Vatru* doda nov rekvizit, on se pojavi na svakom događaju koji ima tu
   kategoriju.

Iz toga sledi:

- `Event` nosi **spisak izabranih kategorija**, ne kopiju stavki. Kopija bi
  značila da se izmena u katalogu ne vidi na već napravljenim događajima.
- Katalog kategorija sa stavkama je **po firmi**, ne po događaju.
- **Izbor vozila i izbor kategorija su obe funkcije managera** — bez prijave
  se samo vide.

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

Plejer za nastup. Spisak numera se puni sa telefona (pojedinačni fajlovi ili
ceo folder), numera se bira iz spiska, a zvuk kreće **tek u plejeru**, velikim
dugmetom.

#### Pravila koja se ne menjaju

1. **Dodir na numeru nikada ne pokreće zvuk.** Usred programa prst ume da
   okrzne ekran; pogrešna pesma u zvučniku je skuplja greška od jednog dodira
   više. Puštanje i pauza idu isključivo preko velikog dugmeta u plejeru.
2. **Izvor numere se uvek vidi** (folder ili plejlista). U žurbi se lako pomeša
   pesma iz telefona sa pesmom pripremljenom za nastup. U zbijenom spisku izvor
   se prikazuje ikonicom, jer za tekst nema mesta.
3. **Svaki podatak može da nedostaje.** Numera bez naziva pada na naziv fajla,
   numera bez poznatog trajanja prikazuje `--:--`, numera koja ne može da se
   otvori javlja grešku umesto da obori plejer.
4. **Red u spisku je 36 dp** — svesno ispod minimalne dodirne mete od 48 dp,
   zbog gustine spiska na nastupu. Red je preko cele širine ekrana, pa je meta
   i dalje široka. Ovo je jedini izuzetak u aplikaciji.

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
- prevlačenjem po prstenu se premotava pesma (MUSIC-015)

**Zaštita gornje ivice (odluka od 9. septembra 2026):** gornja linija prstena
**ne ide uz samu ivicu ekrana**, nego je spuštena za visinu headera (72 dp).
Uz ivicu bi premotavanje prevlačenjem padalo u pojas kojim se otvara sistemska
zavesa, a usred nastupa promašen prst ne sme da isključi Wi-Fi ni da izbaci
aplikaciju. Jednostavnije je skloniti liniju nego se boriti sa sistemskim
pokretima. Uz to plejer radi bez sistemskih traka, kao druga brana.

**Podaci i izvedba (bitno za performanse):**

- amplitude se računaju **jednom po pesmi**, pri učitavanju fajla — niz od N
  vrednosti 0..1, gde je N približno broj tačaka po obimu ekrana
- niz se kešira uz fajl; **nikada se ne računa u toku crtanja**
- crtanje ide kroz `CustomPainter`; putanja (zaobljeni pravougaonik uz ivicu
  ekrana) se gradi jednom po veličini ekrana, ne po kadru
- prerisavanje se okida pozicijom reprodukcije preko `Listenable`, bez
  ponovnog građenja widget stabla; ceo prsten ide u `RepaintBoundary`
- dok amplitude nisu spremne, crta se ravna linija — nikad prazan ekran
- **izabran paket: `just_waveform`** (odluka od 9. septembra 2026). Izabran
  zato što **samo izvlači amplitude u fajl i ne nameće svoj widget** — prsten
  crtamo sami, a amplitude nam trebaju kao podatak. `audio_waveforms` je
  pravljen za snimanje i dolazi sa gotovim prikazom koji bismo zaobilazili.
- talas se crta kao **crtice poprečno na putanju**, dužine srazmerne glasnoći;
  crtice se računaju jednom po pesmi i po veličini ekrana, a u toku crtanja se
  samo bira dokle je pesma stigla (`drawRawPoints` nad unapred spremljenom
  `Float32List`, bez pravljenja novih listi po kadru)

#### Red čekanja i kretanje kroz spisak (dogovoreno 9. septembra 2026)

**Razlikuju se dve stvari:** numera koju si **izabrao** dodirom i numera koja
u tom trenutku **svira**. Dok ništa ne svira, to je ista pesma. Čim nešto
svira, dodir na drugu pesmu je samo bira i priprema — ono što svira se ne seče.

Osnovni tok:

1. gledaš spisak numera
2. **dodirneš pesmu koju hoćeš da pustiš** — ona postaje izabrana
3. pritisneš **play** (u traci uz spisak ili veliko dugme u nastupnom ekranu)

Prelazak na sledeću pesmu usred programa:

1. dodirneš sledeću pesmu — ona je izabrana, a prethodna i dalje svira
2. otvoriš nastupni ekran
3. uključiš **Fade** ako hoćeš preklapanje
4. pritisneš **veliko dugme** — pesma koja svira izlazi, izabrana ulazi, i
   **obe sviraju u preklopu**. Bez `Fade` prelaz je odmah.

Ostalo:

- **dodir na numeru koja je već izabrana** je vraća na početak
- **skip napred / nazad** pomeraju red za jedno mesto
- **zvuk nikad ne kreće od dodira**, samo od dugmeta
- prelazak sa pesme na pesmu ide uz **kratko pretapanje naslova** (do 200 ms);
  ostatak ekrana se ne animira, po opštim pravilima za pokret

**Plejer ima dva nivoa** (dogovoreno 9. septembra 2026):

1. **Kontrole uz spisak** — prethodna, −10 s, plej/pauza, +10 s, sledeća.
   Dovoljno da se upravlja bez izlaska iz spiska.
2. **Nastupni ekran** — prsten, vreme, **ogromno dugme** (200 dp) i **jedan
   prekidač: Fade**. Ništa više. Dugme je namerno preveliko: traži se prstom,
   u mraku, bez gledanja u ekran. Jedan prekidač umesto tri — na nastupu se ne
   bira između opcija.

`Fade` znači sve troje odjednom: ulazak iz tišine, izlazak u tišinu i
**preklapanje** kad se pređe sa numere koja svira na izabranu.

Reprodukcija pripada **Muzika tabu**, ne nastupnom ekranu, pa muzika ne
prestaje kad se sa njega izađe. **Veliko dugme pusti numeru i odmah vrati na
spisak** — pesma krene, a ruke su slobodne da se pripremi sledeća.

#### Spisak feature-a i redosled rada

Radi se odozgo nadole. Gotovo je ono što je označeno.

| ID | Šta | Status |
|---|---|---|
| MUSIC-001 | Spisak numera sa izvorom (folder / plejlista) | gotovo |
| MUSIC-002 | Dodir bira numeru, ne pušta je | gotovo |
| MUSIC-003 | Plejer: veliko dugme, tajmer, naslov | gotovo |
| MUSIC-004 | Fade-in 10 sekundi | gotovo |
| MUSIC-005 | Prsten po ivici ekrana (za sada ravna linija) | gotovo |
| MUSIC-006 | Dodavanje pojedinačnih numera sa telefona | gotovo |
| MUSIC-007 | Sopstveni pregled fajlova (ulazak u foldere, ceo folder / označene) | gotovo |
| MUSIC-008 | Zbijen spisak (36 dp) + sklanjanje headera pri skrolovanju | gotovo |
| MUSIC-009 | Red čekanja (queue) | gotovo |
| MUSIC-010 | Dodir ubacuje numeru kao sledeću u redu | gotovo |
| MUSIC-011 | Dodir na aktivnu numeru je ponavlja | gotovo |
| MUSIC-012 | Skip napred / skip nazad | gotovo |
| MUSIC-013 | Fade-out na kraju i pri pauzi | gotovo |
| MUSIC-014 | Crossfade između dve numere | gotovo |
| MUSIC-015 | Prevlačenje po prstenu premotava pesmu | gotovo |
| MUSIC-016 | Talasni oblik u prstenu | gotovo (`just_waveform`) |
| MUSIC-017 | Podaci iz fajla: izvođač, album, trajanje | gotovo (`audio_metadata_reader`) |
| MUSIC-018 | ~~Pregled foldera sa ulaskom u podfoldere~~ — urađeno uz MUSIC-007 | gotovo |
| MUSIC-019 | Rad u pozadini + kontrole u notifikaciji | gotovo (`audio_service`) |
| MUSIC-020 | Pretapanje naslova pri prelasku na sledeću numeru | gotovo |
| MUSIC-021 | Provera podrške za formate | gotovo |
| MUSIC-022 | Provera rasporeda na različitim veličinama ekrana | gotovo |

**Napomene uz pojedine stavke:**

- **MUSIC-014 (crossfade) je urađen tako što plejer sada drži dva plejera.**
  Jedan svira, drugi već ima učitanu sledeću numeru i čeka; posle preklapanja
  zamene uloge. Sledeća numera se **učitava unapred**, inače prelaz zapne dok
  se fajl otvara. Preklapanje ima prednost nad stišavanjem pred kraj, da ne
  nastane rupa između numera.
- **MUSIC-019 je urađen preko `audio_service`, a ne `just_audio_background`.**
  Jednostavniji paket u svojoj dokumentaciji izričito kaže da radi samo sa
  **jednim** plejerom, a naš ih drži dva zbog preklapanja numera (MUSIC-014).
  `audio_service` dozvoljava više plejera, pa se preklapanje ne gubi.
  Sloj `BackgroundAudioHandler` ne pušta zvuk sam — samo prosleđuje komande
  kontroleru i javlja sistemu šta se dešava.
- **Pristup fajlovima (odluka od 9. septembra 2026):** aplikacija ima
  **sopstveni pregled fajlova**, ne koristi sistemski birač. Sistemski birač na
  Androidu vraća `content://` adresu foldera koja ne može da se čita, pa je
  „ceo folder" bio neupotrebljiv. Umesto toga se traži dozvola **„Pristup svim
  fajlovima"**, koju korisnik odobrava u sistemskim podešavanjima; bez nje
  ekran objasni zašto je potrebna i vodi do nje.

#### Odbačeno (odluka od 9. septembra 2026)

Iz spiska stare muzičke aplikacije **ne prenosi se**:

- **Vintage hi-fi izgled, crno-platinasta tema sa metalnim gradijentima.**
  Paleta aplikacije je propisana i jedinstvena za sve tabove: skoro crno sa
  tamno-tirkiznim prizvukom, gde boja uvek nosi značenje a nikad ukras.
  Muzika tab ne sme da izgleda kao druga aplikacija.
- **Talasni oblik koji se računa u realnom vremenu** (Android `MediaExtractor`
  / `MediaCodec`). Amplitude se računaju jednom po pesmi i keširaju — računanje
  u toku crtanja obara 60 fps na prstenu, a `MediaExtractor` je uz to Android
  klasa, dok je ovo jedan kod za Android i iOS.

### LED tab

Nije započet. Pre prvog feature-a treba potvrditi koji hardver/protokol se
koristi i šta se dešava kada Bluetooth nije dostupan.

**Analiza konkurencije:** postoji zaseban dokument `LED_CHORD_ANALIZA.md` —
pregled aplikacije *LED Chord* (spledapps, 500.000+ preuzimanja, 3,4★), koja
radi isti posao: generički Bluetooth daljinski za jeftine LED kontrolere
(SP107E i slični). Pročitati ga pre prvog LED feature-a.

Ono što iz te analize već sada važi kao pravilo za naš LED tab:

- **Redosled RGB kanala se ne pretpostavlja, nego proverava sa stvarnim
  hardverom.** Najčešća pritužba kod konkurencije je da plavo daje zeleno —
  greška koja se u razvoju bez uređaja na stolu lako previdi.
- **Promena jačine ne sme da obori vezu.** Kod LED Chord-a aplikacija tu puca
  i posle toga se uređaj više ne povezuje; taj put se testira izričito.
- **Ponovno povezivanje posle gubitka Bluetooth signala je očekivan slučaj,
  ne izuzetak** — po recenzijama je to glavni razlog zbog kog ljudi odustanu.
- **Podešavanje uređaja (čipset, RGB redosled, broj piksela) stoji odvojeno
  od svakodnevne kontrole** boja i efekata.
- Ako se ikad doda zvučni režim, **osetljivost mora biti podesiva traka**, ne
  fiksna vrednost.

**Tri pitanja koja moraju da se odgovore pre prvog LED feature-a**
(prepisana iz analize):

1. jedan konkretan protokol (npr. SP107E) ili generički pristup sa spiskom
   podržanih čipova?
2. da li treba zvučni/reaktivni režim, i da li se napaja iz mikrofona telefona
   ili iz onoga što svira na Muzika tabu?
3. da li su u planu i 2D paneli (matrix), ili samo trake — to određuje da li
   kontrolni ekran od početka treba prekidač tipa uređaja

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
  Izvedeno tako da se na kartici pojavi **olovka** koja otvara unos u listu
  odozdo — ekran se time ne pretvara u obrazac, a podatak se menja jednim
  dodirom. Bez dozvole je kartica ista, samo bez olovke.
- **Menjanje logotipa u headeru traži login** — to je funkcija managementa,
  ne obična podešavanja.

Login ekran izgleda kao Home ekran; razlika je samo u tome što on ima
popunjavanje tabele koja se posle deli timu.

#### Spisak feature-a za prijavu i admin konzolu

| ID | Šta | Status |
|---|---|---|
| ADMIN-001 | Prijava i odjava, uloge `glavni` i `user` | gotovo |
| ADMIN-002 | Bez prijave je aplikacija samo za čitanje | gotovo |
| ADMIN-003 | Prijavljeni korisnik i dugmad u headeru | gotovo |
| ADMIN-004 | Polja na Home tabu se popunjavaju kad ima dozvole | tekstualna gotova; datum, sat, trajanje i polazak sledeći |
| ADMIN-005 | Izbor kategorija opreme za događaj + dodela vozila | gotovo |
| ADMIN-006 | Izmena delova kategorije iz konzole | sledeće |
| ADMIN-007 | „Create and share" — dodela događaja timu | |
| ADMIN-008 | Zamena lokalne prijave Firebase Auth-om | |

**Nalozi za probu** (upisani u kodu, samo za razvoj):
`filip` / `1234` — uloga `glavni`; `ana` / `1111` — uloga `user`.
Ovo nije zaštita podataka nego **prekidač između čitanja i unosa**; prava
provera identiteta je posao backenda (ADMIN-008).

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

**Izuzetak od pravila o dodirnoj meti** postoji samo na spisku numera
(36 dp umesto 48) — objašnjen je u odeljku „Muzika tab". Svuda drugde
važi 48 dp.

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
  final List<String> categoryIds; // izabrane kategorije opreme
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
| Talasni oblik pesme | — | **`just_waveform`** (izabrano) |
| Podaci iz audio fajla | — | **`audio_metadata_reader`** (izabrano) |
| Bluetooth (LED tab) | planirano `react-native-ble-plx` | `flutter_blue_plus` |
| Dozvole (Bluetooth, fajlovi) | Expo permissions | `permission_handler` |
| Vremenska prognoza | — | `http` + Open-Meteo (bez ključa) |
| Pristup fajlovima i dozvole | — | `permission_handler` (zaključan na 12.0.0) |

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

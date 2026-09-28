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

**U listovima za unos prazna polja ostaju prazna.** Pravilo „Datum nije unet"
važi za **kartice**, gde podatak stoji sam. U listu „Kada i koliko" svaki red
ima naziv pored sebe i vodi u kalendar, pa se iz konteksta zna šta se bira —
tu bi „Nije unet" bio suvišan tekst.

Uz to na Home ekranu:

- **pull-to-refresh** (povlačenje nadole ponovo učitava podatke o događaju)
- **greška pri učitavanju**: poruka + dugme "Pokušaj ponovo" umesto praznog ekrana (HOME-021)
- **header sa logotipom tima** (iznad tabova): logo bira korisnik sa ulogom `glavni`,
  ostali ga samo vide. **Ime prijavljenog se u headeru ne ispisuje** — stajalo
  je preko banera, a piše u konzoli, gde mu je i mesto. **Izabrana slika se prekopira u trajni folder
  aplikacije**, a ne ostavlja tamo gde je `image_picker` spusti — njegov
  folder je privremen i Android ga briše, pa je logotip nestajao pri
  reinstalaciji. Svaka nova slika dobija novo ime (nosi vreme čuvanja), jer
  bi inače Flutter i dalje crtao staru iz svog keša; stara kopija se briše
  tek kad je nova upisana. Ako kopije nema, zapis se čisti i header se vraća
  na ime aplikacije.

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

**Delovi opreme se unose SAMO u konzoli** (pravilo od 10. septembra 2026, na
izričit zahtev vlasnika). Ni na Lager tabu ni pri dodeli opreme događaju ne
postoji dodavanje ni brisanje stavki.

Razlog je sam smisao Lagera: vlasnik zna svoj lager i **jednom** upiše šta
kojoj kategoriji pripada. Pred nastup se onda ne kucaju stavke nego se
**klikne kategorija** — u tome je ušteda vremena. Ako nešto ne treba da se
nosi, ide se u konzolu i skida se sa te kategorije, a ne krpi po događaju.

Iz toga sledi:

- **Lager tab samo čekira.** Nema „Dodaj stavku", nema brisanja stavki.
- **Izbor opreme za događaj bira samo kategorije.** Nema olovke koja otvara
  delove.
- Sve što menja katalog stoji na jednom mestu: konzola → **„Oprema firme"**.

0. **Manager u konzoli pravi sam spisak kategorija** koje firma poseduje —
   Vatra, Svila, Tehnika, Kablovi, LED, Robot… To je ekran **„Oprema firme"**,
   do kog se stiže iz konzole. Tu se kategorije prave, preimenuju i brišu, a
   dodir na kategoriju otvara njene delove.
1. **Manager u konzoli bira kategorije** za događaj — na primer *Vatra*,
   *LED*, *Ring*. Bira ih iz spiska kategorija koje firma ima.
2. Izbor po događaju stoji kao **dugmići, ne spisak sa kvačicama** — isto
   kao „Ko radi". Preglednije je i odmah se vidi šta je uzeto; olovka na
   dugmetu otvara delove te kategorije.
3. **Lager čita izbor iznova svaki put kad se otvori taj tab.** Oprema se
   bira na Home tabu, a Lager sve vreme stoji u stablu (da bi mu se sačuvale
   kvačice), pa se sam od sebe ne bi osvežio. Bez toga si birao opremu i na
   Lageru gledao staro stanje.
4. **Lager tab prikazuje izabrane kategorije i sve delove koji im pripadaju.**
   Kategorija je sekcija u checklisti, a njeni delovi su stavke u njoj.
   Ono što nije izabrano se ne prikazuje — na nastupu ne treba prelistavati
   opremu koja se ne nosi.
5. **Delovi kategorije se takođe menjaju iz manager konzole** — kad se u
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

1. **Dodir na numeru je pušta — osim u God mode-u** (promenjeno 25.
   septembra 2026; ranije dodir nikada nije puštao zvuk). Korisnici su se
   žalili da nije intuitivno da za slušanje muzike ima toliko koraka.
   - **God mode isključen:** dodir odmah pušta numeru, uz pretapanje ako je
     Fade uključen. Pauzirana numera na dodir nastavlja.
   - **Dodir na numeru koja svira pušta je još jednom, preko sebe**
     (odluka od 28. septembra 2026). To je DJ potez: dok prva ide na
     petnaestoj sekundi, uvod se vrati preko nje i dve se preklope. U red
     ulazi njena kopija, pa se na nju pređe pretapanjem; bez `Fade`
     prelaz je odmah, dakle numera kreće iz početka.
   - **Isto važi i sa talasa**: kad se ista numera pusti sa izabranog
     mesta, taj deo ulazi **preko** onoga što svira. Tako se preko refrena
     vraća bilo koji deo pesme, ne samo uvod. Bez `Fade` se numera samo
     premota na to mesto — nema šta da se preklopi.
   - **God mode uključen:** dodir samo bira numeru (breskva red + kvačica) i
     sprema je u pozadini. Pušta se sa **Ekrana 2**: ogromno okruglo dugme i
     veliki prekidač Fade in, koji važi samo za to jedno puštanje.
   - Prekidači Fade i God mode se menjaju **samo prevlačenjem** (`SlideSwitch`)
     — dodir ih ne menja i ekran kaže „Prevuci prekidač". Tako ih okrznut
     prst ne prebaci usred programa.
2. **Izvor numere se uvek vidi** (folder ili plejlista). U žurbi se lako pomeša
   pesma iz telefona sa pesmom pripremljenom za nastup. U zbijenom spisku izvor
   se prikazuje ikonicom, jer za tekst nema mesta.
   Na tom ekranu stoji i **sopstveni prekidač Fade**, gore desno (dodato
   26. septembra 2026). Talas je mesto gde se bira **koji deo** druge
   numere ulazi, pa se tu i odlučuje da li prethodna izlazi pretapanjem —
   tako se delovi pesama mešaju uživo, bez izlaska na spisak. Prekidač
   važi samo za to puštanje i kreće od onoga što stoji na Muzika tabu.

3. **Numera se skida sa spiska kroz „Uredi"** (MUSIC-027; do 25. septembra
   2026 dugim pritiskom). Dug pritisak sada otvara **talasni oblik**: ceo
   ekran, talas odozgo nadole, skrol kroz pesmu, dva dodira za zum,
   zadržavanje prsta pušta numeru od tog mesta (sa pretapanjem ako nešto
   već svira). U režimu „Uredi" uz svaku numeru stoji crveni minus.

   - **Ni prevlačenje.** Usred nastupa se prst lako okrzne o
     ekran; prevlačenje bi tada skidalo numere samo od sebe.
   - List za potvrdu izričito kaže da **fajl ostaje na telefonu**. Bez toga
     „skloni" zvuči kao brisanje muzike.
   - **Numera koja svira se ne skida.** Ni ona, ni njene kopije: dok svira,
     njen red se ne dira. Pravilo je tako jedno i predvidivo, a muzika ne
     staje zbog sređivanja spiska.
   - U traci stoji i **praznjenje celog spiska**, za slučaj da je ceo folder
     pogrešan.

4. **Spisak numera se pamti između pokretanja** (MUSIC-026). Ranije je živeo
   samo dok je aplikacija otvorena, pa bi izvođač pred svaki nastup ponovo
   tražio isti folder. Pamte se **samo putanje do fajlova**: izvođač i
   trajanje se iznova čitaju iz fajla, pa bi njihovo pamćenje značilo da
   zastare čim se fajl zameni. **Fajl kojeg više nema se preskače** — na
   nastupu numera koja ne može da se pusti samo smeta.

   Čitanje ne drži ekran: spisak se prikaže odmah, a zapamćene numere ulaze
   čim se pročitaju. Ako pamćenje pukne, Muzika tab se otvara prazan umesto
   da javi grešku — to je udobnost, ne uslov za rad.

   **Čitanje ide u zasebnoj niti i u turama** (od 27. septembra 2026).
   Čitanje oznaka je sinhrono i za folder od nekoliko stotina numera traje;
   dok se radilo na glavnoj niti, ekran je zastajkivao, a ceo spisak je stajao
   na `--:--` dok poslednji fajl ne bude gotov. Sada se svaka numera čita u
   `Isolate.run`, a spisak se osvežava **na svakih dvadeset pročitanih**, pa
   trajanja ulaze u hodu.

   **Izvođač i trajanje se čitaju iz fajla jednom i pamte se u keširanom
   spisku, ali i u samim dodatim numerama** (ispravka od 27. septembra 2026).
   Spisak se pri povlačenju nadole gradi iznova od dodatih numera, a one se
   pamte samo kao putanje — dok se pročitani podaci nisu vraćali i u njih,
   jedno povlačenje je obrisalo izvođača i trajanje sa celog spiska, i vraćalo
   ih tek ponovno pokretanje aplikacije.

5. **Naziv numere se prikazuje bez nastavka fajla.** „.mp3" na kraju svakog
   reda ne kaže ništa, a jede širinu na uskom ekranu. Ime koje počinje tačkom
   je skriven fajl, ne nastavak, pa se ne dira.

6. **Svaki podatak može da nedostaje.** Numera bez naziva pada na naziv fajla,
   numera bez poznatog trajanja prikazuje `--:--`, numera koja ne može da se
   otvori javlja grešku umesto da obori plejer.
   Kontrole iznad plejliste (Fade, God mode, jačina, Ekran 2) **nemaju okvire**
   (odluka od 26. septembra 2026). Bele kartice oko njih su jele visinu, a
   prekidač i slovo se i sami prepoznaju; red je time spušten sa 60 na 44 dp.

7. **Jačina zvuka ima tri stepenika, ne klizač** (odluka od 9. septembra
   2026). Prikazuje se **jednim slovom** u traci uz spisak, koje se dodirom
   vrti u krug:

   | Slovo | Jačina |
   |---|---|
   | `L` | 100% |
   | `E` | 35% |
   | `F` | 5% |

   Vrednosti su namerno spuštene (ranije 50% i 15%): **glasnoća se ne čuje
   linearno**. Pola amplitude ne zvuči kao pola jačine nego tek malo tiše, pa
   se razlika između stepenika jedva osećala.

   Razlog: na nastupu se ne pogađa procenat, nego se bira između „puno",
   „pola" i „tiho u pozadini". Bitno je i to što **mikseta nije nadohvat** —
   zvuk do nje ide Bluetooth-om, pa se muzika mora stišati iz aplikacije. Slovo je u boji `accent` kad je puna jačina, a
   u `warning` kad je stišano — stišan zvuk je stanje na koje treba obratiti
   pažnju. Zadata jačina važi i za sva pretapanja: preklapanje ide do nje, ne
   do pune jačine, inače bi stišana muzika skakala nazad na 100%.

   **Brzina ploče** stoji u istom redu, kao ikonica ploče sa brojem ispod:
   **1.0 / 0.9 / 0.8 / 0.7**, dodir je vrti u krug (odluka od 27. septembra
   2026). Zvuk se usporava **zajedno sa visinom tona**, kao kad se uspori
   gramofonska ploča — zato se i zove ploča, a ne „brzina reprodukcije".
   Do nove brzine se **klizi** pola sekunde, da se čuje kao pokret, a ne kao
   kvar. Ikonica je u boji `warning` dok zvuk nije na normalnoj brzini, jer
   je to stanje koje se lako zaboravi.

   Brzina se **pamti preko numera**: sledeća pesma kreće istom brzinom, kao
   što se ni platter na gramofonu ne ubrza sam kad se promeni ploča.
   Scratch (vučenje zvuka prstom napred-nazad) **još nije urađen** — to nije
   podešavanje nego nov sloj obrade zvuka, pa ide zasebno.

8. **Red u spisku je 44 dp** (od 26. septembra 2026; ranije 60) — svesno
   ispod minimalne dodirne mete od 48 dp, zbog gustine spiska na nastupu.
   Red je preko cele širine ekrana, pa je meta i dalje široka.

   Uz to je **uvećanje sistemskog fonta u redu ograničeno** (do 1,1), isto
   kao kod sistemskih birača datuma i sata: na krupnom sistemskom fontu bi
   dva reda teksta prerasla visinu reda i na ekran bi stale tri numere.
   Ista granica (1,15) važi i za karticu „Sada svira".

   **Kartica plejera ima istu visinu u svakom stanju.** Reč „Pauza" je
   obična reč u redu koji uvek stoji, a ne pilula koja se pojavljuje i
   nestaje — inače kartica raste i skuplja se, a spisak ispod nje
   poskakuje i izvođač izgubi red koji je gledao.

9. **Traka uz spisak ima dva reda.** Gore je premotavanje i pauza — ono što
   se dira u hodu. Dole su tri odluke druge vrste: **folder**, ulaz u
   **nastupni ekran** i **jačina**. Donji red je visok **36 dp**, isti svesni
   izuzetak od 48 dp: ta tri dugmeta se ne traže u žurbi, a spisak numera time
   dobija prostor.

   **Fajlovi se otvaraju samom ikonicom foldera** u tom redu — natpis
   „Pregledaj fajlove" je otpao. Natpis ostaje jedino u praznom stanju, dok
   spiska nema pa nema ni trake; inače numere ne bi imale odakle da se dodaju.

#### Kuda ide zvuk: Bluetooth do miksete (razjašnjeno 9. septembra 2026)

**Telefon se preko Bluetooth-a povezuje sa risiverom u mikseti.** To je
standardni način rada: voditelj drži telefon u ruci i kreće se po prostoru,
daleko od miksete, a zvuk ide bežično do razglasa.

Ovo je **drugi sloj od LED-a** i ne treba ih mešati:

| | Čime se povezuje | Šta aplikacija radi |
|---|---|---|
| Zvuk → mikseta | **Bluetooth** (A2DP) | ništa posebno — Android sam usmerava zvuk na povezani uređaj |
| LED kontroler | **Wi-Fi** | aplikacija sama priča sa kontrolerom preko mreže |

Aplikacija **ne implementira Bluetooth za zvuk** — to radi sistem. Ali iz
ovakvog rada slede tri stvari koje se moraju poštovati:

1. **Jačina u aplikaciji (L / E / F) je ovde bitnija nego što izgleda.**
   Mikseta je daleko, ne prilazi joj se usred programa. Zato mora da postoji
   način da se muzika stiša iz same aplikacije, a ne samo na razglasu.
2. **Pad Bluetooth veze se ne obrađuje** (odluka korisnika, 9. septembra
   2026). Ako veza padne, Android vraća zvuk na zvučnik telefona. Predlog je
   bio da aplikacija to prepozna i stane uz poruku, ali korisnik je rekao da
   nije potrebno: „ako se diskonektuje povezaćemo ponovo". To se u praksi
   rešava rukom, za sekund, i ne treba mu aplikacija koja sama zaustavlja
   muziku. **Ne praviti taj feature bez novog dogovora.**
3. **Bluetooth unosi kašnjenje** (obično 100–200 ms). Sve što se meri na uho
   — kada tačno krene pretapanje, koliko traje fade — dešava se na razglasu
   nešto kasnije nego na ekranu. Nema šta da se popravi u kodu, ali se ne
   sme praviti feature koji zavisi od preciznog poklapanja sa ekranom.

Uz to, LED i zvuk rade **istovremeno**: Wi-Fi ka kontroleru i Bluetooth ka
mikseti stoje uporedo, pa se ni jedno ni drugo ne sme gasiti radi onog drugog.

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

**Talas se crta kao crtice sa razmakom, ne kao puna površina** (ispravka od
26. septembra 2026). Puna površina je na današnjoj, izravnatoj muzici
izgledala kao blok boje — sve je bilo na vrhu, pa se od talasa ništa nije
videlo. Uz razmak između crtica i blagu krivu (amplituda na 1,6) razlika
između tihog i glasnog se vidi.

**Zumiran talas pokazuje pravi detalj, ne razvučen isti** (od 28. septembra
2026). Iz fajla se izvlači **2400 vrednosti**, mnogo više nego što stane na
ekran, a crta se onoliko crtica koliko ih staje po visini (jedna crtica sa
razmakom uzima 3 dp). Svaka crtica uzima **najglasniju** vrednost iz svog
opsega — ne prosek, koji spljošti pesmu. Kad se zumira, opseg po crtici se
smanji, pa se pojavi detalj koji je dotle bio sabijen.

**Crta se samo ono što se vidi.** Niz ima 2400 vrednosti, a na ekran ih staje
nekoliko stotina; bez toga bi se pri svakom pomeraju prsta crtalo hiljadama
pravougaonika uzalud.

**Gornja traka ekrana sa talasom ne pripada talasu.** Zadržavanje prsta tamo
ne pušta numeru: pored prekidača Fade i dugmeta za zatvaranje se prst lako
zadrži, a muzika ne sme da krene od toga.

**Dok se talas računa, na ekranu piše dokle je stiglo.** Izvlačenje traje
nekoliko sekundi po numeri, a dotle se crta samo tanka, tiha linija — ranije
je ta linija bila debela i u boji numere, pa je ličila na kvar. Sama obrada
ide na 10 tačaka po sekundi zvuka: iz zapisa se ionako svodi na ~600
vrednosti, a finije samo duže traje na telefonu.

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

**Dodir uvek radi jedno te isto** (precizirano 9. septembra 2026): stavlja
tu numeru na mesto **„sledeća"**, odmah iza one koja svira. Nikada ne pušta
zvuk i nikada ne prekida ono što se čuje.

Osnovni tok:

1. gledaš spisak numera
2. **dodirneš pesmu** — ona ide na mesto „sledeća"
3. pritisneš **play** (u traci uz spisak ili veliko dugme u nastupnom ekranu)

Prelazak na sledeću pesmu usred programa:

1. dodirneš sledeću pesmu — ona je sada „sledeća", a prethodna i dalje svira
2. otvoriš nastupni ekran dugmetom sa uglovima
3. uključiš **Fade** ako hoćeš preklapanje
4. pritisneš **veliko dugme** — pesma koja svira izlazi, „sledeća" ulazi, i
   **obe sviraju u preklopu**. Bez `Fade` prelaz je odmah.

Ostalo:

- **dodir na numeru koja svira dodaje još jednu njenu kopiju** odmah iza nje.
  To je namerno, i to je taj trik: uvod se pusti ponovo i tako se kupi vreme
  na pretapanju dok se ne odluči šta dalje.
- numera koja je već negde u redu se dodirom **premešta** na mesto „sledeća",
  ne dodaje se drugi put
- **skip napred / nazad** pomeraju taj isti red za jedno mesto. Unazad je
  pametan: ako je pesma odmakla **3 sekunde ili više**, vraća je na početak;
  ako je tek počela, ide na prethodnu.
- **zvuk nikad ne kreće od dodira**, samo od dugmeta
- prelazak sa pesme na pesmu ide uz **kratko pretapanje naslova** (do 200 ms);
  ostatak ekrana se ne animira, po opštim pravilima za pokret

**Plejer ima dva nivoa** (dogovoreno 9. septembra 2026):

1. **Kontrole uz spisak** — prethodna, −10 s, plej/pauza, +10 s, sledeća.
   Dovoljno da se upravlja bez izlaska iz spiska.
2. **Nastupni ekran** — prsten, vreme, **ogromno dugme** i **jedan prekidač:
   Fade**.

   **Na tom ekranu pauze nema.** Veliko dugme uvek pušta, nikad ne pauzira.
   Ekran ima jedno jedino značenje: „pusti ono što je izabrano". Ako se
   usred programa dugme promaši, najgore što može da se desi jeste da numera
   krene — a ne da muzika stane pred publikom. Izlazi se strelicom nazad, a
   pauza stoji u traci uz spisak.

   **Dugme je šuplje:** obojena je samo ikonica, a kvadrat je obeležen
   linijom. Puna tirkizna površina preko četiri petine ekrana svetli kao
   lampa i vidi se iz publike, a ekran se otvara usred programa, u mraku.
   Linija i dalje kaže dokle se sme pipnuti dok se meta ne nauči napamet;
   **ceo kvadrat je dodirljiv, ne samo ikonica**. Naziv numere i vreme stoje **sitno i u `textSecondary`**: to su
   podaci koji se provere jednom, a krupno belo na crnom usput štipa oči.
   Sve što je krupno na tom ekranu jeste dugme. Ništa više. Jedan prekidač umesto tri — na nastupu se ne bira
   između opcija.

   Dugme je **kvadrat koji zauzima otprilike četiri petine ekrana** (odluka
   od 9. septembra 2026). Razlog je konkretan: zamišljeno je za voditelja
   koji drži mikrofon i govori, a ne gleda u telefon — dovoljno je da pipne
   bilo gde po sredini ekrana, ne mora da gađa malu metu. Kvadrat, a ne krug,
   jer iz istog prostora daje veću metu. Na niskom ekranu ili uz uvećan
   sistemski font se smanjuje, da sadržaj ne ispadne.

`Fade` znači sve troje odjednom: ulazak iz tišine, izlazak u tišinu i
**preklapanje** kad se pređe sa numere koja svira na izabranu.

**Bez `Fade` pauza zvuči kao ploča koja staje** (odluka od 27. septembra
2026). Umesto kratkog spuštanja jačine, zvuk se za oko sekund **uspori i
spusti u visini tona**, pa utihne — kao gramofon kome je stao platter. To je
efekat, ne podešavanje: sam se vrati na normalnu brzinu, pa sledeće puštanje
kreće kako treba.

Sa uključenim `Fade` pauza ostaje ono što je bila — mirno povlačenje pred
publikom, šest sekundi, bez efekta. Tako izvođač bira šta hoće samim
prekidačem koji već ima.

**Izlazak u tišinu na pauzu traje 3 sekunde** (skraćeno sa šest 27. septembra
2026, jer je šest bilo predugo čekanje).
Toliko da se muzika pred publikom povuče kao namera, a ne kao kvar — voditelj
u tom vremenu stigne da uzme mikrofon i progovori preko nje. Kad je `Fade`
isključen, pauza i dalje ima kratkih pola sekunde, samo da nestane „klik" na
prekidu; naglo sečenje ne postoji ni u jednom slučaju.

**Dužina ulaska iz tišine se bira** (odluka od 27. septembra 2026):
**1, 4 ili 8 sekundi**, dodirom na broj koji stoji uz prekidač `Fade` —
isto kao slovo L / E / F za jačinu. Podrazumevane su 4 sekunde: 1 s je gotovo
rez, 8 s je uvod pred publiku, a 4 s je ono što najčešće treba.

Ista dužina važi i za **preklapanje** dve numere, kako je i do sada bilo
vezano: preklapanje traje koliko i ulazak iz tišine. **Izlazak na pauzu je
druga stvar** i ostaje 6 sekundi.

Time je otpala ranija razlika između velikog dugmeta (10 s) i plej dugmeta u
traci (5 s): otkad se broj bira jednim dodirom, dva različita ulaska samo
zbunjuju — važi ono što piše na dugmetu.

**Pretapanje ide po glasnoći koja se čuje, ne po amplitudi** (ispravka od
26. septembra 2026). Pola amplitude nije pola glasnoće nego oko −6 dB, što se
jedva primeti; zbog toga je pravolinijsko pretapanje zvučalo pogrešno na oba
kraja — numera koja izlazi kao da ne izlazi, a ona koja ulazi kao da upada.
Rampa je zato pravolinijska **u decibelima**, preko 45 dB: svaki deo puta
oduzme isto toliko glasnoće. U sredini preklopa se obe numere čuju tiše, i to
je namerno — jedna se povlači, druga dolazi. Isto važi i za ulazak iz tišine i
za izlazak na pauzu.

**U preklopu nijedna numera ne ode do tišine** (odluka od 27. septembra
2026). Ona koja izlazi se spušta samo do **20%**, a ona koja ulazi kreće od
**10%** — pa se kroz ceo prelaz čuju obe. Kad su obe strane išle do kraja, u
sredini preklopa je nastajala rupa i zvučalo je kao da je muzika stala.
Pošto se preklop završi, stara numera još četvrt sekunde utihne sa 20% na
nulu, da se prekid ne čuje kao „klik".

**Premotavanje ne prekida pretapanje** (odluka od 9. septembra 2026). Dok
preklapanje traje, izvođač sme da prevlači po prstenu ili da preskače, i da
tako dovede novu numeru na pravo mesto — a pretapanje i dalje ide. To je i
poenta: u preklopu se doterivanje ne čuje, pa ima prostora za finu izmenu i
greška se teže primeti. Zbog toga preklapanje traje isto koliko i ulazak iz
tišine; ranije je stajalo 6 sekundi, što nije davalo vremena ni za šta.
Stišavanje pred kraj numere se **ne pokreće dok pretapanje traje**, da se dva
pretapanja ne otimaju oko istog plejera.

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
| MUSIC-023 | Dodir stavlja numeru na mesto „sledeća"; dodir na aktivnu dodaje kopiju | gotovo |
| MUSIC-024 | Jačina zvuka u tri stepenika (L / E / F) | gotovo |
| MUSIC-025 | Veliko dugme kao kvadrat preko četiri petine ekrana | gotovo |
| MUSIC-026 | Spisak numera se pamti između pokretanja | gotovo |
| MUSIC-027 | Skidanje numere sa spiska (dug pritisak) i praznjenje spiska | gotovo |

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

Započet 10. septembra 2026. Pre prvog feature-a treba potvrditi koji hardver/protokol se
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

**Veza ide preko Wi-Fi-ja, ne Bluetooth-a** (odgovor korisnika, 9. septembra
2026). Korisnik kaže da se do sada, u svakoj aplikaciji koju je koristio,
povezivao tako što bi **uređaj našao u spisku Wi-Fi mreža**, u meniju koji se
izvlači prstom nadole. To znači da kontroler pravi **sopstvenu Wi-Fi mrežu**
(pristupnu tačku) na koju se telefon zakači, pa aplikacija sa njim priča
preko lokalne mreže.

Šta iz toga sledi:

- **`flutter_blue_plus` ne treba za LED.** Umesto Bluetooth-a ide obična
  mrežna veza (TCP/UDP soket) ka kontroleru na lokalnoj adresi. Paket se bira
  tek kad se zna tačan model.
  **Pažnja:** ovo ne znači da Bluetooth nije u igri — on nosi **zvuk** do
  miksete (vidi „Kuda ide zvuk" u Muzika delu). Dva različita sloja.
- **Bluetooth dozvole otpadaju**, a s njima i najmučniji deo dozvola na
  Androidu.
- Zato dobija na značaju sasvim drugo pitanje: **šta se dešava kad telefon
  nije na toj mreži** — treba jasno reći „nisi na mreži kontrolera" i uputiti
  korisnika u Wi-Fi podešavanja, umesto da ekran ćuti.
- Kad je telefon na kontrolerovoj mreži, **nema interneta** — a Home tab vuče
  prognozu i karte. To se mora predvideti: te kartice tada javljaju grešku,
  ne smeju da obore ekran.
- Treba i dalje saznati **tačan model kontrolera** (piše na samom uređaju ili
  na kutiji), jer se protokol razlikuje od modela do modela.

**Kontroler je Magic Home** (odgovor korisnika, 10. septembra 2026). To je
poznata porodica Wi-Fi LED kontrolera (LEDENET / Magic Home / „Flux LED"),
pa je protokol poznat i ne mora da se pogađa:

| Šta | Kako |
|---|---|
| Veza | **TCP, port 5577** |
| Pronalaženje uređaja | **UDP broadcast na port 48899**, poruka `HF-A11ASSISTHREAD`; uređaj odgovara sa `IP,MAC,MODEL` |
| Uključivanje | `71 23 0F` + kontrolni zbir |
| Isključivanje | `71 24 0F` + kontrolni zbir |
| Boja | `31 RR GG BB WW 00 0F` + kontrolni zbir |
| Stanje uređaja | `81 8A 8B` + kontrolni zbir |

**Kontrolni zbir** je zbir svih prethodnih bajtova po modulu 256 — poslednji
bajt svake poruke.

Šta iz toga sledi za našu izvedbu:

- **Nije potreban nijedan nov paket.** Sve staje u `dart:io`: `RawDatagramSocket`
  za pronalaženje uređaja i `Socket` za komande. `INTERNET` dozvola već stoji
  u manifestu, a lokalna mreža na Androidu ne traži ništa posebno.
- **Redosled boja se ne pretpostavlja.** Magic Home kontroleri dolaze kao RGB,
  GRB ili BRG. Najčešća pritužba na konkurenciju je bila da „plavo daje
  zeleno". Zato u podešavanjima stoji izbor redosleda, a proverava se sa
  uređajem na stolu.
- **Ručni unos IP adrese mora da postoji** pored automatskog pronalaženja:
  broadcast ume da ne prođe kroz neke rutere, a bez rezervnog puta bi tada
  ceo tab bio neupotrebljiv.
- **Kad telefon nije na mreži kontrolera**, ekran to kaže i vodi u Wi-Fi
  podešavanja, umesto da ćuti ili da se vrti u prazno.

#### Spisak LED feature-a

| ID | Šta | Status |
|---|---|---|
| LED-001 | Pronalaženje kontrolera na mreži (UDP broadcast) | gotovo |
| LED-002 | Ručni unos IP adrese, kad broadcast ne prođe | gotovo |
| LED-003 | Paljenje i gašenje | gotovo |
| LED-004 | Izbor boje iz palete | gotovo |
| LED-005 | Izbor redosleda boja (RGB / GRB / BRG) | gotovo |
| LED-006 | Jačina svetla | gotovo |
| LED-007 | Pamćenje poslednjeg kontrolera | gotovo |
| LED-008 | Scene i efekti (ugrađeni u kontroler) | gotovo |

**Efekte vrti sam kontroler, ne telefon.** Zato rade i kad se telefon
zaključa ili izgubi mrežu — na nastupu presudno: rasveta ne sme da stane zato
što je nekome pao Wi-Fi. Aplikacija samo pošalje broj efekta i brzinu.
**Efekat i boja se isključuju** — kontroler radi ili jedno ili drugo, pa izbor
boje gasi efekat i obrnuto.

**Kontrole se vide i pre povezivanja**, samo ne rade. Ranije ih uopšte nije
bilo dok se kontroler ne nađe, pa je tab delovao prazno i nije se videlo šta
uopšte nudi.

**Jačina svetla nema svoju komandu.** Magic Home je nema — šalje se **ista
boja, utamnjena**. Zato boja i jačina žive zajedno u kontroleru: kad bi se
pamtile odvojeno, promena jednog bi poništila drugo. Klizač šalje komandu
**tek kad se prst podigne**, jer bi svaki pomeraj bio nova poruka i svetlo bi
poskakivalo. Najniža vrednost je 5%, ne 0 — nula je gašenje, a za to postoji
dugme.

**Kontroler se pamti** (adresa i redosled boja), pa se pred nastup nudi
„Poveži se ponovo" umesto traženja mreže iznova. Redosled se pamti jer je
**svojstvo samog uređaja**: isti kontroler će i sledeći put očekivati isto.

**Prvo što treba proveriti sa uređajem na stolu:** da li boje izlaze tačno.
Ako plavo daje zeleno, menja se redosled u samom tabu — to je stvar
kontrolera, ne aplikacije, i zato izbor stoji na ekranu.

**Pitanja koja još stoje** (odgovoriti pre nego što se pređe na efekte):

1. da li su u planu i 2D paneli (matrix) ili samo trake?
2. da li treba zvučni/reaktivni režim, i da li se napaja iz mikrofona telefona
   ili iz onoga što svira na Muzika tabu?

### Više događaja (dogovoreno 9. septembra 2026)

Do sada je aplikacija radila sa **jednim** događajem. To je bio propust: čim
postoji delegiranje, i onaj ko dodeljuje i onaj kome je dodeljeno imaju
**više događaja pred sobom** — često i više u istom danu.

**Spisak događaja je prvi ekran aplikacije.** Kad se izabere događaj,
otvaraju se četiri taba za **taj** događaj; strelica nazad vraća na spisak.
Odluka je korisnikova, uz dva razloga:

- na poslu se aplikacija otvara sa već poznatim pitanjem „koji mi je sledeći" —
  spisak je odgovor na to pitanje, ne prepreka pred njim
- manager time dobija pregled delegiranog **bez posebnog ekrana** — to je isti
  spisak, samo drugi filter

**Kako je spisak organizovan:**

- grupisan po vremenu: *Danas*, *Sutra*, *Ova nedelja*, *Kasnije*, pa
  *Prošli* na dnu
- unutar dana poređan **po satu početka**, i sat stoji u redu — više nastupa
  istog dana je uobičajeno, pa se redosled mora videti na prvi pogled
- red nosi: sat, naziv (`7 Mia / 2h`), mesto. Datum se ne ponavlja u redu jer
  ga nosi grupa
- **prekidač „Moji / Delegirani"** vidi samo onaj ko ima dozvolu za
  delegiranje; ostalima stoji samo njihov spisak, bez prekidača

**Spisak se prati uživo** (od 26. septembra 2026). Servis uz `loadEvents()`
ima i `watchEvents()`, koji vraća tok: nova vrednost stiže sama čim se u bazi
nešto promeni. Razlog je konkretan — spisak stoji u stablu i dok se gleda
pojedinačan događaj (da muzika ne stane), pa bi inače pokazivao ono što je
zatekao pri otvaranju. Izvođač tako događaj koji mu je upravo dodeljen vidi
bez povlačenja nadole i bez ponovnog pokretanja aplikacije.

Povlačenje nadole ostaje, ali sada služi samo za **pokušaj ponovo posle
greške** — kad nema mreže, ruka ionako traži taj pokret.

**Obaveštenje (push) kad ti neko dodeli događaj ne postoji** i nije isto što i
ovo: traži Firebase Cloud Messaging i deo koji radi na serveru. Zasebna odluka.

**Šta iz toga sledi za podatke:**

- `Event` nosi **ko ga je napravio** (`createdBy`) i **kome je dodeljen**
  (`assignedTo`, spisak imena/ID-jeva) — bez toga nema ni „moji" ni
  „delegirani"
- servis dobija `loadEvents()`; koji se vraćaju zavisi od toga ko je prijavljen
- **koji je događaj otvoren pamti se na jednom mestu** koje Home i Lager oba
  gledaju, kao što oba gledaju u `AuthService`. Nikad dva izvora istine o tome
- **Muzika i LED se ne vezuju za događaj** — plejlista i rasveta su izvođačeva
  oprema, ne podatak o proslavi

#### Spisak feature-a za više događaja

Radi se pre ADMIN-007: dodela događaja timu nema smisla dok ne postoji spisak.

| ID | Šta | Status |
|---|---|---|
| EVENTS-001 | `createdBy` i `assignedTo` na `Event`, `loadEvents()` u servisu | gotovo |
| EVENTS-002 | Ekran spiska, grupisan po vremenu i poređan po satu | gotovo |
| EVENTS-003 | Izbor događaja otvara tabove za taj događaj, nazad vraća na spisak | gotovo |
| EVENTS-004 | Prekidač „Moji / Delegirani" za onoga ko delegira | gotovo |
| EVENTS-005 | Prazna stanja i greška pri učitavanju spiska | gotovo |
| EVENTS-006 | Vrsta događaja (rođendan, krštenje, svadba, nastup, festival) | gotovo |
| EVENTS-007 | Spisak se prati uživo (`watchEvents`) | gotovo |

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
- **Logotip se menja iz konzole, ne sa glavne strane** (odluka od
  9. septembra 2026). U headeru stoji **jedno jedino dugme**: bez prijave
  vodi u prijavu, sa prijavom u konzolu. Ranije su tu bile tri ikonice —
  prijava, promena i uklanjanje logotipa — i **prekrivale su sam baner**, a
  logotip se menja retko i ionako samo uz prijavu.

  Konzola je isti onaj ekran prijave: kad je neko već prijavljen, pokazuje
  **ko je prijavljen, opremu firme, logotip tima i odjavu** — tim redom.
  **Oprema stoji iznad logotipa** jer se logotip postavi jednom u životu, a
  oprema se dira stalno; kad je stajala dole, korisnik je nije ni našao. Izvođaču bez dozvole se
  logotip tu i ne nudi.

Login ekran izgleda kao Home ekran; razlika je samo u tome što on ima
popunjavanje tabele koja se posle deli timu.

**Kako je izvedeno „create and share" (9. septembar 2026):**

- na spisku događaja stoji dugme **„Nov događaj"**, vidljivo samo onome ko
  ima dozvolu `editEvent`
- ekran za nov događaj traži **samo ono bez čega događaj nema smisla**:
  vrsta, naziv, kada i koliko, i **ko radi**. Adresa, organizator, telefon i
  oprema se popunjavaju na Home tabu olovkama koje već postoje — isti unos se
  ne pravi dvaput
- **dodela ekipe je deo pravljenja, ne poseban korak** — događaj koji niko ne
  radi je samo beleška. Onaj ko pravi događaj je unapred čekiran, jer gotovo
  uvek i ide na njega
- posle pravljenja se događaj **odmah otvara**, da se posao nastavi u njemu
- dodela se menja i kasnije, karticom **„Ko radi"** na Home tabu. Ta kartica
  se razlikuje od **Učesnika**: *Učesnici* kažu ko šta radi na nastupu
  (glavni, vozač, pomoćni), a *Ko radi* kome se događaj uopšte pojavljuje u
  aplikaciji

### Ekipa: veštine i bodovi (dogovoreno 27. septembra 2026)

Uz opremu firme, u konzoli stoji i **Ekipa** — ko šta ume i koliko je odradio.
Do nje se stiže istim putem i istim pravom: samo uz prijavu, i menja je onaj
ko vodi ekipu.

**Veštine su katalog firme**, kao i kategorije opreme: manager jednom upiše
šta se kod njih radi (Vatra, Svila, Voditelj, Vozač, LED…), pa uz svakog
člana samo čekira. Slobodan unos bi značio da se ista veština piše na tri
načina, pa se po njoj ne bi moglo filtrirati.

**Veštine i bodove upisuje manager, ne sam član.** Spisak koji svako sebi
popunjava ne znači ništa, a bodovi bi bili šala. To brane i pravila baze:
čovek sme da promeni svoje ime, ali ne i svoje veštine ni bodove.

**Bodovi se dodeljuju ručno**, posle odrađenog posla — dugmad `+10`, `+25`,
`+50`, i oduzimanje po 10 za ispravku greške. Ne računaju se sami iz
odrađenih događaja: manager zna ko je šta stvarno radio, a aplikacija ne.

**Nivo je svakih 100 bodova**, i prvi nivo je 1 — čovek bez ijednog boda je i
dalje na nekom nivou. Sto je izabrano zato što se lako računa u glavi.
Uz traku uvek stoji i tačan broj bodova, jer traka sama kaže samo „negde oko
pola", a manageru treba brojka kad dodaje nove.

**Obrisana veština se skida i sa ljudi** — inače bi ostala zalepljena za njih
kao id koji više ništa ne znači.

**Dodela po veštini je filter, ne zahtev** (izbor korisnika): na događaju se
ne čekira šta treba, nego se u „Ko radi" bira po veštini ko ulazi u ekipu.

U listu „Ko radi" stoji red dugmića: **Svi** i po jedno za svaku veštinu.
**Jedna veština u jednom trenutku** — pitanje „ko zna i vatru i vožnju" se
pred nastup ne postavlja. Ponovni dodir na istu veštinu vraća ceo spisak.
Uz svako ime stoji i šta ta osoba ume, pa se vidi zašto je u spisku.

**Filter ne odčekirava nikoga.** Ko je već dodeljen a filter ga sakrio,
ostaje dodeljen — i to piše iznad spiska, da se ne pomisli da je ispao.

#### Spisak feature-a za ekipu

| ID | Šta | Status |
|---|---|---|
| TEAM-001 | Katalog veština firme (konzola) | gotovo |
| TEAM-002 | Ekran „Ekipa": veštine i bodovi po članu | gotovo |
| TEAM-003 | EXP traka i nivoi | gotovo |
| TEAM-004 | Filter po veštini u „Ko radi" | gotovo |

#### Spisak feature-a za prijavu i admin konzolu

| ID | Šta | Status |
|---|---|---|
| ADMIN-001 | Prijava i odjava, uloge `glavni` i `user` | gotovo |
| ADMIN-002 | Bez prijave je aplikacija samo za čitanje | gotovo |
| ADMIN-003 | Prijavljeni korisnik i dugmad u headeru | gotovo |
| ADMIN-004 | Polja na Home tabu se popunjavaju kad ima dozvole | gotovo |
| ADMIN-005 | Izbor kategorija opreme za događaj + dodela vozila | gotovo |
| ADMIN-006 | Izmena delova kategorije iz konzole | gotovo |
| ADMIN-007 | „Create and share" — dodela događaja timu | gotovo |
| ADMIN-008 | Zamena lokalne prijave Firebase Auth-om | gotovo |

**Ime pod kojim te ekipa vidi menja se u konzoli.** Podrazumevano stoji deo
mejla pre `@`, jer se **ljudi pamte po imenu, ne po adresi** — a to ime stoji
i u „Ko radi", gde bi spisak mejlova bio neupotrebljiv. Svako sme da promeni
svoje ime; **ulogu ne sme**, to brane i pravila baze.

**Sistemski birači datuma i sata crtaju se sa ograničenim uvećanjem teksta**
(do ~1,15) i sat se unosi **brojkama, ne brojčanikom**. Brojčanik se na uskom
telefonu sa uvećanim fontom raspadao — brojke su izlazile jedna preko druge.
Ostatak aplikacije poštuje sistemsko uvećanje u celosti; ovo je izuzetak samo
za tuđe, gotove ekrane.

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

- Reč **"rođendan" se ne piše u nazivu** — za to postoji zasebno polje
  **vrsta događaja** (vidi niže).
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

#### Vrsta događaja

Naziv je kratak, ali izvođač i dalje mora da zna **na šta ide** — nije isto
spremiti se za dečji rođendan i za svadbu. Zato je vrsta **zaseban podatak**
(`Event.type`), a ne deo naziva:

| Vrsta | Piše se |
|---|---|
| `rodjendan` | Rođendan |
| `krstenje` | Krštenje |
| `svadba` | Svadba |
| `nastup` | Nastup |
| `festival` | Festival |

- u **spisku događaja** vrsta stoji prva u donjem redu:
  `Rođendan · Novi Sad · 2h`
- na **Home kartici** vrsta stoji na mestu opšte reči „Događaj", pa se ne
  troši nijedan piksel viška: `Rođendan   12. septembar   16:00`
- **vrsta može da nedostaje** — tada na Home kartici piše opšte „Događaj", a u
  spisku se preskače. Događaj bez vrste je i dalje ispravan događaj.
- u bazi se piše bez naših slova (`rodjendan`, `krstenje`), da uvoz podataka
  ne zavisi od kodne strane

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

### Put do događaja (dogovoreno 27. septembra 2026)

Na kartici **Vreme polaska** stoji i koliko se vozi do adrese događaja, i kad
se najkasnije kreće.

**Meri se uvek od magacina**, ne od trenutne lokacije telefona. Ekipa kreće po
opremu, pa je taj broj tačniji — a aplikaciji time ne treba ni dozvola za
lokaciju ni nov paket. Adresa magacina se upisuje **u konzoli**, jednom.

**Bez saobraćaja u realnom vremenu** (izbor korisnika). Vreme je „koliko se
vozi kad je normalno". Izvori koji znaju gužvu, zatvorene ulice i udese traže
nalog, ključ i (kod Google-a) karticu; za prvu verziju je dogovoreno da se ide
sa besplatnim podacima. Kad to zatreba, menja se samo `RouteService` — ekrani
ga ne poznaju.

Izvedba, u istom duhu kao prognoza i mape:

| Šta | Čime | Zašto |
|---|---|---|
| Adresa u koordinate | **Nominatim** (OpenStreetMap) | bez naloga i ključa |
| Vreme vožnje | **OSRM** (`router.project-osrm.org`) | bez naloga i ključa |

Oba imaju pravila korišćenja za javne servere (Nominatim traži da se
aplikacija predstavi i najviše jedan zahtev u sekundi; OSRM-ov demo server je
za lagan saobraćaj). Za jednu ekipu je to u redu; ako aplikacija izađe šire,
prelazi se na svoj ili plaćen server.

**Pronađene koordinate se pamte** — i za magacin i za događaj — pa se adresa
ne traži pri svakom otvaranju. Pamti ih samo onaj ko ima dozvolu za izmenu.

**Vožnja je dopuna, ne uslov.** Kad nema adrese magacina, adrese događaja ili
mreže, kartica izgleda kao i ranije. Ništa se ne nagađa.

Kad se zna i početak događaja, kartica računa i **najkasniji polazak**
(početak minus vožnja). Ako je upisano vreme polaska kasnije od toga, piše
„Kasniš" u boji upozorenja — broj koji se ionako računa u glavi.

### Navigacija (odluka od 26. septembra 2026)

Ranije su tabovi stajali **gore, odmah ispod headera**, kao dugmad sa
zakošenom ivicom. Ta traka je uklonjena 26. septembra 2026 zajedno sa
widgetom `top_tab_bar.dart`; ono što je od nje ostalo jeste razlog zašto
ništa nije otišlo dole — telefon se često drži u držaču u vozilu i na
sastanku, gde se prilazi kažiprstom odozgo, a ne palcem odozdo.

**Između stranica se prevlači** (urađeno 26. septembra 2026). Redosled je
**Home · Muzika · LED · Lager**, a stranica se menja prevlačenjem levo-desno.

**Trake sa dugmadima Home / Muzika / LED / Lager više nema.** Otkad se
prevlači, ta dugmad su bila samo ponavljanje pokreta, a trošila su 82 dp —
na Muzika stranici je to razlika između tri i sedam numera na ekranu. Umesto
njih stoje **tačkice**: kažu na kojoj si stranici i koliko ih ima.
Tačkice se **ne dodiruju** — one su oznaka, ne dugme; meta od 6 dp bi ionako
bila premala za prst usred programa. Čitač ekrana uz njih izgovara naziv
stranice, jer bez trake nema odakle drugačije da ga sazna.

**Header je spušten sa 72 na 48 dp.** Gornji pojas više ne nosi dugmad, pa
nema šta ni da zauzima visinu; 48 dp je tačno dodirna meta, niže se dugme za
konzolu ne bi moglo pogoditi.

**Home ostaje kao stranica**, samo bez svog dugmeta: podaci o događaju
(organizator, adresa, učesnici, scenario, oprema) i dalje se vide, do njih se
stiže prevlačenjem.

**Sve stranice ostaju u stablu.** `PageView` inače ukloni stranicu koja nije
uz trenutnu, a sa Muzika stranicom bi otišao i plejer — muzika bi stala čim se
ode na Lager. Zato je svaka stranica `_KeepAlivePage`. Iz istog razloga spisak
događaja i stranice događaja stoje jedno pored drugog u `IndexedStack`: muzika
svira i dok se bira drugi događaj.

**Plejlista ne sme da menja veličinu.** Kad se kartica plejera raširi ili
skupi, spisak numera poskoči i izvođač izgubi red koji je gledao. Zato kartica
ima **istu visinu u svakom stanju**.

**Unutar događaja headera nema nigde** (odluka od 27. septembra 2026). Ostaje
samo na **spisku događaja**, gde nosi logotip tima i ulaz u konzolu.

Na prvoj stranici događaja ga je zamenilo **jedno dugme — izlazak nazad na
spisak**, gore levo. Muzika, LED i Lager ga nisu ni imale. Razlog je
doslednost: ili se gornji pojas koristi na svim stranicama, ili ni na jednoj,
a koristan je bio samo na jednoj.

Posledica koju treba znati: **konzola (prijava) se otvara sa spiska
događaja**, ne iz otvorenog događaja.

**Ništa se više ne sklanja pri skrolovanju.** Ranije su header i tačkice
nestajali kad se krene nadole i vraćali se nagore; spisak numera je time menjao
visinu pod prstom, a izvođači su se žalili da ih to dezorijentiše. To je isto
pravilo koje već važi za karticu plejera: **raspored se ne menja dok se radi.**

**Izuzetak od pravila o dodirnoj meti** postoji samo na spisku numera
(36 dp umesto 48) — objašnjen je u odeljku „Muzika tab". Svuda drugde
važi 48 dp.

### Pravila dizajna

- **Aplikacija je svetla** (odluka od 25. septembra 2026: nežan „Apple"
  izgled — topla bela, safir, breskva, cimet; jako zaobljeni oblici). Ranije
  je bila samo tamna; tamna varijanta se za sada ne pravi.
- Minimalna dodirna meta **48x48 dp** — rad jednom rukom tokom nastupa
- Visok kontrast, krupan tekst za ključne informacije (naziv, vreme, adresa)
- Minimalistički UI: na ekranu samo ono što treba u tom trenutku

### Paleta (koristiti tačno ove vrednosti)

Vizuelni pravac (od 25. septembra 2026): **svetao, nežan, „Apple" osećaj.**
Topla bela podloga, safirno plava za sve što se dodiruje, breskva i cimet kao
topli akcenti. Oblici su jako zaobljeni (kartice 22–32, dugmad kao pilule), da
aplikacija deluje prijateljski. Tačne vrednosti su u `app_theme.dart`.

| Uloga | Hex | Gde se koristi |
|---|---|---|
| `background` | `#F5F4F2` | osnovna pozadina ekrana |
| `surface` | `#FFFFFF` | kartice |
| `surfaceAlt` | `#F1EFEC` | polja, aktivni red |
| `border` | `#E6E3DF` | okviri i razdelnici |
| `textPrimary` | `#1D1D1F` | glavni tekst |
| `textSecondary` | `#6E6E73` | pomoćni tekst |
| `accent` | `#2F5BEA` | safir: sve što se dodiruje |
| `accentDeep` | `#DCE4FB` | svetli safir: sjaj, gradijenti — **nikad za tekst** |
| `peach` / `peachStrong` | `#FFF1E8` / `#FFD6BF` | kartica „Sada svira", izabran red, oznake |
| `cinnamon` | `#8F4A22` | sitan tekst na breskvi |
| `success` | `#2E9E5B` | spremno, završeno |
| `warning` | `#A86A12` | uskoro, nedostaje podatak, stišan zvuk |
| `danger` | `#D1453B` | greška, problem |

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
| Mapa u kartici adrese | `react-native-maps` | — **otpalo 26. septembra 2026**; adresa otvara navigaciju u tuđoj aplikaciji |
| Datum/vreme na srpskom | `Intl.DateTimeFormat('sr-Latn-RS')` | `intl` (`DateFormat.yMMMMd('sr')`) |
| Kopiranje u clipboard | `expo-clipboard` | ugrađeno: `Clipboard.setData` |
| Logo tima iz galerije | `expo-image-picker` | `image_picker` |
| Trajno čuvanje loga | *nije radilo u Expo Go* | `shared_preferences` + `path_provider` |
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

**Pravila u `firestore.rules` ne važe dok se ne objave.** Fajl u projektu je
samo nacrt; baza radi po onome što je poslednji put poslato. Kad se doda nova
kolekcija, sve dok se pravila ne objave ona pada na završno „sve ostalo je
zatvoreno", pa upis puca bez očiglednog razloga — ekran samo kaže da nije
sačuvano. To se desilo 27. septembra 2026. sa kolekcijom `skills`.

```powershell
firebase deploy --only firestore:rules --project eventapp-4682e
```

**Posle svake izmene `firestore.rules` — objaviti odmah**, u istom koraku u
kom je pisana nova kolekcija.

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

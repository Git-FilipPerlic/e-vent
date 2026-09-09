# LED Chord (spledapps) — analiza konkurentske aplikacije za LED tab

Analiza je urađena za potrebe planiranja **LED taba** u `e-vent` aplikaciji
(Bluetooth kontrola rasvete — boje, scene, efekti), koji je trenutno u fazi
"planirano" i čeka potvrdu hardvera/protokola. Izvor: Google Play stranica
aplikacije i njenih 35 recenzija, pregledano 9. septembra 2026.

## Osnovni podaci

| | |
|---|---|
| Naziv | LED Chord |
| Izdavač | spledapps |
| Paket | `com.spled.pzse` |
| Preuzimanja | 500.000+ |
| Ocena | 3,4 / 5 (35 ocena: 16×5★, 4×4★, 3×3★, 2×2★, 10×1★) |
| Poslednje ažuriranje | 14. avgust 2025. |
| Cena | Besplatna |
| Privatnost | "No data collected", "No data shared" — sve lokalno preko Bluetooth-a, nema naloga ni clouda |
| PEGI | 3 |

Ocena je izrazito polarizovana — skoro trećina ocena je 1 zvezdica, a skoro
polovina 5 zvezdica. To obično znači da aplikacija radi dobro sa nekim
kombinacijama hardvera/telefona, a uopšte ne radi sa drugima — ne da je
prosečno osrednja.

## Namena i pozicioniranje

LED Chord nije vezan za jedan proizvod — to je **generički daljinski
upravljač** za jeftine Bluetooth LED kontrolere koji se prodaju pod raznim
imenima (najčešće pominjani u recenzijama: **SP107E**, vrlo rasprostranjena
pločica za "pixel" LED trake). Podržava dugačku listu LED driver čipova
(SM16703, WS2811, WS2801, SK6812, APA102, DMX512 i još desetak drugih), što
znači da je aplikacija napravljena da radi sa bilo kojim kontrolerom koji
priča isti Bluetooth protokol, a ne da je uparena sa jednim uređajem.

Izdavač (spledapps) ima čitavu porodicu skoro identičnih aplikacija —
Trimlight, Trimlight Edge, BanlanX, FairyNest, LED Hue, LED Shop — svaka za
drugi hardverski protokol. Kvalitet nije ujednačen ni unutar iste firme (LED
Hue stoji na 3,7★ naspram 3,4★ za LED Chord), što potvrđuje da je problem u
pojedinačnim protokolima/hardveru, ne u opštem pristupu firme.

## Tok kroz aplikaciju (redosled ekrana)

1. **Konekcija i uređaji** — spisak Bluetooth uređaja, prekidač za
   povezivanje, preimenovanje uređaja (dijalog "Rename").
2. **AUTO / efekti** — kružni birač efekata (brojevi 5, 6, 7, 8, 9…) sa
   velikim brojem trenutnog efekta u sredini; traka za brzinu i traka za
   jačinu ispod.
3. **SOLID / statična boja** — horizontalna duga (hue) traka za biranje
   boje, red "DIY Color" (sopstvene sačuvane boje) i red "Regu. Color"
   (fiksne osnovne boje: crvena, zelena, plava, žuta, cijan, magenta,
   bela), plus jačina i još dve trake (varijanta efekta/gradijent).
4. **Zvučni režim za traku** — talasni prikaz uživo (mikrofon telefona),
   traka "Color" za boju efekta i posebna traka **"Sensitivity"** za
   osetljivost mikrofona; numerisani preset-i zvučnih efekata.
5. **Matrix režim** — za 2D LED panele (ne samo trake): prekidač
   **"Strip" / "Matrix"** menja tip uređaja; VU-metar vizuelizacija sa
   odvojenim biranjem boje za "Falling Dot" i za "Column"; galerija
   gotovih vizuelnih preset-a (brojevi 1, 30…) sa sličicama efekta.
6. Donja navigacija na svakom ekranu: leva ikonica vodi na kontrolu efekta,
   desna na nešto nalik plejlisti/redu sačuvanih scena.

Podešavanje čipseta, redosleda RGB kanala i broja piksela postoji (pomenuto
u opisu aplikacije: "Selecting different chipset; Setting RGB order;
Setting pixels number"), ali nije bilo među javno prikazanim slikama
ekrana — verovatno je sakriveno u meniju uređaja (ikonica "i" pored naziva
uređaja na kontrolnim ekranima).

## Šta je dobro rešeno (vredi ugledati se)

- **Setup je odvojen od kontrole.** Izbor čipseta/RGB redosleda/broja
  piksela je jednokratno podešavanje po uređaju, odvojeno od ekrana na
  kojima se svakodnevno biraju boje i efekti.
- **DIY boje odvojene od standardnih.** Korisnik ima i brz pristup fiksnim
  osnovnim bojama i svoju paletu sačuvanih boja — nema pretraživanja kroz
  točak boja svaki put za istu nijansu.
- **Posebna "Sensitivity" traka za zvučni režim.** Osetljivost mikrofona
  telefona i akustika prostora previše variraju da bi jedna fiksna
  osetljivost odgovarala svima — ovo je nužan, ne opcioni kontrolni element.
- **Jedan prekidač za dva fizička oblika uređaja** (traka vs. matrica),
  umesto dve odvojene aplikacije ili dva odvojena taba.
- **Kružni birač efekta s brojem u sredini** je brz za dodir jednom rukom —
  relevantno za e-vent, pošto se i Home i Muzika tab eksplicitno prave za
  rad jednom rukom na terenu.

## Poznati problemi (iz recenzija)

- **Pogrešne/zamenjene boje** — više recenzija opisuje da pritisak na
  plavo daje zeleno, pritisak na zeleno daje roze itd. Klasičan simptom
  pogrešnog RGB/GRB redosleda kanala koji korisnik ne može sam da ispravi
  ili aplikacija ne detektuje čipset tačno.
- **Pad aplikacije pri promeni jačine (brightness)**, posle čega se uređaj
  više ne povezuje — ozbiljan bag jer kombinuje crash sa gubitkom
  konekcije, korisnik ostaje "zaključan napolju" iz sopstvene rasvete.
- **Čest "ne povezuje se" / "can't connect"** u 1★ recenzijama — Bluetooth
  parivanje očigledno nije pouzdano na svim telefonima/verzijama Androida.
- **Nema pojedinačnog adresiranja LED-ova** — tražen feature, aplikacija
  radi samo sa efektima/celom trakom, ne sa pojedinačnim pikselima.
- **Traženi widget-i** za brzi pristup sa home ekrana bez otvaranja
  aplikacije.
- Za sam SP107E protokol jedna recenzija kaže da aplikacija "jedva radi,
  treba je kompletno predelati" — jasan signal da kvalitet i stabilnost
  nisu ujednačeni po hardverskom protokolu, čak ni unutar iste aplikacije.

## Šta je relevantno za e-vent LED tab

CLAUDE.md već beleži da LED tab čeka "potvrdu hardvera/protokola i
rešavanje greške kad Bluetooth nije dostupan" — ova analiza direktno
potvrđuje da su to ispravni prioriteti, ne formalnost:

- **Redosled RGB kanala treba testirati sa stvarnim hardverom pre puštanja
  u rad**, ne pretpostaviti ga — to je najčešća pritužba kod konkurencije i
  lako se previdi u razvoju bez fizičkog uređaja na stolu.
- **Promena jačine/boje ne sme da obori konekciju.** Kad dođe biranje
  hardvera, vredi eksplicitno testirati baš tu putanju (brz niz izmena
  brightness-a), pošto je to tačno mesto gde je LED Chord pukao.
- **Ponovno povezivanje posle gubitka Bluetooth signala** treba tretirati
  kao očekivan slučaj, ne izuzetak — sudeći po recenzijama, ovo je najčešći
  uzrok napuštanja aplikacije od strane korisnika.
- Ako e-vent ikad doda zvučni/reaktivni režim (sinhronizacija sa Muzika
  tabom), osetljivost mikrofona mora biti podesiva traka, ne fiksna
  vrednost.
- Vizuelno, e-vent ima prednost što je LED tab deo iste aplikacije sa istom
  tamnom temom (`AppColors`) kao ostala tri taba — generički izgled
  LED Chord-a (ljubičasta pozadina, sistemski Android izgled) ne ostavlja
  utisak da pripada jedinstvenom proizvodu, dok e-vent to može rešiti samim
  tim što je jedna aplikacija, a ne porodica odvojenih alata kao kod
  spledapps.

## Otvorena pitanja za odluku pre početka rada na LED tabu

- Da li e-vent LED tab cilja na jedan konkretan, poznat hardverski protokol
  (npr. samo SP107E-kompatibilne kontrolere) ili generički pristup sa
  listom podržanih čipova kao LED Chord?
- Da li je potreban zvučni/muzički reaktivni režim, i da li bi se napajao
  iz mikrofona telefona ili iz onoga što već svira na Muzika tabu?
- Da li je matrix (2D panel) podrška uopšte u planu, ili samo LED trake —
  ovo utiče na to da li kontrolni ekran treba prekidač tipa uređaja od
  početka.

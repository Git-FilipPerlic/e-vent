# ARHIVA — React Native / Expo verzija Animator App-a

> Ovo je **istorijska referenca**, ne aktivna dokumentacija. Projekat je
> 8. septembra 2026. prebačen na Flutter (vidi `CLAUDE.md`).
>
> Kod opisan ovde više ne postoji u folderu, ali je sačuvan u git istoriji:
>
> ```
> git show 2d06a89:App.js            # pojedinačni fajl
> git checkout 2d06a89 -- src/       # vratiti ceo src/ folder
> ```
>
> Ovaj dokument se čuva zbog dve stvari koje i dalje važe: **redosleda i opisa
> feature-a** koje treba preneti u Flutter, i **modela podataka**.

## Arhitektura (RN verzija)

- React Native + Expo (Expo SDK 57, RN 0.86, React 19), testirano kroz Expo Go
- State: React Hooks (useState, useReducer, useMemo)
- UI: React Native core, `@expo/vector-icons` (Feather), `expo-linear-gradient`
- Navigacija: `@react-navigation/native` + `bottom-tabs`
- Dark mode: `useColorScheme()` preko `src/theme/theme.js`, dark kao default
- Podaci: `src/api/EventAPI_Mock.js` — mock API sa Promise-ima, 4 test događaja
- Delimično pripremljen Google Sheets pravac (`GoogleSheetsAdapter.js`,
  `GoogleSheetsConfig.js`) — **napušten** u korist Firebase-a
- Auth: `src/auth/MockAuth.js` — uloge `glavni` i `user`, provera kroz `can()`
- Mape `react-native-maps`, clipboard `expo-clipboard`, logo `expo-image-picker`

## Struktura koja je postojala

```
App.js                              - tab navigator (Home / Muzika / LED / Lager),
                                       header sa upload-om logotipa (samo "glavni")
src/theme/theme.js                  - useTheme(), dark/light palete, spacing, minTouchTarget
src/api/EventAPI_Mock.js            - getEvent, updateEvent, listEvents,
                                       listVehicles, createVehicle, listChecklist
src/api/GoogleSheetsAdapter.js      - normalizacija Sheets redova u checklist model
src/api/GoogleSheetsConfig.js       - placeholder za link tabele (ostao prazan)
src/auth/MockAuth.js                - uloge glavni/user, permission model

src/screens/
  HomeScreen.jsx                     - učitava evt-001 + vozila, pull-to-refresh
  MusicScreen.jsx                    - MUSIC-001 mock plejer
  LagerScreen.jsx                    - checklist opreme
  PlaceholderScreen.jsx              - "još nije rađeno" ekran (LED tab)

src/components/
  EventTitleDisplay.jsx    (HOME-001) - naziv slavljenika, read-only
  OrganizerName.jsx        (HOME-002) - ime organizatora + copy-to-clipboard
  OrganizerPhone.jsx       (HOME-004) - telefon: poziv / SMS / kopiranje
  AddressLocation.jsx      (HOME-003) - adresa + mini mapa + dugme Navigacija
  EventDateDisplay.jsx     (HOME-005) - datum, srpska lokalizacija (sr-Latn-RS)
  LiveClock.jsx            (HOME-006) - sat uživo, osvežavanje svake sekunde
  DepartureTimeDisplay.jsx (HOME-007) - planirano vreme polaska
  VehicleSelector.jsx      (zamena za HOME-008/009/010) - izbor i dodavanje vozila
  EventParticipants.jsx    (HOME-012) - učesnici sa ulogama, fallback po redosledu
  EventTeamStatus.jsx      (HOME-013) - provera obaveznih uloga (glavni, vozač)
  EventReadiness.jsx       (HOME-011) - koji podaci događaja nedostaju
  EventOverviewStatus.jsx  (HOME-020) - kombinovani rezime (podaci + oprema)
  EventStatusBanner.jsx    (HOME-018) - status po vremenu: planirano / polazak /
                                        u toku / završeno
  EventReminder.jsx        (HOME-019) - in-app podsetnik za polazak ili početak
  EventScenario.jsx        (HOME-025) - scenario: read-only stavke + lokalno dodavanje
  HomeLoadError.jsx        (HOME-021) - greška pri učitavanju sa Retry dugmetom
  PreparationChecklist.jsx (HOME-015/016) - checklist po sekcijama, do 90 stavki,
                                        progress bar (prikazivan na Lager tabu)
```

## Dokle se stiglo

**Home** — praktično kompletan MVP: sve gore navedeno plus pull-to-refresh.
Checklist opreme je odlukom u HOME-025 premešten sa Home taba na Lager tab.

**Muzika** — MUSIC-001: lista fajlova (izvor Folder ili Playlista), izbor fajla
bez autoplay-a, playback modal sa velikim dugmetom, tajmer po ivicama kvadrata,
fade-in toggle. Sve simulirano (`setInterval`), bez pravog audio engine-a.

**Lager** — checklist sa sekcijama Tehnika, Animacija, Specijalni efekti,
Vatreni rekviziti, Svila, Hoop; čekiranje, lokalno dodavanje stavki, limit 90,
progress bar.

**LED** — nije započet.

**Branding** — `glavni` može da učita logo tima u header; logo se čuvao samo u
memoriji sesije jer AsyncStorage nije radio u tadašnjem Expo Go okruženju.
(U Flutteru ovo rešava `shared_preferences`.)

## Model podataka (prenosi se u Flutter/Firestore)

```js
{
  id: 'evt-001',
  title: 'Rođendan - Mia (7 godina)',
  scenario: ['Doček gostiju', 'Igre za decu', 'Završni plesni program'],
  organizerName: 'Jovana Petrović',
  organizerPhone: '+381641234567',
  address: 'Bulevar Oslobođenja 45, Novi Sad',
  latitude: 45.2671,
  longitude: 19.8335,
  eventDate: '2026-09-12T16:00:00',
  departureTime: '2026-09-12T14:30:00',
  travelDurationMinutes: 35,
  vehicleId: 'vehicle-001',
  participants: [
    { name: 'Filip', role: 'glavni' },
    { name: 'Ana', role: 'vozač' },
    { name: 'Marko', role: 'pomoćni' },
  ],
}
```

Vozila: `{ id, name }`. Checklist: `[{ id, name, items: [{ id, name }] }]`.

Test događaji: `evt-001` (pun), `evt-002` (jedan učesnik), `evt-003` (bez
telefona i vozila), `evt-004` (sva polja prazna — za proveru praznih stanja).

## Pravila koja su se pokazala kao dobra i treba ih zadržati

- Komponente primaju podatke kroz props; samo ekrani pričaju sa API-jem — zato
  je zamena backend-a bila zamena jednog fajla
- Svaka komponenta ima `loading` stanje i fallback tekst za prazan podatak
- Dark-first tema kroz jedan hook, bez hardkodovanih boja po komponentama
- Dodirne mete minimum 48 dp
- Read-only prema izvoru podataka; lokalno se menjaju samo logo, dodate
  checklist stavke i dodate stavke scenarija

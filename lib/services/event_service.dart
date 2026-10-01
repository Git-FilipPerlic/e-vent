import '../models/checklist.dart';
import '../models/company_settings.dart';
import '../models/event.dart';
import '../models/meeting.dart';
import '../models/team.dart';
import '../models/vehicle.dart';

/// Ugovor između ekrana i izvora podataka.
///
/// Ekrani zovu **samo** ovaj interfejs i nikad ne znaju odakle podaci stižu.
/// Zato se kasnija zamena mock podataka Firebase-om svodi na jednu liniju
/// tamo gde se servis pravi — nijedan widget se ne dira.
abstract interface class EventService {
  /// Učitava jedan događaj. Baca [EventNotFoundException] ako ga nema.
  Future<Event> loadEvent(String eventId);

  /// Spisak događaja, od najbližeg ka daljem.
  ///
  /// Filtriranje ide **ovde, a ne na ekranu**: kad umesto mock servisa dođe
  /// Firestore, spisak mora da ograniči baza. Ekran koji sam prosejava tuđe
  /// događaje znači da su mu tuđi podaci ipak stigli.
  ///
  /// * [assignedTo] — događaji koje taj korisnik ima kao svoj zadatak
  /// * [createdBy] — događaji koje je taj korisnik napravio i podelio timu
  ///
  /// Bez oba se vraća sve. To je stanje **bez prijave**, kad se ne zna ni ko
  /// gleda; sa pravim backendom spisak i tada ograničava baza.
  Future<List<Event>> loadEvents({String? assignedTo, String? createdBy});

  /// Isti spisak, ali **uživo**: nova vrednost stiže sama čim se u bazi
  /// nešto promeni.
  ///
  /// Postoji zato što spisak stoji u stablu dok se gleda pojedinačan događaj
  /// (da muzika ne stane), pa bi bez ovoga pokazivao ono što je zatekao pri
  /// otvaranju. Izvođač tako događaj koji mu je upravo dodeljen vidi bez
  /// povlačenja nadole i bez ponovnog pokretanja aplikacije.
  ///
  /// Parametri znače isto što i kod [loadEvents].
  Stream<List<Event>> watchEvents({String? assignedTo, String? createdBy});

  /// Pravi nov događaj i vraća ga sa dodeljenim `id`-jem.
  ///
  /// Sve sem [createdBy] može da nedostaje — događaj se često otvori sa
  /// samo datumom i imenom, a ostalo se popunjava kad stigne dogovor.
  Future<Event> createEvent({
    required String createdBy,
    String? title,
    EventType? type,
    DateTime? eventDate,
    int? durationMinutes,
    List<String> assignedTo,
  });

  /// Ko sve postoji u ekipi — iz toga se bira kome se događaj dodeljuje.
  ///
  /// Za sada su to imena; sa Firebase Auth-om ovde stižu nalozi tima.
  Future<List<String>> loadTeamMembers();

  /// Podešavanja firme — za sada adresa magacina, odakle ekipa kreće.
  Future<CompanySettings> loadSettings();

  /// Pamti podešavanja firme. Menja ih samo onaj ko vodi ekipu.
  Future<void> saveSettings(CompanySettings settings);

  /// Ekipa sa veštinama i bodovima — za ekran „Ekipa" u konzoli.
  ///
  /// Razlikuje se od [loadTeamMembers], koji vraća samo imena: tamo se bira
  /// kome se događaj dodeljuje, a ovde se vidi ko šta ume.
  Future<List<TeamMember>> loadTeam();

  /// Pamti ime, ulogu, veštine i bodove jednog člana — sve što manager sme
  /// da menja. Čovek sam sme da promeni i svoje ime i svoju ikonicu, odvojeno
  /// od ovoga; ikonicu ovaj poziv ne dira.
  Future<void> saveMemberSkills(TeamMember member);

  /// Katalog veština koje firma poznaje.
  Future<List<Skill>> loadSkills();

  /// Dodaje veštinu u katalog i vraća je sa dodeljenim `id`-jem.
  Future<Skill> createSkill(String name);

  /// Preimenuje veštinu.
  Future<void> saveSkill(Skill skill);

  /// Briše veštinu iz kataloga **i sa svih članova ekipe** — obrisana
  /// veština ne sme da ostane zalepljena za ljude.
  Future<void> deleteSkill(String skillId);

  /// Spisak vozila koja ekipa može da izabere.
  Future<List<Vehicle>> loadVehicles();

  /// Dodaje novo vozilo i vraća ga sa dodeljenim `id`-jem.
  Future<Vehicle> addVehicle(String name);

  /// Pamti koje je vozilo izabrano za dati događaj.
  /// Baca [EventNotFoundException] ako događaja nema.
  Future<void> setEventVehicle(String eventId, String vehicleId);

  /// Čuva izmenjene podatke o događaju (admin konzola).
  /// Baca [EventNotFoundException] ako događaja nema.
  Future<void> saveEvent(Event event);

  /// Katalog kategorija opreme koje firma ima, sa delovima.
  Future<List<ChecklistSection>> loadChecklistTemplate();

  /// Pravi novu kategoriju opreme i vraća je sa dodeljenim `id`-jem.
  Future<ChecklistSection> createCategory(String name);

  /// Briše kategoriju iz **kataloga firme**.
  ///
  /// Događaji koji su je nosili je posle toga prosto nemaju — čuvaju se samo
  /// id-jevi, pa nepostojeća kategorija ispada iz prikaza sama.
  Future<void> deleteCategory(String categoryId);

  /// Čuva izmenjenu kategoriju (delove koji joj pripadaju).
  ///
  /// Menja **katalog firme**, pa se izmena vidi na svim događajima koji tu
  /// kategoriju nose — to je i poenta: dodat rekvizit se ne unosi po događaju.
  Future<void> saveCategory(ChecklistSection category);

  /// Sastanci firme — spisak za konzolu, gde ih glavni pravi i briše.
  Future<List<CompanyMeeting>> loadMeetings();

  /// Isti spisak, uživo — isti razlog kao [watchEvents]: spisak događaja
  /// stoji u stablu, pa mora sam da primeti nov sastanak.
  Stream<List<CompanyMeeting>> watchMeetings();

  /// Pravi nov sastanak i vraća ga sa dodeljenim `id`-jem. Pravi ga samo
  /// glavni — vidi ga posle cela ekipa, bez obzira na dodelu.
  Future<CompanyMeeting> createMeeting({
    required DateTime dateTime,
    required String address,
  });

  /// Briše sastanak iz konzole.
  Future<void> deleteMeeting(String meetingId);
}

/// Traženi događaj ne postoji.
class EventNotFoundException implements Exception {
  const EventNotFoundException(this.eventId);

  final String eventId;

  @override
  String toString() => 'Događaj "$eventId" ne postoji.';
}

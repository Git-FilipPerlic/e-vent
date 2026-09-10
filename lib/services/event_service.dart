import '../models/checklist.dart';
import '../models/event.dart';
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
}

/// Traženi događaj ne postoji.
class EventNotFoundException implements Exception {
  const EventNotFoundException(this.eventId);

  final String eventId;

  @override
  String toString() => 'Događaj "$eventId" ne postoji.';
}

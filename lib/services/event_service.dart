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

  /// Spisak vozila koja ekipa može da izabere.
  Future<List<Vehicle>> loadVehicles();

  /// Dodaje novo vozilo i vraća ga sa dodeljenim `id`-jem.
  Future<Vehicle> addVehicle(String name);

  /// Prazan šablon checkliste opreme, po sekcijama.
  Future<List<ChecklistSection>> loadChecklistTemplate();
}

/// Traženi događaj ne postoji.
class EventNotFoundException implements Exception {
  const EventNotFoundException(this.eventId);

  final String eventId;

  @override
  String toString() => 'Događaj "$eventId" ne postoji.';
}

import '../models/event.dart';

/// Vremenske grupe u spisku događaja.
///
/// Redosled u enumu je i redosled na ekranu: prvo ono što je najbliže, na
/// dnu ono što je prošlo.
enum EventGroup {
  danas('Danas'),
  sutra('Sutra'),
  ovaNedelja('Ova nedelja'),
  kasnije('Kasnije'),
  bezDatuma('Bez datuma'),
  prosli('Prošli');

  const EventGroup(this.label);

  /// Naslov grupe u spisku.
  final String label;
}

/// Jedna grupa sa svojim događajima. Prazne grupe se ne prave.
class EventGroupSection {
  const EventGroupSection({required this.group, required this.events});

  final EventGroup group;
  final List<Event> events;
}

/// Deli događaje u vremenske grupe.
///
/// Grupiše se **po danu, ne po satu**: nastup koji je danas ostaje pod
/// „Danas" i pošto se završi. Tako se posle podneva spisak ne premešta pod
/// nogama — a i završen nastup se tog dana još raspakuje.
///
/// [now] se prosleđuje da bi moglo da se testira; ekran šalje `DateTime.now()`.
List<EventGroupSection> groupEvents(
  List<Event> events, {
  required DateTime now,
}) {
  final grouped = <EventGroup, List<Event>>{};

  for (final event in events) {
    grouped.putIfAbsent(_groupFor(event, now), () => []).add(event);
  }

  // Prošli se čitaju unazad — juče je zanimljivije od prošle godine.
  grouped[EventGroup.prosli] = grouped[EventGroup.prosli]?.reversed.toList()
      ?? const [];

  return [
    for (final group in EventGroup.values)
      if (grouped[group]?.isNotEmpty ?? false)
        EventGroupSection(group: group, events: grouped[group]!),
  ];
}

EventGroup _groupFor(Event event, DateTime now) {
  final date = event.eventDate;
  if (date == null) return EventGroup.bezDatuma;

  final days = _dayDifference(date, now);

  if (days < 0) return EventGroup.prosli;
  if (days == 0) return EventGroup.danas;
  if (days == 1) return EventGroup.sutra;
  // Sedam dana unapred je „ova nedelja" u svakodnevnom smislu, bez obzira
  // na to kog je dana nedelja počela.
  if (days <= 7) return EventGroup.ovaNedelja;
  return EventGroup.kasnije;
}

/// Razlika u **danima**, bez sati — 23:00 danas i 01:00 sutra su dva dana.
int _dayDifference(DateTime date, DateTime now) {
  final left = DateTime(date.year, date.month, date.day);
  final right = DateTime(now.year, now.month, now.day);
  return left.difference(right).inDays;
}

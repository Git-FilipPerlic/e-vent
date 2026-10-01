import '../models/event.dart';
import '../models/meeting.dart';
import 'event_grouping.dart';

/// Jedan red u spisku: događaj ili sastanak firme. Oboje dele isto
/// vremensko grupisanje, ali se crtaju različito — sastanak nosi samo
/// vreme i adresu, u drugoj boji, i vidi ga cela ekipa.
sealed class AgendaEntry {
  const AgendaEntry();

  DateTime? get when;
}

class EventEntry extends AgendaEntry {
  const EventEntry(this.event);

  final Event event;

  @override
  DateTime? get when => event.eventDate;
}

class MeetingEntry extends AgendaEntry {
  const MeetingEntry(this.meeting);

  final CompanyMeeting meeting;

  @override
  DateTime? get when => meeting.dateTime;
}

/// Jedna vremenska grupa sa svim redovima koji joj pripadaju.
class AgendaSection {
  const AgendaSection({required this.group, required this.entries});

  final EventGroup group;
  final List<AgendaEntry> entries;
}

/// Spaja događaje i sastanke u jedan spisak, grupisan po [groupForDate].
///
/// Oba spiska stižu već poređana po vremenu (tako ih vraća servis), pa se
/// unutar svake grupe samo ponovo sortiraju — spajanje dva već sortirana
/// spiska bi inače moglo da ih ostavi isprepletane pogrešnim redom.
List<AgendaSection> groupAgenda({
  required List<Event> events,
  required List<CompanyMeeting> meetings,
  required DateTime now,
}) {
  final grouped = <EventGroup, List<AgendaEntry>>{};

  for (final event in events) {
    grouped
        .putIfAbsent(groupForDate(event.eventDate, now), () => [])
        .add(EventEntry(event));
  }
  for (final meeting in meetings) {
    grouped
        .putIfAbsent(groupForDate(meeting.dateTime, now), () => [])
        .add(MeetingEntry(meeting));
  }

  for (final entries in grouped.values) {
    entries.sort((a, b) {
      final left = a.when;
      final right = b.when;
      if (left == null && right == null) return 0;
      if (left == null) return 1;
      if (right == null) return -1;
      return left.compareTo(right);
    });
  }

  // Prošli se čitaju unazad — juče je zanimljivije od prošle godine.
  grouped[EventGroup.prosli] = grouped[EventGroup.prosli]?.reversed.toList()
      ?? const [];

  return [
    for (final group in EventGroup.values)
      if (grouped[group]?.isNotEmpty ?? false)
        AgendaSection(group: group, entries: grouped[group]!),
  ];
}

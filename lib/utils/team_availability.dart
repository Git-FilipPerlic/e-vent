import '../models/event.dart';
import '../widgets/home/event_status_banner.dart';
import 'date_format.dart';

/// Ko je u datom terminu već na drugom događaju.
///
/// Vraća ime → natpis za spisak („Radi na: 7 Mia, 16:00" — bez „zauzet /
/// zauzeta", jer se iz imena ne zna rod). Zauzeti se pri
/// biranju ekipe **ne sklanjaju**, nego stoje bledo sa ovim natpisom
/// (odluka korisnika od 29. septembra 2026): kad nekog nema na spisku, ne
/// zna se da li je zauzet ili zaboravljen, a ovako se odmah vidi zašto.
///
/// Termin je od početka do kraja nastupa. Bez ugovorenog trajanja računa se
/// [EventStatusBanner.assumedDuration], isto kao za status događaja.
/// **Bez početka nema provere** — ne zna se kada je, pa se ništa ne nagađa.
///
/// Događaj koji se upravo menja ([exceptEventId]) se ne računa, inače bi
/// svako ko je već na njemu izgledao zauzet samim sobom.
Map<String, String> busyMembers({
  required List<Event> events,
  required DateTime? start,
  int? durationMinutes,
  String? exceptEventId,
}) {
  if (start == null) return const {};
  final end = _endOf(start, durationMinutes);

  // Najraniji sukob prvi, da natpis pokaže onaj koji prvi smeta.
  final others = [
    for (final event in events)
      if (event.id != exceptEventId && event.eventDate != null) event,
  ]..sort((a, b) => a.eventDate!.compareTo(b.eventDate!));

  final busy = <String, String>{};
  for (final event in others) {
    final otherStart = event.eventDate!;
    final otherEnd = _endOf(otherStart, event.durationMinutes);
    // Dva termina se preklapaju kad svaki počinje pre kraja onog drugog.
    // Nastup koji počinje tačno kad se drugi završi nije sukob.
    final overlaps = otherStart.isBefore(end) && start.isBefore(otherEnd);
    if (!overlaps) continue;

    final title = event.title?.trim();
    final label =
        'Radi na: ${title == null || title.isEmpty ? 'drugi događaj' : title}, '
        '${AppDate.time(otherStart)}';
    for (final name in event.assignedTo) {
      busy.putIfAbsent(name, () => label);
    }
  }
  return busy;
}

DateTime _endOf(DateTime start, int? minutes) => start.add(
  minutes == null ? EventStatusBanner.assumedDuration : Duration(minutes: minutes),
);

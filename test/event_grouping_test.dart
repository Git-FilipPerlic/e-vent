import 'package:event_app/models/event.dart';
import 'package:event_app/utils/event_grouping.dart';
import 'package:flutter_test/flutter_test.dart';

/// Sreda, 9. septembar 2026, popodne.
final DateTime _now = DateTime(2026, 9, 9, 14, 30);

Event _at(String id, DateTime? date) => Event(id: id, eventDate: date);

void main() {
  group('grupisanje događaja po vremenu', () {
    test('svrstava svaki događaj u svoju grupu', () {
      final sections = groupEvents([
        _at('danas', DateTime(2026, 9, 9, 20)),
        _at('sutra', DateTime(2026, 9, 10, 12)),
        _at('ove-nedelje', DateTime(2026, 9, 14, 18)),
        _at('kasnije', DateTime(2026, 10, 3, 20)),
        _at('bez-datuma', null),
        _at('prosli', DateTime(2026, 9, 1, 18)),
      ], now: _now);

      expect(sections.map((s) => s.group), [
        EventGroup.danas,
        EventGroup.sutra,
        EventGroup.ovaNedelja,
        EventGroup.kasnije,
        EventGroup.bezDatuma,
        EventGroup.prosli,
      ]);
    });

    test('prazne grupe se ne prikazuju', () {
      final sections = groupEvents([
        _at('kasnije', DateTime(2026, 12, 1, 20)),
      ], now: _now);

      expect(sections, hasLength(1));
      expect(sections.single.group, EventGroup.kasnije);
    });

    test('nastup koji je danas već prošao ostaje pod „Danas"', () {
      // Grupiše se po danu, ne po satu — spisak se ne premešta u toku dana,
      // a i završen nastup se tog dana još raspakuje.
      final sections = groupEvents([
        _at('jutros', DateTime(2026, 9, 9, 9)),
      ], now: _now);

      expect(sections.single.group, EventGroup.danas);
    });

    test('sedmi dan je još „ova nedelja", osmi je „kasnije"', () {
      final sections = groupEvents([
        _at('sedmi', DateTime(2026, 9, 16, 10)),
        _at('osmi', DateTime(2026, 9, 17, 10)),
      ], now: _now);

      expect(sections.first.group, EventGroup.ovaNedelja);
      expect(sections.first.events.single.id, 'sedmi');
      expect(sections.last.group, EventGroup.kasnije);
    });

    test('kasno veče i rano jutro su dva različita dana', () {
      final sections = groupEvents([
        _at('veceras', DateTime(2026, 9, 9, 23, 30)),
        _at('u-ranu-zoru', DateTime(2026, 9, 10, 1)),
      ], now: _now);

      expect(sections.first.group, EventGroup.danas);
      expect(sections.last.group, EventGroup.sutra);
    });

    test('prošli se čitaju unazad, od najskorijeg', () {
      final sections = groupEvents([
        _at('lane', DateTime(2025, 5, 1)),
        _at('juce', DateTime(2026, 9, 8)),
      ], now: _now);

      expect(sections.single.events.map((e) => e.id), ['juce', 'lane']);
    });

    test('prazan spisak nema nijednu grupu', () {
      expect(groupEvents(const [], now: _now), isEmpty);
    });
  });
}

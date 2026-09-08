import 'package:event_app/models/event.dart';
import 'package:event_app/theme/app_theme.dart';
import 'package:event_app/widgets/home/participants_list.dart';
import 'package:event_app/widgets/home/team_status.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: AppTheme.dark,
    home: Scaffold(body: child),
  );
}

const List<Participant> _fullTeam = [
  Participant(name: 'Marko Marković', role: ParticipantRole.glavni),
  Participant(name: 'Ana Anić', role: ParticipantRole.vozac),
  Participant(name: 'Petar Perić', role: ParticipantRole.pomocni),
];

void main() {
  group('spisak učesnika', () {
    testWidgets('prikazuje sva imena, uloge i broj članova',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        _wrap(const ParticipantsList(participants: _fullTeam)),
      );

      expect(find.text('Marko Marković'), findsOneWidget);
      expect(find.text('Ana Anić'), findsOneWidget);
      expect(find.text('Petar Perić'), findsOneWidget);
      expect(find.text(ParticipantRole.glavni), findsOneWidget);
      expect(find.text(ParticipantRole.vozac), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('prazan spisak ima svoje objašnjenje',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        _wrap(const ParticipantsList(participants: [])),
      );

      expect(find.text('Ekipa još nije određena'), findsOneWidget);
    });

    testWidgets('učesnik bez imena ne ostavlja prazan red',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        _wrap(
          const ParticipantsList(
            participants: [Participant(name: '  ', role: ParticipantRole.glavni)],
          ),
        ),
      );

      expect(find.text('Ime nije uneto'), findsOneWidget);
    });

    test('svaka uloga ima svoju ikonicu', () {
      expect(
        ParticipantsList.iconForRole(ParticipantRole.glavni),
        Icons.star_rounded,
      );
      expect(
        ParticipantsList.iconForRole(ParticipantRole.vozac),
        Icons.drive_eta_rounded,
      );
      expect(
        ParticipantsList.iconForRole(ParticipantRole.pomocni),
        Icons.person_rounded,
      );
    });
  });

  group('status tima', () {
    testWidgets('kompletna ekipa je spremna', (WidgetTester tester) async {
      await tester.pumpWidget(
        _wrap(const TeamStatus(participants: _fullTeam)),
      );

      expect(find.text('Ekipa je kompletna'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    });

    testWidgets('bez vozača se javlja koja uloga nedostaje',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        _wrap(
          const TeamStatus(
            participants: [
              Participant(name: 'Marko', role: ParticipantRole.glavni),
            ],
          ),
        ),
      );

      expect(find.text('Nedostaje uloga: ${ParticipantRole.vozac}'),
          findsOneWidget);
      expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
    });

    testWidgets('prazna ekipa javlja obe uloge', (WidgetTester tester) async {
      await tester.pumpWidget(_wrap(const TeamStatus(participants: [])));

      expect(
        find.text(
          'Nedostaju uloge: ${ParticipantRole.glavni}, ${ParticipantRole.vozac}',
        ),
        findsOneWidget,
      );
    });

    test('nedostajuće uloge se računaju iz spiska', () {
      const withDriverOnly = TeamStatus(
        participants: [Participant(name: 'Ana', role: ParticipantRole.vozac)],
      );

      expect(withDriverOnly.isReady, isFalse);
      expect(withDriverOnly.missingRoles, [ParticipantRole.glavni]);

      const full = TeamStatus(participants: _fullTeam);
      expect(full.isReady, isTrue);
      expect(full.missingRoles, isEmpty);
    });
  });
}

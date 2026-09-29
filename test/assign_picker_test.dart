import 'package:event_app/models/team.dart';
import 'package:event_app/theme/app_theme.dart';
import 'package:event_app/widgets/home/team_assignment.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const List<Skill> _skills = [
  Skill(id: 's1', name: 'Vatra'),
  Skill(id: 's2', name: 'Svila'),
  Skill(id: 's3', name: 'Voditelj'),
  Skill(id: 's4', name: 'Vozač'),
  Skill(id: 's5', name: 'LED rasveta'),
  Skill(id: 's6', name: 'Hoop'),
  Skill(id: 's7', name: 'Mehurići'),
  Skill(id: 's8', name: 'Balon figure'),
];

void main() {
  testWidgets('sve veštine se vide odjednom, i na uskom ekranu',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showAssignPicker(
                context,
                team: const [TeamMember(id: 'u1', name: 'Filip')],
                skills: _skills,
                assignedTo: const [],
              ),
              child: const Text('Otvori'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Otvori'));
    await tester.pumpAndSettle();

    // Nijedno dugme ne sme da ispadne van ekrana: sve se slaže u redove.
    for (final label in ['Svi', ..._skills.map((s) => s.name)]) {
      final chip = find.widgetWithText(ChoiceChip, label);
      expect(chip, findsOneWidget);
      final rect = tester.getRect(chip);
      expect(rect.right, lessThanOrEqualTo(360), reason: label);
    }

    // Poslednja veština je na dohvat prsta bez ikakvog pomeranja.
    await tester.tap(find.widgetWithText(ChoiceChip, 'Balon figure'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Balon figure'))
          .selected,
      isTrue,
    );
  });

  testWidgets('zauzeti ostaju u spisku, bledo i sa natpisom gde rade',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showAssignPicker(
                context,
                team: const [
                  TeamMember(id: 'u1', name: 'Filip'),
                  TeamMember(id: 'u2', name: 'Ana'),
                ],
                skills: const [],
                assignedTo: const [],
                busy: const {'Ana': 'Radi na: 7 Mia, 16:00'},
              ),
              child: const Text('Otvori'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Otvori'));
    await tester.pumpAndSettle();

    // Nije sklonjena — vidi se i zašto je bleda.
    expect(find.text('Ana'), findsOneWidget);
    expect(find.text('Radi na: 7 Mia, 16:00'), findsOneWidget);
    final name = tester.widget<Text>(find.text('Ana'));
    expect(name.style?.color, AppColors.textSecondary);

    // I dalje može da se čekira, ako manager zna nešto što aplikacija ne zna.
    await tester.tap(find.text('Ana'));
    await tester.pumpAndSettle();
    final box = tester.widget<CheckboxListTile>(
      find.widgetWithText(CheckboxListTile, 'Ana'),
    );
    expect(box.value, isTrue);
  });
}

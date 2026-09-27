// Ekipa: veštine iz kataloga firme i bodovi koje dodeljuje manager.

import 'package:event_app/models/team.dart';
import 'package:event_app/services/mock_event_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('član ekipe', () {
    test('nivo kreće od jedan, i bez ijednog boda', () {
      const member = TeamMember(id: 'u1', name: 'Ana');
      expect(member.level, 1);
      expect(member.levelProgress, 0);
      expect(member.expToNextLevel, 100);
    });

    test('bodovi se pretvaraju u nivo i traku', () {
      const member = TeamMember(id: 'u1', name: 'Ana', exp: 240);
      expect(member.level, 3);
      expect(member.levelProgress, closeTo(0.4, 0.001));
      expect(member.expToNextLevel, 60);
    });

    // Oduzimanje bodova je ispravka greške, ne kazna — pa se staje na nuli.
    test('bodovi ne idu ispod nule', () {
      const member = TeamMember(id: 'u1', name: 'Ana', exp: 30);
      expect(member.copyWith(exp: -50).exp, 0);
    });

    test('prazan i neispravan zapis iz baze ne obara ekran', () {
      final member = TeamMember.fromMap({
        'id': 'u1',
        'name': '  Ana  ',
        'skills': ['skill-001', '', 42],
        'exp': 12.7,
      });
      expect(member.name, 'Ana');
      expect(member.skillIds, ['skill-001']);
      expect(member.exp, 13);
      expect(member.role, 'user');

      final empty = TeamMember.fromMap(const {});
      expect(empty.exp, 0);
      expect(empty.skillIds, isEmpty);
    });
  });

  group('katalog veština', () {
    test('veština se doda i odmah je u spisku', () async {
      final service = MockEventService();
      final before = await service.loadSkills();

      final added = await service.createSkill('  Hoop  ');
      final after = await service.loadSkills();

      expect(added.name, 'Hoop');
      expect(after.length, before.length + 1);
      expect(after.map((s) => s.name), contains('Hoop'));
    });

    // Obrisana veština ne sme da ostane zalepljena za ljude kao id koji
    // više ništa ne znači.
    test('brisanje veštine skida je i sa članova ekipe', () async {
      final service = MockEventService();
      final team = await service.loadTeam();
      final filip = team.firstWhere((m) => m.name == 'Filip');
      expect(filip.knows('skill-001'), isTrue);

      await service.deleteSkill('skill-001');

      final skills = await service.loadSkills();
      expect(skills.map((s) => s.id), isNot(contains('skill-001')));
      final after = (await service.loadTeam()).firstWhere(
        (m) => m.name == 'Filip',
      );
      expect(after.knows('skill-001'), isFalse);
    });
  });

  group('čuvanje člana', () {
    test('veštine i bodovi se pamte, ime i uloga se ne diraju', () async {
      final service = MockEventService();
      final ana = (await service.loadTeam()).firstWhere((m) => m.name == 'Ana');

      await service.saveMemberSkills(
        ana.copyWith(name: 'Neko drugi', skillIds: ['skill-003'], exp: 150),
      );

      final saved = (await service.loadTeam()).firstWhere((m) => m.id == ana.id);
      expect(saved.skillIds, ['skill-003']);
      expect(saved.exp, 150);
      expect(saved.level, 2);
      // Ime ostaje ono koje čovek sam postavlja u konzoli.
      expect(saved.name, 'Ana');
    });
  });
}

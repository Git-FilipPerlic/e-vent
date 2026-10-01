/// Veština koju firma poznaje — Vatra, Svila, Hoop, Voditelj, Vozač, LED…
///
/// Katalog je **po firmi**, kao i katalog opreme: manager ga jednom napravi u
/// konzoli, pa se uz svakog člana ekipe samo čekira šta ume. Slobodan unos bi
/// značio da se ista veština piše na tri načina, pa se po njoj ne bi moglo
/// filtrirati.
class Skill {
  const Skill({required this.id, required this.name});

  final String id;
  final String name;

  Skill copyWith({String? name}) => Skill(id: id, name: name ?? this.name);

  Map<String, dynamic> toMap() => {'name': name};

  factory Skill.fromMap(Map<String, dynamic> map) {
    return Skill(
      id: (map['id'] as String?) ?? '',
      name: ((map['name'] as String?) ?? '').trim(),
    );
  }
}

/// Član ekipe sa onim što ume i koliko je odradio.
///
/// **Veštine i bodove upisuje manager**, ne sam član (odluka od 27. septembra
/// 2026) — inače bi se spisak popunio brzo, ali mu se ne bi verovalo. Isto
/// važi i za bodove: dodeljuju se ručno, posle odrađenog posla.
class TeamMember {
  const TeamMember({
    required this.id,
    required this.name,
    this.role = 'user',
    this.skillIds = const [],
    this.exp = 0,
    this.avatarId,
  });

  /// Nalog kome član pripada (`users/{uid}`).
  final String id;

  /// Ime pod kojim ga ekipa vidi.
  final String name;

  /// `glavni` vodi ekipu; `user` je izvođač.
  final String role;

  /// Šta ume — id-jevi iz kataloga veština.
  final List<String> skillIds;

  /// Skupljeni bodovi. Manager ih dodeljuje posle odrađenog posla.
  final int exp;

  /// Ikonica pod kojom ga ekipa prepoznaje. `null` znači podrazumevanu.
  /// Bira je čovek sam — to je jedino što na svom profilu sme da menja
  /// uz ime.
  final String? avatarId;

  /// Koliko bodova nosi jedan nivo.
  ///
  /// Sto je izabrano zato što se lako računa u glavi: manager posle nastupa
  /// doda deset ili dvadeset bodova i odmah zna koliko je do sledećeg nivoa.
  static const int expPerLevel = 100;

  /// Koji je nivo, računato iz bodova. Prvi nivo je 1, ne 0 — čovek bez
  /// ijednog boda je i dalje na nekom nivou.
  int get level => exp ~/ expPerLevel + 1;

  /// Dokle je stigao u tekućem nivou, 0..1 — to crta EXP traka.
  double get levelProgress => (exp % expPerLevel) / expPerLevel;

  /// Koliko bodova fali do sledećeg nivoa.
  int get expToNextLevel => expPerLevel - exp % expPerLevel;

  bool knows(String skillId) => skillIds.contains(skillId);

  TeamMember copyWith({
    String? name,
    String? role,
    List<String>? skillIds,
    int? exp,
    String? avatarId,
  }) {
    return TeamMember(
      id: id,
      name: name ?? this.name,
      role: role ?? this.role,
      avatarId: avatarId ?? this.avatarId,
      skillIds: skillIds ?? this.skillIds,
      // Bodovi ne idu ispod nule: oduzimanje je ispravka greške, ne kazna.
      exp: exp == null ? this.exp : (exp < 0 ? 0 : exp),
    );
  }

  /// Samo ono što manager sme da menja — veštine, bodovi i uloga. Ime,
  /// ikonica i ostatak profila se ovim ne diraju; njih bira čovek sam.
  Map<String, dynamic> toManagerMap() => {
    'skills': skillIds,
    'exp': exp,
    'role': role,
  };

  factory TeamMember.fromMap(Map<String, dynamic> map) {
    final skills = map['skills'];
    return TeamMember(
      id: (map['id'] as String?) ?? '',
      name: ((map['name'] as String?) ?? '').trim(),
      role: ((map['role'] as String?) ?? 'user').trim(),
      avatarId: (map['avatar'] as String?)?.trim(),
      skillIds: skills is List
          ? [
              for (final value in skills)
                if (value is String && value.trim().isNotEmpty) value.trim(),
            ]
          : const [],
      // Iz baze ume da stigne i broj sa decimalom; prazno polje je nula.
      exp: switch (map['exp']) {
        final int value => value < 0 ? 0 : value,
        final num value => value < 0 ? 0 : value.round(),
        _ => 0,
      },
    );
  }
}

/// Odakle je pesma došla.
///
/// Izvor se prikazuje uz svaku pesmu, jer se u žurbi lako pomeša numera iz
/// telefona sa numerom iz plejliste za nastup.
enum TrackSource {
  folder('Folder'),
  playlist('Playlista');

  const TrackSource(this.label);

  final String label;

  /// Nepoznat izvor iz baze se tretira kao folder — nikad se ne puca.
  factory TrackSource.fromName(String? name) {
    for (final source in TrackSource.values) {
      if (source.name == name) return source;
    }
    return TrackSource.folder;
  }
}

/// Jedna numera u spisku za nastup.
///
/// **Svako polje sem [id] može da nedostaje** — ekran mora da prikaže razuman
/// tekst umesto podatka, nikad da pukne.
class Track {
  const Track({
    required this.id,
    this.title,
    this.artist,
    this.source = TrackSource.folder,
    this.duration,
    this.path,
  });

  final String id;

  /// Naziv numere. Kad ga nema, pada se na naziv fajla iz [path].
  final String? title;

  final String? artist;
  final TrackSource source;

  /// Trajanje numere. `null` dok se fajl ne pročita.
  final Duration? duration;

  /// Putanja do fajla na telefonu. Trebaće kad se priključi pravi plejer.
  final String? path;

  /// Šta se prikazuje kao naziv: naziv iz podataka, pa naziv fajla,
  /// pa objašnjenje.
  String get displayTitle {
    final name = title?.trim();
    if (name != null && name.isNotEmpty) return name;

    final file = path?.split(RegExp(r'[/\\]')).last.trim();
    if (file != null && file.isNotEmpty) return withoutExtension(file);

    return 'Numera bez naziva';
  }

  /// Naziv fajla bez nastavka.
  ///
  /// „.mp3" na kraju svakog reda ne kaže ništa, a jede širinu na uskom
  /// ekranu. Tačka na samom početku znači skriven fajl, ne nastavak, pa se
  /// takvo ime ne dira.
  static String withoutExtension(String fileName) {
    final dot = fileName.lastIndexOf('.');
    return dot > 0 ? fileName.substring(0, dot) : fileName;
  }

  bool get hasArtist => artist != null && artist!.trim().isNotEmpty;

  factory Track.fromMap(Map<String, dynamic> map) {
    final seconds = (map['durationSeconds'] as num?)?.toInt();
    return Track(
      id: map['id'] as String,
      title: _emptyToNull(map['title'] as String?),
      artist: _emptyToNull(map['artist'] as String?),
      source: TrackSource.fromName(map['source'] as String?),
      duration: seconds == null ? null : Duration(seconds: seconds),
      path: _emptyToNull(map['path'] as String?),
    );
  }

  static String? _emptyToNull(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return value;
  }
}

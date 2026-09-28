import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/track_note.dart';

/// Odakle stižu beleške na pesmama.
///
/// Ekrani zovu samo ovaj interfejs — u aplikaciji ide Firestore, u testu
/// obična lista u memoriji, da se ne dira mreža.
abstract interface class TrackNoteService {
  /// Sve beleške za jednu numeru, poređane po mestu u pesmi.
  Future<List<TrackNote>> notesFor(String trackKey);

  /// Dodaje belešku i vraća je sa dodeljenim `id`-jem.
  Future<TrackNote> add(TrackNote note);

  /// Briše belešku.
  Future<void> remove(String noteId);
}

/// Beleške u Firestore bazi, u kolekciji `trackNotes`.
///
/// Firestore je već u upotrebi i njegov besplatan nivo je za ovo sasvim
/// dovoljan — za razliku od Storage-a, koji bi trebao za prave profilne
/// slike i koji se plaća.
class FirestoreTrackNoteService implements TrackNoteService {
  FirestoreTrackNoteService({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _notes =>
      _db.collection('trackNotes');

  @override
  Future<List<TrackNote>> notesFor(String trackKey) async {
    final snapshot = await _notes.where('trackKey', isEqualTo: trackKey).get();
    final notes = [
      for (final doc in snapshot.docs)
        TrackNote.fromMap({...doc.data(), 'id': doc.id}),
    ]..removeWhere((note) => note.text.isEmpty);

    // Redom kroz pesmu, ne redom kojim su upisane — tako se čita uz talas.
    notes.sort((a, b) => a.positionMs.compareTo(b.positionMs));
    return notes;
  }

  @override
  Future<TrackNote> add(TrackNote note) async {
    final doc = _notes.doc();
    final created = TrackNote(
      id: doc.id,
      trackKey: note.trackKey,
      positionMs: note.positionMs,
      text: note.text,
      authorName: note.authorName,
      authorAvatarId: note.authorAvatarId,
      createdAt: note.createdAt ?? DateTime.now(),
    );
    await doc.set(created.toMap());
    return created;
  }

  @override
  Future<void> remove(String noteId) => _notes.doc(noteId).delete();
}

/// Beleške u memoriji — za razvoj i testove.
class InMemoryTrackNoteService implements TrackNoteService {
  InMemoryTrackNoteService([List<TrackNote> initial = const []])
    : _notes = [...initial];

  final List<TrackNote> _notes;
  int _next = 1;

  @override
  Future<List<TrackNote>> notesFor(String trackKey) async {
    final notes = [
      for (final note in _notes)
        if (note.trackKey == trackKey) note,
    ];
    notes.sort((a, b) => a.positionMs.compareTo(b.positionMs));
    return notes;
  }

  @override
  Future<TrackNote> add(TrackNote note) async {
    final created = TrackNote(
      id: 'note-${_next++}',
      trackKey: note.trackKey,
      positionMs: note.positionMs,
      text: note.text,
      authorName: note.authorName,
      authorAvatarId: note.authorAvatarId,
      createdAt: note.createdAt ?? DateTime.now(),
    );
    _notes.add(created);
    return created;
  }

  @override
  Future<void> remove(String noteId) async {
    _notes.removeWhere((note) => note.id == noteId);
  }
}

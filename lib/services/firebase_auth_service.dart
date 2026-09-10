import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;

import 'auth_service.dart';

/// Prava prijava, preko Firebase Auth-a.
///
/// **Isti interfejs kao lokalna prijava**, pa se zamena svodi na jednu liniju
/// tamo gde se servis pravi. Ekrani i dalje pitaju samo „sme li ovo", ne
/// „ko je ovo".
///
/// Prijava ide **mejlom i lozinkom** (odluka korisnika, 10. septembra 2026).
/// Ime i uloga ne stoje u samom nalogu nego u `users/{uid}` — nalog zna samo
/// mejl, a ko je ko u ekipi je podatak firme.
class FirebaseAuthService extends AuthService {
  FirebaseAuthService({fb.FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? fb.FirebaseAuth.instance,
      _db = firestore ?? FirebaseFirestore.instance {
    // Prijava preživljava zatvaranje aplikacije, pa se pri pokretanju samo
    // pročita ko je već prijavljen.
    _subscription = _auth.authStateChanges().listen(_onAuthChanged);
  }

  final fb.FirebaseAuth _auth;
  final FirebaseFirestore _db;

  AppUser? _currentUser;
  StreamSubscription<fb.User?>? _subscription;

  @override
  AppUser? get currentUser => _currentUser;

  @override
  bool get usesEmail => true;

  Future<void> _onAuthChanged(fb.User? user) async {
    if (user == null) {
      _currentUser = null;
      notifyListeners();
      return;
    }

    _currentUser = await _profileFor(user);
    notifyListeners();
  }

  /// Ime i uloga iz `users/{uid}`.
  ///
  /// Ako zapisa nema, korisnik i dalje ulazi — samo kao običan izvođač, bez
  /// prava na izmene. Bolje nego da prijava pukne zbog toga što neko nije
  /// upisan u ekipu.
  Future<AppUser> _profileFor(fb.User user) async {
    // **Ne ceo mejl.** Ljudi se pamte po imenu, ne po adresi; a ime stoji i
    // u „Ko radi", gde bi spisak mejlova bio neupotrebljiv. Dok korisnik ne
    // upiše svoje ime, uzima se deo pre @.
    final fallback = AppUser(
      name: nameFromEmail(user.email),
      role: UserRole.user,
    );

    try {
      final doc = await _db.collection('users').doc(user.uid).get();
      final data = doc.data();
      if (data == null) {
        // Prva prijava: profil se pravi sam, kao **običan izvođač**.
        // Unapređenje u `glavni` ide iz konzole ili od nekoga ko to već
        // jeste — inače bi svako sebe proglasio šefom, što pravila i brane.
        await doc.reference.set({
          'name': fallback.name,
          'role': UserRole.user,
          'email': user.email,
        });
        return fallback;
      }

      final name = (data['name'] as String?)?.trim();
      final role = (data['role'] as String?)?.trim();

      return AppUser(
        name: name == null || name.isEmpty ? fallback.name : name,
        role: role == null || role.isEmpty ? UserRole.user : role,
      );
    } catch (_) {
      return fallback;
    }
  }

  @override
  Future<String?> signIn({required String name, required String pin}) async {
    final email = name.trim();
    if (email.isEmpty || pin.isEmpty) {
      return 'Unesi mejl i lozinku.';
    }

    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: pin,
      );
      final user = result.user;
      if (user == null) return 'Prijava nije uspela.';

      _currentUser = await _profileFor(user);
      notifyListeners();
      return null;
    } on fb.FirebaseAuthException catch (error) {
      return _messageFor(error.code);
    } catch (_) {
      return 'Prijava nije uspela. Proveri vezu sa internetom.';
    }
  }

  /// Deo mejla pre `@`, kao privremeno ime.
  ///
  /// `filip.perlic@gmail.com` daje `filip.perlic` — nije lepo, ali je
  /// čitljivije od pune adrese i menja se u konzoli jednim unosom.
  static String nameFromEmail(String? email) {
    final value = email?.trim() ?? '';
    if (value.isEmpty) return 'Korisnik';
    final at = value.indexOf('@');
    return at > 0 ? value.substring(0, at) : value;
  }

  /// Menja ime pod kojim se korisnik vidi u ekipi.
  ///
  /// Uloga se ovim **ne dira** — pravila to i ne dozvoljavaju: kad bi svako
  /// mogao da menja svoju ulogu, prijava ne bi značila ništa.
  Future<String?> setDisplayName(String name) async {
    final user = _auth.currentUser;
    final trimmed = name.trim();
    if (user == null) return 'Nisi prijavljen.';
    if (trimmed.isEmpty) return 'Ime ne može da bude prazno.';

    try {
      await _db.collection('users').doc(user.uid).set({
        'name': trimmed,
      }, SetOptions(merge: true));

      _currentUser = AppUser(
        name: trimmed,
        role: _currentUser?.role ?? UserRole.user,
      );
      notifyListeners();
      return null;
    } catch (_) {
      return 'Ime nije sačuvano. Proveri vezu sa internetom.';
    }
  }

  /// Poruka za korisnika.
  ///
  /// **Pogrešan mejl i pogrešna lozinka daju istu poruku** — namerno, isto
  /// kao kod lokalne prijave: iz različitih poruka bi se saznalo koji nalozi
  /// postoje.
  static String _messageFor(String code) {
    return switch (code) {
      'network-request-failed' =>
        'Nema veze sa internetom. Prijava traži mrežu.',
      'too-many-requests' =>
        'Previše pokušaja. Sačekaj malo pa probaj ponovo.',
      'user-disabled' => 'Nalog je isključen. Javi se onome ko vodi ekipu.',
      _ => 'Pogrešan mejl ili lozinka.',
    };
  }

  @override
  Future<void> signOut() async {
    await _auth.signOut();
    _currentUser = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _subscription = null;
    super.dispose();
  }
}

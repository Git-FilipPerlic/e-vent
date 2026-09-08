/// Šta prijavljeni korisnik sme da uradi.
///
/// UI uvek proverava **dozvolu**, nikada naziv uloge — tako backend kasnije
/// može da doda nove uloge bez menjanja ekrana.
enum Permission {
  /// Menjanje logotipa tima u headeru. Funkcija managementa.
  editTeamLogo,

  /// Izbor vozila za događaj.
  editVehicle,

  /// Popunjavanje i deljenje podataka o događaju (admin konzola).
  editEvent,
}

/// Ko je prijavljen i šta sme.
///
/// Zasad postoji samo mock implementacija; kasnije je menja Firebase Auth,
/// bez diranja ekrana.
abstract interface class AuthService {
  /// Da li je korisnik prijavljen. Bez prijave se podaci samo čitaju.
  bool get isSignedIn;

  /// Uloga prijavljenog korisnika (`glavni` ili `user`), ili `null`
  /// kad niko nije prijavljen.
  String? get role;

  /// Da li trenutni korisnik sme datu radnju.
  bool can(Permission permission);
}

/// Lokalna zamena dok ne stigne pravi login.
///
/// **Namerno pušta sve** — da bi se funkcije koje traže dozvolu mogle
/// isprobati pre nego što login postoji. Kad se napravi login ekran, ovo se
/// menja pravim korisnikom i zamenjuje se u jednoj liniji.
class MockAuthService implements AuthService {
  const MockAuthService({this.signedIn = true, this.userRole = 'glavni'});

  final bool signedIn;
  final String userRole;

  @override
  bool get isSignedIn => signedIn;

  @override
  String? get role => signedIn ? userRole : null;

  @override
  bool can(Permission permission) {
    // Bez prijave se ništa ne menja — ni logo, ni vozilo, ni podaci.
    if (!signedIn) return false;
    return userRole == 'glavni';
  }
}

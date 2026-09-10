import 'package:flutter/foundation.dart';

/// Šta prijavljeni korisnik sme da uradi.
///
/// UI uvek proverava **dozvolu**, nikada naziv uloge — tako backend kasnije
/// može da doda nove uloge bez menjanja ekrana.
enum AppPermission {
  /// Menjanje logotipa tima u headeru. Funkcija managementa.
  editTeamLogo,

  /// Izbor vozila za događaj.
  editVehicle,

  /// Popunjavanje podataka o događaju i deljenje timu (admin konzola).
  editEvent,
}

/// Uloge u aplikaciji.
abstract final class UserRole {
  /// Vodi ekipu: popunjava podatke o događaju, deli ih timu, menja logotip.
  static const String glavni = 'glavni';

  /// Izvođač: vidi sve, ali ne menja podatke tima.
  static const String user = 'user';
}

/// Prijavljeni korisnik.
class AppUser {
  const AppUser({required this.name, required this.role});

  final String name;
  final String role;

  bool get isGlavni => role == UserRole.glavni;
}

/// Ko je prijavljen i šta sme.
///
/// Nasleđuje [ChangeNotifier] jer se **ceo UI menja kad se neko prijavi ili
/// odjavi** — kartice na Home tabu iz čitanja prelaze u unos, a u headeru se
/// pojavljuje menjanje logotipa.
///
/// Zasad postoji samo lokalna implementacija; kasnije je menja Firebase Auth,
/// bez diranja ekrana.
abstract class AuthService extends ChangeNotifier {
  /// Prijavljeni korisnik, ili `null`.
  AppUser? get currentUser;

  bool get isSignedIn => currentUser != null;

  /// Da li se prijavljuje **mejlom i lozinkom** (prava prijava), ili imenom
  /// i PIN-om (lokalna, za probu). Ekran po tome ispisuje nazive polja.
  bool get usesEmail => false;

  /// Prijava. Vraća `null` kad je prošla, ili poruku o grešci.
  Future<String?> signIn({required String name, required String pin});

  Future<void> signOut();

  /// Da li trenutni korisnik sme datu radnju.
  ///
  /// Bez prijave se ništa ne menja — aplikacija je tada samo za čitanje.
  bool can(AppPermission permission) {
    final user = currentUser;
    if (user == null) return false;
    return user.isGlavni;
  }
}

/// Lokalna prijava, dok ne stigne Firebase.
///
/// Nalozi su upisani u kodu i služe samo za razvoj i probu na terenu. Prava
/// provera identiteta je posao backenda — ovde se ne pretvaramo da je ovo
/// zaštita, nego da je **prekidač između čitanja i unosa**.
class MockAuthService extends AuthService {
  MockAuthService({AppUser? signedInAs}) : _currentUser = signedInAs;

  AppUser? _currentUser;

  /// Nalozi za probu: ime u malim slovima → (PIN, uloga).
  static const Map<String, (String, String)> _accounts = {
    'filip': ('1234', UserRole.glavni),
    'ana': ('1111', UserRole.user),
  };

  @override
  AppUser? get currentUser => _currentUser;

  @override
  Future<String?> signIn({required String name, required String pin}) async {
    final key = name.trim().toLowerCase();
    if (key.isEmpty) return 'Unesi ime.';
    if (pin.trim().isEmpty) return 'Unesi PIN.';

    final account = _accounts[key];
    // Namerno ista poruka i za pogrešno ime i za pogrešan PIN — inače se iz
    // poruke saznaje koja imena postoje.
    if (account == null || account.$1 != pin.trim()) {
      return 'Ime ili PIN nisu tačni.';
    }

    _currentUser = AppUser(name: name.trim(), role: account.$2);
    notifyListeners();
    return null;
  }

  @override
  Future<void> signOut() async {
    _currentUser = null;
    notifyListeners();
  }
}

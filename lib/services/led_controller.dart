import 'dart:async';
import 'dart:io';

/// Redosled boja u kontroleru.
///
/// Magic Home kontroleri dolaze kao RGB, GRB ili BRG — isti bajtovi daju
/// različitu boju. **Ne pretpostavlja se, nego se bira**: najčešća pritužba
/// na slične aplikacije je da „plavo daje zeleno".
enum ColorOrder {
  rgb('RGB'),
  grb('GRB'),
  brg('BRG');

  const ColorOrder(this.label);

  final String label;

  /// Preslaže tri bajta iz onoga što korisnik vidi u ono što kontroler
  /// očekuje.
  List<int> arrange(int red, int green, int blue) {
    return switch (this) {
      ColorOrder.rgb => [red, green, blue],
      ColorOrder.grb => [green, red, blue],
      ColorOrder.brg => [blue, red, green],
    };
  }
}

/// Nađen kontroler na mreži.
class LedDevice {
  const LedDevice({required this.address, this.mac, this.model});

  /// IP adresa na lokalnoj mreži.
  final String address;

  final String? mac;
  final String? model;

  /// Kako se ispisuje u spisku: model ako se zna, inače sama adresa.
  String get label => model == null || model!.trim().isEmpty ? address : model!;
}

/// Kontrola LED rasvete.
///
/// Ekran zove samo ovaj interfejs, pa se u testu podmetne lažni kontroler —
/// pravi uređaj u testu ne postoji.
abstract interface class LedController {
  /// Traži kontrolere na lokalnoj mreži.
  Future<List<LedDevice>> discover({Duration timeout});

  /// Otvara vezu ka uređaju. Baca [LedConnectionException] ako ne uspe.
  Future<void> connect(String address);

  /// Zatvara vezu.
  Future<void> disconnect();

  /// Da li veza stoji.
  bool get isConnected;

  /// Pali i gasi rasvetu.
  Future<void> setPower(bool on);

  /// Postavlja boju. Vrednosti su 0..255, onako kako ih korisnik vidi;
  /// preslaganje po [ColorOrder] radi sam kontroler.
  Future<void> setColor(int red, int green, int blue);
}

/// Uređaj se ne javlja (nije na mreži, ili telefon nije na njegovoj mreži).
class LedConnectionException implements Exception {
  const LedConnectionException(this.address);

  final String address;

  @override
  String toString() => 'Kontroler na $address se ne javlja.';
}

/// Prava kontrola Magic Home kontrolera, preko obične mrežne veze.
///
/// **Nije potreban nijedan paket** — sve staje u `dart:io`: `RawDatagramSocket`
/// za pronalaženje uređaja i `Socket` za komande.
class MagicHomeController implements LedController {
  MagicHomeController({this.colorOrder = ColorOrder.rgb});

  /// Port na kome Magic Home kontroleri slušaju komande.
  static const int commandPort = 5577;

  /// Port na koji se šalje poruka za pronalaženje uređaja.
  static const int discoveryPort = 48899;

  /// Poruka koju kontroleri prepoznaju kao „javi se".
  static const String discoveryMessage = 'HF-A11ASSISTHREAD';

  /// Koliko se čeka na otvaranje veze pre nego što se odustane.
  static const Duration connectTimeout = Duration(seconds: 5);

  /// Redosled boja u kontroleru.
  ColorOrder colorOrder;

  Socket? _socket;

  @override
  bool get isConnected => _socket != null;

  @override
  Future<List<LedDevice>> discover({
    Duration timeout = const Duration(seconds: 3),
  }) async {
    final socket = await RawDatagramSocket.bind(
      InternetAddress.anyIPv4,
      0,
    );
    socket.broadcastEnabled = true;

    final found = <String, LedDevice>{};
    final done = Completer<void>();

    socket.listen((event) {
      if (event != RawSocketEvent.read) return;
      final packet = socket.receive();
      if (packet == null) return;

      final device = _parseDiscovery(String.fromCharCodes(packet.data));
      if (device != null) found[device.address] = device;
    }, onDone: () {
      if (!done.isCompleted) done.complete();
    });

    socket.send(
      discoveryMessage.codeUnits,
      InternetAddress('255.255.255.255'),
      discoveryPort,
    );

    // Uređaji se javljaju u roku od par stotina milisekundi; čeka se malo
    // duže, jer se na slabijoj mreži ume da zakasni.
    await Future<void>.delayed(timeout);
    socket.close();
    if (!done.isCompleted) done.complete();

    return found.values.toList();
  }

  /// Odgovor je oblika `192.168.1.50,ACCF23xxxxxx,HF-LPB100`.
  ///
  /// Nepoznat oblik se preskače: bolje prazan spisak nego uređaj sa
  /// besmislenom adresom.
  static LedDevice? _parseDiscovery(String reply) {
    final parts = reply.trim().split(',');
    if (parts.isEmpty) return null;

    final address = parts[0].trim();
    if (address.isEmpty || !address.contains('.')) return null;

    return LedDevice(
      address: address,
      mac: parts.length > 1 ? parts[1].trim() : null,
      model: parts.length > 2 ? parts[2].trim() : null,
    );
  }

  @override
  Future<void> connect(String address) async {
    await disconnect();
    try {
      _socket = await Socket.connect(
        address,
        commandPort,
        timeout: connectTimeout,
      );
    } on SocketException {
      throw LedConnectionException(address);
    }
  }

  @override
  Future<void> disconnect() async {
    final socket = _socket;
    _socket = null;
    if (socket == null) return;
    try {
      await socket.close();
    } catch (_) {
      // Veza je možda već pala; nema šta da se javi korisniku.
    }
  }

  @override
  Future<void> setPower(bool on) =>
      _send(on ? const [0x71, 0x23, 0x0F] : const [0x71, 0x24, 0x0F]);

  @override
  Future<void> setColor(int red, int green, int blue) {
    final ordered = colorOrder.arrange(
      red.clamp(0, 255),
      green.clamp(0, 255),
      blue.clamp(0, 255),
    );
    // Peti bajt je bela dioda; nju ne diramo dok se ne zna ima li je uređaj.
    return _send([0x31, ...ordered, 0x00, 0x00, 0x0F]);
  }

  Future<void> _send(List<int> payload) async {
    final socket = _socket;
    if (socket == null) return;

    socket.add(withChecksum(payload));
    await socket.flush();
  }

  /// Dodaje kontrolni bajt: zbir svih prethodnih po modulu 256.
  ///
  /// Bez njega kontroler poruku tiho odbaci — ne javi grešku, samo ne uradi
  /// ništa, pa je ovo prvo mesto koje treba proveriti ako svetlo ne reaguje.
  static List<int> withChecksum(List<int> payload) {
    var sum = 0;
    for (final byte in payload) {
      sum += byte;
    }
    return [...payload, sum & 0xFF];
  }
}

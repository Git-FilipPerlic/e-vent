import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../theme/app_theme.dart';

/// Zlatni listići i varnice na dodir i prevlačenje (proba „zlatno-crno").
///
/// Stoji preko cele aplikacije, ali **ne hvata dodire** — samo ih posmatra,
/// pa svako dugme, spisak i prevlačenje ispod radi tačno kao i pre. Na dodir
/// izleti prasak listića sa kratkim zlatnim talasom, a prst koji prevlači
/// ostavlja trag varnica.
///
/// Sat za crtanje radi samo dok ima listića u vazduhu; kad padnu, staje, pa
/// aplikacija u mirovanju ne troši bateriju. Uz sistemski „smanjen pokret"
/// listića nema.
class GoldBurst extends StatefulWidget {
  const GoldBurst({super.key, required this.child});

  final Widget child;

  @override
  State<GoldBurst> createState() => _GoldBurstState();
}

class _GoldBurstState extends State<GoldBurst>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker(_onTick);
  final _ParticleField _field = _ParticleField();
  final math.Random _random = math.Random();

  Duration _lastTick = Duration.zero;

  /// Gde je koji prst bio poslednji put i koliko je prešao od poslednje
  /// varnice. Prati se po prstu, da dva prsta ne mešaju tragove.
  final Map<int, Offset> _lastPoint = {};
  final Map<int, double> _travel = {};

  /// Na koliko piksela prevlačenja izleti nova grupica varnica.
  static const double _trailStep = 18;

  bool get _enabled => !MediaQuery.disableAnimationsOf(context);

  void _onDown(PointerDownEvent event) {
    if (!_enabled) return;
    _lastPoint[event.pointer] = event.localPosition;
    _travel[event.pointer] = 0;
    _field.burst(event.localPosition, _random);
    _wake();
  }

  void _onMove(PointerMoveEvent event) {
    final last = _lastPoint[event.pointer];
    if (last == null || !_enabled) return;
    final delta = event.localPosition - last;
    final distance = delta.distance;
    _lastPoint[event.pointer] = event.localPosition;
    if (distance == 0) return;

    final before = _travel[event.pointer] ?? 0;
    final total = before + distance;
    // Brz potez preskoči mnogo piksela u jednom događaju — varnice se
    // raspoređuju duž cele deonice, ne gomilaju na kraju.
    final count = math.min((total / _trailStep).floor(), 6);
    for (var i = 1; i <= count; i++) {
      final along = ((i * _trailStep - before) / distance).clamp(0.0, 1.0);
      _field.trail(last + delta * along, delta / distance, _random);
    }
    _travel[event.pointer] = total - count * _trailStep;
    if (count > 0) _wake();
  }

  void _onEnd(PointerEvent event) {
    _lastPoint.remove(event.pointer);
    _travel.remove(event.pointer);
  }

  void _wake() {
    if (_ticker.isActive) return;
    _lastTick = Duration.zero;
    _ticker.start();
  }

  void _onTick(Duration elapsed) {
    // Posle zastoja (aplikacija u pozadini) korak se ograniči, da listići
    // ne preskoče ceo let odjednom.
    final dt = math.min((elapsed - _lastTick).inMicroseconds / 1e6, 0.05);
    _lastTick = elapsed;
    _field.step(dt);
    if (_field.isEmpty) _ticker.stop();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _field.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _onDown,
      onPointerMove: _onMove,
      onPointerUp: _onEnd,
      onPointerCancel: _onEnd,
      child: CustomPaint(
        foregroundPainter: _BurstPainter(_field),
        // Aplikacija ispod se ne precrtava zbog listića iznad nje.
        child: RepaintBoundary(child: widget.child),
      ),
    );
  }
}

enum _Kind { flake, spark, ring }

class _Particle {
  _Particle({
    required this.kind,
    required this.position,
    required this.velocity,
    required this.life,
    required this.size,
    this.angle = 0,
    this.spin = 0,
    this.flipRate = 0,
    this.seed = 0,
  });

  final _Kind kind;
  Offset position;
  Offset velocity;
  final double life;
  final double size;
  double angle;
  final double spin;
  final double flipRate;
  final double seed;
  double age = 0;

  /// 1 na početku, 0 na kraju života.
  double get remaining => (1 - age / life).clamp(0.0, 1.0);
}

/// Svi listići u vazduhu i njihova fizika. Javlja slikaru kad se nešto
/// pomeri.
class _ParticleField extends ChangeNotifier {
  final List<_Particle> _particles = [];

  /// Gornja granica, da divlje prevlačenje ne zaguši telefon.
  static const int _maxParticles = 320;

  bool get isEmpty => _particles.isEmpty;
  List<_Particle> get particles => _particles;

  static double _between(math.Random r, double a, double b) =>
      a + r.nextDouble() * (b - a);

  static Offset _direction(double angle) =>
      Offset(math.cos(angle), math.sin(angle));

  _Particle _flake(math.Random r, Offset at, Offset velocity) => _Particle(
    kind: _Kind.flake,
    position: at,
    velocity: velocity,
    life: _between(r, 0.8, 1.5),
    size: _between(r, 3, 7),
    angle: _between(r, 0, 2 * math.pi),
    spin: _between(r, 3, 11) * (r.nextBool() ? 1 : -1),
    flipRate: _between(r, 6, 16),
    seed: _between(r, 0, 2 * math.pi),
  );

  _Particle _spark(math.Random r, Offset at, Offset velocity) => _Particle(
    kind: _Kind.spark,
    position: at,
    velocity: velocity,
    life: _between(r, 0.25, 0.55),
    size: _between(r, 1, 1.8),
  );

  /// Prasak na mestu dodira: talas, listići na sve strane i brze varnice.
  void burst(Offset at, math.Random r) {
    _particles.add(
      _Particle(
        kind: _Kind.ring,
        position: at,
        velocity: Offset.zero,
        life: 0.4,
        size: 48,
      ),
    );
    for (var i = 0; i < 16; i++) {
      final v = _direction(_between(r, 0, 2 * math.pi)) *
          _between(r, 120, 420);
      // Malo nagore, da prasak „iskoči" iz prsta pre nego što padne.
      _particles.add(_flake(r, at, v + const Offset(0, -90)));
    }
    for (var i = 0; i < 12; i++) {
      final v = _direction(_between(r, 0, 2 * math.pi)) *
          _between(r, 320, 720);
      _particles.add(_spark(r, at, v));
    }
    _trim();
    notifyListeners();
  }

  /// Trag prevlačenja: varnice beže bočno od pravca kretanja, a listić se
  /// otkine i pada.
  void trail(Offset at, Offset direction, math.Random r) {
    final side = Offset(-direction.dy, direction.dx);
    for (var i = 0; i < 2; i++) {
      final sign = r.nextBool() ? 1.0 : -1.0;
      final v = side * (sign * _between(r, 120, 320)) -
          direction * _between(r, 20, 120);
      _particles.add(_spark(r, at, v));
    }
    final drift = side * _between(r, -60, 60) - direction * 40;
    _particles.add(_flake(r, at, drift + const Offset(0, -40)));
    _trim();
    notifyListeners();
  }

  void _trim() {
    final excess = _particles.length - _maxParticles;
    if (excess > 0) _particles.removeRange(0, excess);
  }

  void step(double dt) {
    for (final p in _particles) {
      p.age += dt;
      switch (p.kind) {
        case _Kind.flake:
          // Listić je lak: vazduh ga brzo koči, pa lebdi i njiše se padajući.
          p.velocity = p.velocity * math.pow(0.08, dt).toDouble() +
              Offset(math.sin(p.age * 5 + p.seed) * 140 * dt, 320 * dt);
          p.angle += p.spin * dt;
        case _Kind.spark:
          p.velocity = p.velocity * math.pow(0.3, dt).toDouble() +
              Offset(0, 700 * dt);
        case _Kind.ring:
          break;
      }
      p.position += p.velocity * dt;
    }
    _particles.removeWhere((p) => p.age >= p.life);
    notifyListeners();
  }
}

class _BurstPainter extends CustomPainter {
  _BurstPainter(this.field) : super(repaint: field);

  final _ParticleField field;

  /// Oblik listića: nepravilan četvorougao, kao otkinut komadić zlatne
  /// folije. Crta se razvučen, pa jedna putanja služi za sve.
  static final Path _leaf = Path()
    ..moveTo(-1, -0.55)
    ..lineTo(0.25, -1)
    ..lineTo(1, 0.45)
    ..lineTo(-0.35, 1)
    ..close();

  final Paint _fill = Paint();
  final Paint _stroke = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in field.particles) {
      final fade = p.remaining;
      switch (p.kind) {
        case _Kind.ring:
          final t = Curves.easeOutCubic.transform(1 - fade);
          _stroke
            ..strokeWidth = 2.5 * fade + 0.5
            ..color = AppColors.accent.withValues(alpha: 0.7 * fade);
          canvas.drawCircle(p.position, 6 + p.size * t, _stroke);
        case _Kind.spark:
          // Varnica je crtica duž pravca leta: što brža, to duža.
          final tail = p.position - p.velocity * 0.03;
          _stroke
            ..strokeWidth = p.size * 3
            ..color = AppColors.accent.withValues(alpha: 0.35 * fade);
          canvas.drawLine(tail, p.position, _stroke);
          _stroke
            ..strokeWidth = p.size
            ..color = AppColors.accentHighlight.withValues(alpha: fade);
          canvas.drawLine(tail, p.position, _stroke);
        case _Kind.flake:
          // Listić se prevrće: kad je licem ka nama, bljesne svetlije.
          final flip = math.cos(p.age * p.flipRate + p.seed);
          final shine = math.pow(flip.abs(), 6).toDouble();
          final color = Color.lerp(
            AppColors.accent,
            AppColors.accentHighlight,
            shine,
          )!;
          // Poslednja trećina života polako bledi.
          final alpha = math.min(1.0, fade * 3);
          _fill.color = color.withValues(alpha: alpha);
          canvas
            ..save()
            ..translate(p.position.dx, p.position.dy)
            ..rotate(p.angle)
            ..scale(p.size * (0.2 + 0.8 * flip.abs()), p.size)
            ..drawPath(_leaf, _fill)
            ..restore();
      }
    }
  }

  @override
  bool shouldRepaint(_BurstPainter oldDelegate) => oldDelegate.field != field;
}

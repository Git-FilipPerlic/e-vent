import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// Tačkice koje kažu na kojoj si stranici i koliko ih ima.
///
/// Zamenile su traku sa dugmadima Home / Muzika / LED / Lager (odluka od
/// 26. septembra 2026). Otkad se između stranica **prevlači**, dugmad su
/// bila suvišna, a trošila su 82 dp visine — na Muzika tabu je to razlika
/// između tri i sedam numera na ekranu.
///
/// Tačkice se ne dodiruju. One su oznaka, ne dugme: meta od 6 dp bi ionako
/// bila premala za prst usred programa, a stranica je na jedan pokret.
///
/// Widget je „glup" — dobija broj stranica i trenutnu kroz konstruktor.
class PageDots extends StatelessWidget {
  const PageDots({
    super.key,
    required this.count,
    required this.currentIndex,
    required this.labels,
  });

  final int count;
  final int currentIndex;

  /// Nazivi stranica. Ne ispisuju se — služe čitaču ekrana, koji bez trake
  /// sa dugmadima inače ne bi imao odakle da sazna gde je korisnik.
  final List<String> labels;

  /// Visina trake sa tačkicama.
  static const double height = 18;

  static const double _dot = 6;
  static const double _activeDot = 18;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final label = currentIndex >= 0 && currentIndex < labels.length
        ? labels[currentIndex]
        : '';

    return Semantics(
      container: true,
      label: '$label — stranica ${currentIndex + 1} od $count',
      child: SizedBox(
        height: height,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (int i = 0; i < count; i++)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: AnimatedContainer(
                  duration: reduceMotion
                      ? Duration.zero
                      : const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  width: i == currentIndex ? _activeDot : _dot,
                  height: _dot,
                  decoration: BoxDecoration(
                    color: i == currentIndex
                        ? AppColors.accent
                        : AppColors.border,
                    borderRadius: BorderRadius.circular(_dot / 2),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

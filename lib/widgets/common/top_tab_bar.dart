import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import 'neon_glow.dart';

/// Jedan tab u gornjoj navigaciji.
class TopTab {
  const TopTab({required this.label, required this.icon});

  final String label;
  final IconData icon;
}

/// Glavna navigacija — **gore**, odmah ispod headera.
///
/// Tabovi su izvedeni kao dugmad sa zakošenom ivicom (bevel): izabrani je
/// izdignut, sa svetlijom ivicom gore i senkom ispod, i u boji `accent`;
/// neizabrani su utisnuti u podlogu i mirni. Cilj je da se sa ispružene ruke —
/// na sastanku, u vožnji, tokom programa — na prvi pogled vidi šta je
/// izabrano, bez čitanja sitnog teksta.
///
/// Widget je "glup": dobija tabove i izabrani indeks kroz konstruktor.
class TopTabBar extends StatelessWidget {
  const TopTabBar({
    super.key,
    required this.tabs,
    required this.currentIndex,
    required this.onSelected,
  });

  final List<TopTab> tabs;
  final int currentIndex;
  final ValueChanged<int> onSelected;

  /// Visina trake. Krupno namerno — meta za prst je cela visina taba.
  static const double height = 82;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: const BoxDecoration(
        // Bez sopstvene boje, da se vidi pozadina u pokretu (proba).
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Row(
        children: [
          for (var i = 0; i < tabs.length; i++) ...[
            if (i > 0) const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: _TabButton(
                tab: tabs[i],
                isSelected: i == currentIndex,
                onTap: () => onSelected(i),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Jedno dugme u traci.
///
/// Zakošenje se pravi od **dva sloja**: spoljni sloj je tanak okvir koji je
/// gore svetliji a dole tamniji (to je ono što oko čita kao ivicu uhvaćenu u
/// svetlu), a unutrašnji je lice dugmeta. Flutter ne dozvoljava okvir sa
/// različitim bojama stranica ako je zaobljen, pa je ovo i jedini način da
/// bevel i zaobljeni uglovi idu zajedno.
class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.tab,
    required this.isSelected,
    required this.onTap,
  });

  final TopTab tab;
  final bool isSelected;
  final VoidCallback onTap;

  static const double _radius = 12;
  static const double _bevel = 2;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Poštuje se sistemsko podešavanje za smanjen pokret.
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final duration = reduceMotion
        ? Duration.zero
        : const Duration(milliseconds: 150);

    final color = isSelected ? AppColors.accent : AppColors.textSecondary;

    return Semantics(
      selected: isSelected,
      button: true,
      // Izabrani tab svetli kao neon i polako diše (proba).
      child: NeonGlow(
        active: isSelected,
        borderRadius: _radius,
        intensity: 0.8,
        child: AnimatedContainer(
          duration: duration,
          curve: Curves.easeOut,
          padding: const EdgeInsets.all(_bevel),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_radius),
            // Spoljni sloj = zakošena ivica. Izdignuto: svetlo gore, tama dole.
            // Utisnuto: obrnuto, pa dugme deluje uvučeno u podlogu.
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isSelected
                  ? const [AppColors.accent, AppColors.accentDeep]
                  : const [AppColors.backgroundBottom, AppColors.border],
            ),
            boxShadow: isSelected
                ? const [
                    // Senka ispod izdignutog dugmeta.
                    BoxShadow(
                      color: AppColors.backgroundBottom,
                      offset: Offset(0, 3),
                      blurRadius: 8,
                    ),
                    // Blagi sjaj oko izabranog taba.
                    BoxShadow(
                      color: AppColors.accentDeep,
                      blurRadius: 14,
                      spreadRadius: -2,
                    ),
                  ]
                : null,
          ),
          child: AnimatedContainer(
            duration: duration,
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(_radius - _bevel),
              // Unutrašnji sloj = lice dugmeta.
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isSelected
                    ? const [AppColors.surfaceAlt, AppColors.surface]
                    : const [AppColors.surface, AppColors.backgroundBottom],
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(_radius - _bevel),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(tab.icon, size: 28, color: color),
                    const SizedBox(height: 2),
                    // Nazivi tabova su kratki, ali sistemski font ume da bude
                    // uvećan — tekst se skuplja umesto da se lomi u dva reda.
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          tab.label,
                          maxLines: 1,
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: color,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// Zajednički header iznad tabova.
///
/// Po specifikaciji ovde stoji **logotip tima**, ne naziv taba — koji je tab
/// otvoren već se vidi u donjoj navigaciji, pa bi naslov gore bio ponavljanje.
///
/// Dok logotip ne postoji (nije izabran, ili tek treba da se napravi biranje
/// slike), prikazuje se ime aplikacije. Header nikad nije prazan.
class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  const AppHeader({super.key, this.logo});

  /// Logotip tima. `null` znači da nije izabran.
  final ImageProvider? logo;

  static const double _height = 56;
  static const double _logoHeight = 32;

  @override
  Size get preferredSize => const Size.fromHeight(_height);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: _height,
      decoration: const BoxDecoration(
        gradient: AppGradients.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Align(
            alignment: Alignment.centerLeft,
            child: logo != null
                ? Image(
                    image: logo!,
                    height: _logoHeight,
                    fit: BoxFit.contain,
                    // Neispravna slika ne sme da obori header.
                    errorBuilder: (context, error, stackTrace) =>
                        _Wordmark(theme: theme),
                  )
                : _Wordmark(theme: theme),
          ),
        ),
      ),
    );
  }
}

/// Ime aplikacije kao zamena dok logotipa nema.
class _Wordmark extends StatelessWidget {
  const _Wordmark({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Text(
      'e-vent',
      style: theme.textTheme.titleLarge?.copyWith(
        color: AppColors.accent,
        fontWeight: FontWeight.w600,
        letterSpacing: 1,
      ),
    );
  }
}

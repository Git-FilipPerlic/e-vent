import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// Zajednički header iznad tabova.
///
/// Po specifikaciji ovde stoji **logotip tima**, ne naziv taba — koji je tab
/// otvoren već se vidi u tabovima ispod, pa bi naslov gore bio ponavljanje.
///
/// Slika ide **preko cele trake**, kao baner, a ne kao sličica u uglu.
/// Dok logotipa nema, prikazuje se ime aplikacije. Header nikad nije prazan.
///
/// Widget je "glup": dobija sliku i dozvolu kroz konstruktor, a promenu
/// logotipa javlja kroz `onEditLogo`.
class AppHeader extends StatelessWidget {
  const AppHeader({super.key, this.logo, this.onEditLogo, this.onRemoveLogo});

  /// Logotip tima. `null` znači da nije izabran.
  final ImageProvider? logo;

  /// Poziva se kad korisnik hoće da promeni logotip. `null` znači da nema
  /// dozvolu — menjanje logotipa je funkcija managementa i traži prijavu.
  final VoidCallback? onEditLogo;

  /// Poziva se kad korisnik hoće da ukloni logotip. `null` kad nema dozvole
  /// ili kad logotipa ionako nema.
  final VoidCallback? onRemoveLogo;

  /// Visina trake, bez statusne trake telefona.
  static const double height = 72;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canEdit = onEditLogo != null;
    final image = logo;

    return SizedBox(
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Podloga: slika preko cele trake, ili ime aplikacije kad slike nema.
          if (image != null)
            Image(
              image: image,
              fit: BoxFit.cover,
              // Obrisana ili neispravna slika ne sme da obori header.
              errorBuilder: (context, error, stackTrace) =>
                  _Wordmark(theme: theme),
            )
          else
            _Wordmark(theme: theme),

          // Zatamnjenje uz desnu ivicu, da se ikonice vide i na svetloj slici.
          if (image != null && canEdit)
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerRight,
                  end: Alignment.center,
                  colors: [AppColors.background, Colors.transparent],
                ),
              ),
            ),

          if (canEdit)
            Align(
              alignment: Alignment.centerRight,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (onRemoveLogo != null)
                    IconButton(
                      onPressed: onRemoveLogo,
                      icon: const Icon(Icons.hide_image_outlined),
                      iconSize: 22,
                      color: AppColors.textSecondary,
                      tooltip: 'Ukloni logotip',
                    ),
                  IconButton(
                    onPressed: onEditLogo,
                    icon: const Icon(Icons.image_outlined),
                    iconSize: 22,
                    color: AppColors.accent,
                    tooltip: 'Promeni logotip tima',
                  ),
                  const SizedBox(width: AppSpacing.xs),
                ],
              ),
            ),

          // Razdelnik prema tabovima ispod.
          const Align(
            alignment: Alignment.bottomCenter,
            child: Divider(height: 1),
          ),
        ],
      ),
    );
  }
}

/// Ime aplikacije — podloga kad logotipa nema.
class _Wordmark extends StatelessWidget {
  const _Wordmark({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppGradients.surface),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      alignment: Alignment.centerLeft,
      child: Text(
        'e-vent',
        style:
            theme.textTheme.headlineSmall?.copyWith(
              color: AppColors.accent,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ) ??
            const TextStyle(color: AppColors.accent),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// Zajednički header iznad tabova.
///
/// Po specifikaciji ovde stoji **logotip tima**, ne naziv taba — koji je tab
/// otvoren već se vidi u tabovima ispod, pa bi naslov gore bio ponavljanje.
///
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

  /// Visina trake sa logotipom, bez statusne trake telefona.
  static const double height = 72;

  /// Logotip zauzima skoro celu visinu trake — dovoljno da se prepozna
  /// i fotografija, a ne samo čist znak na providnoj podlozi.
  static const double _logoHeight = 52;

  @override
  Widget build(BuildContext context) {
    final canEdit = onEditLogo != null;

    return Container(
      decoration: const BoxDecoration(
        gradient: AppGradients.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: SizedBox(
        height: height,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Row(
            children: [
              Expanded(child: _LogoOrName(logo: logo)),
              if (canEdit && onRemoveLogo != null)
                IconButton(
                  onPressed: onRemoveLogo,
                  icon: const Icon(Icons.hide_image_outlined),
                  iconSize: 22,
                  color: AppColors.textSecondary,
                  tooltip: 'Ukloni logotip',
                ),
              if (canEdit)
                IconButton(
                  onPressed: onEditLogo,
                  icon: const Icon(Icons.image_outlined),
                  iconSize: 22,
                  color: AppColors.accent,
                  tooltip: 'Promeni logotip tima',
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Logotip ako postoji, inače ime aplikacije.
class _LogoOrName extends StatelessWidget {
  const _LogoOrName({required this.logo});

  final ImageProvider? logo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final image = logo;

    final Widget wordmark = Text(
      'e-vent',
      style:
          theme.textTheme.headlineSmall?.copyWith(
            color: AppColors.accent,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ) ??
          const TextStyle(color: AppColors.accent),
    );

    if (image == null) {
      return Align(alignment: Alignment.centerLeft, child: wordmark);
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: ClipRRect(
        // Fotografija bez zaobljenja izgleda kao zalepljena nalepnica.
        borderRadius: BorderRadius.circular(AppSpacing.sm),
        child: Image(
          image: image,
          height: AppHeader._logoHeight,
          fit: BoxFit.contain,
          // Obrisana ili neispravna slika ne sme da obori header.
          errorBuilder: (context, error, stackTrace) => wordmark,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// Zajednički header iznad tabova.
///
/// Po specifikaciji ovde stoji **logotip tima**, ne naziv taba — koji je tab
/// otvoren već se vidi u donjoj navigaciji, pa bi naslov gore bio ponavljanje.
///
/// Dok logotipa nema, prikazuje se ime aplikacije. Header nikad nije prazan.
///
/// Widget je "glup": dobija sliku i dozvolu kroz konstruktor, a promenu
/// logotipa javlja kroz `onEditLogo`.
class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  const AppHeader({super.key, this.logo, this.onEditLogo, this.onRemoveLogo});

  /// Logotip tima. `null` znači da nije izabran.
  final ImageProvider? logo;

  /// Poziva se kad korisnik hoće da promeni logotip. `null` znači da nema
  /// dozvolu — menjanje logotipa je funkcija managementa i traži prijavu.
  final VoidCallback? onEditLogo;

  /// Poziva se kad korisnik hoće da ukloni logotip. `null` kad nema dozvole
  /// ili kad logotipa ionako nema.
  final VoidCallback? onRemoveLogo;

  static const double _height = 56;
  static const double _logoHeight = 32;

  @override
  Size get preferredSize => const Size.fromHeight(_height);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canEdit = onEditLogo != null;

    return Container(
      height: _height,
      decoration: const BoxDecoration(
        gradient: AppGradients.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.only(left: AppSpacing.md),
          child: Row(
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _LogoOrName(logo: logo, theme: theme),
                ),
              ),
              if (canEdit && onRemoveLogo != null)
                IconButton(
                  onPressed: onRemoveLogo,
                  icon: const Icon(Icons.hide_image_outlined),
                  iconSize: 20,
                  color: AppColors.textSecondary,
                  tooltip: 'Ukloni logotip',
                ),
              if (canEdit)
                IconButton(
                  onPressed: onEditLogo,
                  icon: const Icon(Icons.image_outlined),
                  iconSize: 20,
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
  const _LogoOrName({required this.logo, required this.theme});

  final ImageProvider? logo;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final image = logo;
    if (image == null) return _wordmark;

    return Image(
      image: image,
      height: AppHeader._logoHeight,
      fit: BoxFit.contain,
      // Obrisana ili neispravna slika ne sme da obori header.
      errorBuilder: (context, error, stackTrace) => _wordmark,
    );
  }

  Widget get _wordmark => Text(
    'e-vent',
    style:
        theme.textTheme.titleLarge?.copyWith(
          color: AppColors.accent,
          fontWeight: FontWeight.w600,
          letterSpacing: 1,
        ) ??
        const TextStyle(color: AppColors.accent),
  );
}

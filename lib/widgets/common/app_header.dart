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
  const AppHeader({
    super.key,
    this.logo,
    this.signedInAs,
    this.onOpenConsole,
    this.onBack,
  });

  /// Vraća na spisak događaja. `null` kad je spisak već otvoren.
  final VoidCallback? onBack;

  /// Ko je prijavljen. **Ne ispisuje se u headeru** — samo određuje da li
  /// dugme vodi u prijavu ili u konzolu. Ime je stajalo preko banera, a piše
  /// u konzoli, gde mu je i mesto.
  final String? signedInAs;

  /// Otvara prijavu, odnosno konzolu kad je neko već prijavljen.
  ///
  /// **Jedno jedino dugme.** Ranije ih je ovde stajalo troje — prijava,
  /// promena i uklanjanje logotipa — i prekrivala su sam baner. Logotip se
  /// menja retko i samo uz prijavu, pa mu je mesto u konzoli.
  final VoidCallback? onOpenConsole;

  /// Logotip tima. `null` znači da nije izabran.
  final ImageProvider? logo;

  /// Visina trake, bez statusne trake telefona.
  static const double height = 72;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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

          if (onBack != null)
            Align(
              alignment: Alignment.centerLeft,
              child: DecoratedBox(
                // Isto zatamnjenje kao desno: strelica mora da se vidi i
                // preko svetlog banera.
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerRight,
                    end: Alignment.centerLeft,
                    colors: [
                      Colors.transparent,
                      AppColors.background,
                      AppColors.background,
                    ],
                    stops: [0, 0.35, 1],
                  ),
                ),
                child: IconButton(
                  onPressed: onBack,
                  icon: const Icon(Icons.arrow_back_rounded),
                  iconSize: 22,
                  color: AppColors.accent,
                  tooltip: 'Nazad na spisak događaja',
                ),
              ),
            ),

          Align(
            alignment: Alignment.centerRight,
            child: DecoratedBox(
              // Zatamnjenje ide **ispod same grupe dugmadi**, a ne preko pola
              // trake: logotip ostaje vidljiv, a ikonice se čitaju i na
              // svetloj slici. Ranije se ime korisnika gubilo u baneru.
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Colors.transparent,
                    AppColors.background,
                    AppColors.background,
                  ],
                  stops: const [0, 0.35, 1],
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                  children: [
                  if (onOpenConsole != null)
                    IconButton(
                      onPressed: onOpenConsole,
                      icon: Icon(
                        signedInAs == null
                            ? Icons.login_rounded
                            : Icons.manage_accounts_rounded,
                      ),
                      iconSize: 22,
                      color: AppColors.accent,
                      tooltip: signedInAs == null ? 'Prijava' : 'Konzola',
                    ),
                  const SizedBox(width: AppSpacing.xs),
                ],
              ),
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

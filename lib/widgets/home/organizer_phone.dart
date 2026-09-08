import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../theme/app_theme.dart';
import '../common/copy_button.dart';

/// HOME-004 — telefon organizatora sa tri akcije: pozovi, SMS, kopiraj.
///
/// Akcije su **samo ikonice, u jednom redu uz sam broj**. Tako kartica stane
/// u jedan red i na ekran ulazi više podataka — a sledeći podatak (adresa na
/// koju se putuje) je odmah tu, bez skrolovanja.
///
/// Ikonice su bez natpisa, ali svaka ima opis za čitač ekrana i tooltip pri
/// dužem pritisku; dodirna meta ostaje puna, 48 dp.
///
/// Widget je "glup": prima gotov broj kroz konstruktor. Pozivanje i SMS nisu
/// podaci nego radnje nad telefonom, pa ih widget pokreće sam preko
/// `url_launcher` — ni ovde se ne dira servis ni baza.
class OrganizerPhone extends StatelessWidget {
  const OrganizerPhone({super.key, required this.phone});

  /// Broj telefona. Može da bude `null` ili prazan — tada se prikazuje
  /// objašnjenje, bez ikonica.
  final String? phone;

  /// Broj kakav se šalje telefonu: bez razmaka, crtica i zagrada.
  /// Vodeći `+` (pozivni broj države) ostaje.
  static String _forDialing(String value) {
    return value.replaceAll(RegExp(r'[^0-9+]'), '');
  }

  Future<void> _open(BuildContext context, Uri uri, String failureText) async {
    final messenger = ScaffoldMessenger.of(context);
    final opened = await launchUrl(uri);
    if (opened) return;

    // Na tabletu bez SIM kartice ili u emulatoru ovoga nema — bolje poruka
    // nego da ikonica deluje pokvareno.
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(content: Text(failureText)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final value = phone?.trim() ?? '';
    final hasPhone = value.isNotEmpty;
    final dialable = hasPhone ? _forDialing(value) : '';

    return Card(
      child: Padding(
        padding: const EdgeInsets.only(
          left: AppSpacing.md,
          top: AppSpacing.sm,
          bottom: AppSpacing.sm,
          right: AppSpacing.xs,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    // Kratko namerno: organizator stoji u kartici iznad, pa
                    // "Telefon organizatora" pri uvećanom fontu samo lomi red.
                    'Telefon',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: AppColors.textSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  // Broj se pri uvećanom sistemskom fontu radije skuplja nego
                  // što se lomi na "+381641234 / 567".
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      hasPhone ? value : 'Telefon nije unet',
                      maxLines: 1,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: hasPhone
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                        fontWeight: hasPhone
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (hasPhone) ...[
              // Broj ne sme da dodiruje zeleno dugme za poziv.
              const SizedBox(width: AppSpacing.sm),
              _PhoneAction(
                icon: Icons.call_rounded,
                label: 'Pozovi',
                // Poziv je glavna radnja — jedina ikonica na punoj podlozi.
                isPrimary: true,
                onPressed: () => _open(
                  context,
                  Uri(scheme: 'tel', path: dialable),
                  'Pozivanje nije moguće na ovom uređaju.',
                ),
              ),
              _PhoneAction(
                icon: Icons.sms_rounded,
                label: 'Pošalji SMS',
                onPressed: () => _open(
                  context,
                  Uri(scheme: 'sms', path: dialable),
                  'Slanje poruke nije moguće na ovom uređaju.',
                ),
              ),
              CopyButton(value: value, label: 'Telefon'),
            ],
          ],
        ),
      ),
    );
  }
}

/// Jedna akcija nad brojem, kao ikonica.
class _PhoneAction extends StatelessWidget {
  const _PhoneAction({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.isPrimary = false,
  });

  final IconData icon;

  /// Opis radnje — za tooltip i za čitač ekrana; ikonica bez natpisa
  /// inače ne bi ništa značila slepom korisniku.
  final String label;

  final VoidCallback onPressed;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon),
        iconSize: 22,
        tooltip: label,
        style: isPrimary
            ? IconButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: AppColors.background,
              )
            : IconButton.styleFrom(foregroundColor: AppColors.accent),
      ),
    );
  }
}

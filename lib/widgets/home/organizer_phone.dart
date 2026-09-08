import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../theme/app_theme.dart';
import '../common/copy_button.dart';

/// HOME-004 — telefon organizatora sa tri akcije: pozovi, SMS, kopiraj.
///
/// Dugmad idu jedno **ispod** drugog, preko cele širine. Kad je sistemski
/// font uvećan (a mnogi ga uvećaju), tekst u uskim dugmadima se lomi na
/// "Poz / ovi" — puna širina to ne dozvoljava, a i meta za prst je veća.
///
/// Widget je "glup": prima gotov broj kroz konstruktor. Pozivanje i SMS nisu
/// podaci nego radnje nad telefonom, pa ih widget pokreće sam preko
/// `url_launcher` — ni ovde se ne dira servis ni baza.
class OrganizerPhone extends StatelessWidget {
  const OrganizerPhone({super.key, required this.phone});

  /// Broj telefona. Može da bude `null` ili prazan — tada se prikazuje
  /// objašnjenje, bez dugmadi.
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
    // nego da dugme deluje pokvareno.
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
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Telefon organizatora',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: AppColors.textSecondary,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        hasPhone ? value : 'Telefon nije unet',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: hasPhone
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                          fontWeight: hasPhone
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                // Kopiranje je sitna radnja — ostaje ikonica uz sam broj.
                if (hasPhone) CopyButton(value: value, label: 'Telefon'),
              ],
            ),
            if (hasPhone) ...[
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => _open(
                    context,
                    Uri(scheme: 'tel', path: dialable),
                    'Pozivanje nije moguće na ovom uređaju.',
                  ),
                  icon: const Icon(Icons.call_rounded),
                  label: const Text('Pozovi'),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _open(
                    context,
                    Uri(scheme: 'sms', path: dialable),
                    'Slanje poruke nije moguće na ovom uređaju.',
                  ),
                  icon: const Icon(Icons.sms_rounded),
                  label: const Text('Pošalji SMS'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

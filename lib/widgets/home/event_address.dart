import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../theme/app_theme.dart';
import '../common/copy_button.dart';

/// HOME-003 — adresa događaja: grad, tekst adrese i dugme "Navigacija".
///
/// **Mini mape više nema.** Statična sličica ulice ne govori ništa što adresa
/// već ne kaže, a zauzimala je pola ekrana i vukla pločice sa mreže. Snalaženje
/// ide kroz "Navigacija", u aplikaciji koju korisnik već ima na telefonu
/// (Google Maps, Waze...).
///
/// Widget je "glup": prima gotovu adresu i koordinate kroz konstruktor.
class EventAddress extends StatelessWidget {
  const EventAddress({
    super.key,
    required this.address,
    this.latitude,
    this.longitude,
  });

  /// Tekst adrese. Može da bude `null` ili prazan.
  final String? address;

  /// Koordinate idu u paru — ako fali jedna, mape nema, ali adresa i dalje
  /// može da se otvori po tekstu.
  final double? latitude;
  final double? longitude;

  /// Grad iz adrese — sve posle poslednjeg zareza
  /// ("Bulevar Oslobođenja 45, Novi Sad" → "Novi Sad").
  ///
  /// Piše se sitno uz naslov kartice: to je podatak koji se hvata pogledom
  /// ("gde se putuje"). **Velikim početnim slovom**, kako se imena mesta i
  /// pišu — velikim slovom se piše ime, ne stil kartice.
  static String? cityFrom(String address) {
    final parts = address.split(',');
    if (parts.length < 2) return null;
    final city = parts.last.trim();
    return city.isEmpty ? null : city;
  }

  /// Adresa bez grada ("Bulevar Oslobođenja 45, Novi Sad" →
  /// "Bulevar Oslobođenja 45").
  ///
  /// Grad već stoji u redu iznad, pa bi ga ulica samo ponovila.
  /// Adresa bez zareza ostaje kakva jeste.
  static String streetFrom(String address) {
    final parts = address.split(',');
    if (parts.length < 2) return address.trim();
    final street = parts.sublist(0, parts.length - 1).join(',').trim();
    return street.isEmpty ? address.trim() : street;
  }

  bool get _hasCoordinates => latitude != null && longitude != null;

  /// Adresa za navigaciju: ako ima koordinata, ide se na tačnu tačku,
  /// inače se prosleđuje tekst adrese pa mapa sama traži.
  Uri _navigationUri(String addressText) {
    final destination = _hasCoordinates
        ? '$latitude,$longitude'
        : addressText;
    return Uri.https('www.google.com', '/maps/dir/', {
      'api': '1',
      'destination': destination,
    });
  }

  Future<void> _openNavigation(BuildContext context, String addressText) async {
    final messenger = ScaffoldMessenger.of(context);
    final opened = await launchUrl(
      _navigationUri(addressText),
      mode: LaunchMode.externalApplication,
    );
    if (opened) return;

    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      const SnackBar(content: Text('Navigacija nije moguća na ovom uređaju.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final value = address?.trim() ?? '';
    final hasAddress = value.isNotEmpty;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Adresa',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: AppColors.textSecondary,
                    letterSpacing: 0.5,
                  ),
                ),
                if (hasAddress && cityFrom(value) != null) ...[
                  Text(
                    '  ·  ',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: AppColors.border,
                    ),
                  ),
                  Flexible(
                    child: Text(
                      cityFrom(value)!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: AppColors.accent,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                Expanded(
                  child: Text(
                    hasAddress ? streetFrom(value) : 'Adresa nije uneta',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: hasAddress
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                      fontWeight:
                          hasAddress ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
                if (hasAddress) CopyButton(value: value, label: 'Adresa'),
              ],
            ),
            if (hasAddress || _hasCoordinates) ...[
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => _openNavigation(context, value),
                  icon: const Icon(Icons.navigation_rounded, size: 20),
                  label: const Text('Navigacija'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

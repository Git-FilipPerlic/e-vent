import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../theme/app_theme.dart';
import '../common/copy_button.dart';

/// HOME-003 — adresa događaja: tekst, mini mapa i dugme "Navigacija".
///
/// Widget je "glup": prima gotovu adresu i koordinate kroz konstruktor.
/// Mapa je samo pregled — prava navigacija se otvara u aplikaciji koju
/// korisnik već ima na telefonu (Google Maps, Waze...).
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
  /// ("Bulevar Oslobođenja 45, Novi Sad" → "novi sad").
  ///
  /// Piše se **malim slovima**, sitno, uz naslov kartice: to je podatak koji
  /// se hvata pogledom ("gde se putuje"), pa ne sme da se otima od same adrese.
  static String? cityFrom(String address) {
    final parts = address.split(',');
    if (parts.length < 2) return null;
    final city = parts.last.trim();
    return city.isEmpty ? null : city.toLowerCase();
  }

  /// Visina mini mape. Dovoljno da se vidi ulica, a da ne pojede ekran.
  static const double _mapHeight = 160;

  /// Zumiranje na nivou ulice.
  static const double _mapZoom = 15;

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
                    hasAddress ? value : 'Adresa nije uneta',
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
            if (_hasCoordinates) ...[
              const SizedBox(height: AppSpacing.md),
              _MiniMap(center: LatLng(latitude!, longitude!), zoom: _mapZoom),
            ],
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

/// Mali pregled lokacije na mapi. Ne pomera se i ne zumira — služi samo da
/// se vidi gde je to; pravo snalaženje ide kroz dugme "Navigacija".
class _MiniMap extends StatelessWidget {
  const _MiniMap({required this.center, required this.zoom});

  final LatLng center;
  final double zoom;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(kCardRadius),
      child: SizedBox(
        height: EventAddress._mapHeight,
        child: FlutterMap(
          options: MapOptions(
            initialCenter: center,
            initialZoom: zoom,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.none,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              // OSM traži da se aplikacija predstavi pravim imenom paketa
              // (isti applicationId kao u android/app/build.gradle.kts).
              userAgentPackageName: 'com.eventapp.event_app',
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: center,
                  width: 36,
                  height: 36,
                  child: const Icon(
                    Icons.location_on,
                    color: AppColors.accent,
                    size: 36,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

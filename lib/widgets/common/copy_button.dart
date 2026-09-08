import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_theme.dart';

/// Dugme "kopiraj" — prepiše zadati tekst u clipboard i potvrdi porukom
/// pri dnu ekrana.
///
/// Koristi se svuda gde neki podatak treba brzo proslediti dalje
/// (ime organizatora, telefon, adresa). Widget je "glup": dobija gotov
/// tekst kroz konstruktor i ne zna odakle je došao.
class CopyButton extends StatelessWidget {
  const CopyButton({super.key, required this.value, required this.label});

  /// Tekst koji se kopira.
  final String value;

  /// Naziv podatka, samo za poruku potvrde ("Kopirano: Telefon").
  /// Oblik poruke je namerno neutralan, da ne zavisi od roda reči.
  final String label;

  Future<void> _copy(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    await Clipboard.setData(ClipboardData(text: value));
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text('Kopirano: $label'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () => _copy(context),
      icon: const Icon(Icons.copy_rounded),
      iconSize: 20,
      color: AppColors.accent,
      tooltip: 'Kopiraj',
    );
  }
}

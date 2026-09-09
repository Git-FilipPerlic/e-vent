import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_theme.dart';

/// Unos jednog podatka o događaju, u listu koja se izvuče odozdo.
///
/// Kartice na Home tabu se **ne prave dvaput**: iste su i za čitanje i za
/// unos. Kad korisnik ima dozvolu, na kartici se pojavi olovka koja otvara
/// ovaj list — tako se ekran ne pretvara u obrazac, a podatak se i dalje menja
/// jednim dodirom.
///
/// Vraća novi tekst, ili `null` ako je korisnik odustao. **Prazan tekst je
/// ispravan odgovor** — njime se podatak briše.
Future<String?> showEditTextSheet(
  BuildContext context, {
  required String label,
  required String? value,
  String? hint,
  TextInputType keyboardType = TextInputType.text,
  int maxLines = 1,
}) {
  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: AppColors.surface,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => _EditTextSheet(
      label: label,
      value: value,
      hint: hint,
      keyboardType: keyboardType,
      maxLines: maxLines,
    ),
  );
}

class _EditTextSheet extends StatefulWidget {
  const _EditTextSheet({
    required this.label,
    required this.value,
    required this.hint,
    required this.keyboardType,
    required this.maxLines,
  });

  final String label;
  final String? value;
  final String? hint;
  final TextInputType keyboardType;
  final int maxLines;

  @override
  State<_EditTextSheet> createState() => _EditTextSheetState();
}

class _EditTextSheetState extends State<_EditTextSheet> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.value ?? '',
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() => Navigator.of(context).pop(_controller.text);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        // Tastatura ne sme da prekrije polje.
        padding: EdgeInsets.only(
          left: AppSpacing.md,
          right: AppSpacing.md,
          bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.md,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.label,
              style: theme.textTheme.titleMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _controller,
              autofocus: true,
              keyboardType: widget.keyboardType,
              maxLines: widget.maxLines,
              textInputAction: widget.maxLines > 1
                  ? TextInputAction.newline
                  : TextInputAction.done,
              onSubmitted: widget.maxLines > 1 ? null : (_) => _submit(),
              inputFormatters: widget.keyboardType == TextInputType.phone
                  ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9+ ()-]'))]
                  : null,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: widget.hint,
                hintStyle: const TextStyle(color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.surfaceAlt,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              // Ljudi se plaše da obrišu polje, pa im se kaže da sme.
              'Prazno polje briše podatak.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Odustani'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: FilledButton(
                    onPressed: _submit,
                    child: const Text('Sačuvaj'),
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

/// Olovka koja stoji na kartici kad korisnik sme da menja podatak.
///
/// Kad dozvole nema, kartica je ista — samo bez ovog dugmeta.
class EditFieldButton extends StatelessWidget {
  const EditFieldButton({super.key, required this.label, required this.onTap});

  /// Šta se menja — za čitač ekrana i tooltip.
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Izmeni: $label',
      child: IconButton(
        onPressed: onTap,
        icon: const Icon(Icons.edit_rounded),
        iconSize: 18,
        color: AppColors.accent,
        tooltip: 'Izmeni',
      ),
    );
  }
}

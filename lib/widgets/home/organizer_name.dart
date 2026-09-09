import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../common/copy_button.dart';
import '../common/edit_text_sheet.dart';

/// HOME-002 — ime organizatora (roditelja) i dugme za kopiranje.
///
/// Widget je "glup": prima gotov tekst kroz konstruktor, ne zna ništa
/// o servisu ni o bazi.
class OrganizerName extends StatelessWidget {
  const OrganizerName({super.key, required this.name, this.onEdit});

  /// Otvara izmenu imena. `null` kad korisnik nema dozvolu.
  final VoidCallback? onEdit;

  /// Ime organizatora. Može da bude `null` ili prazno — tada se prikazuje
  /// objašnjenje, a dugme za kopiranje se ne prikazuje (nema šta da se kopira).
  final String? name;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final value = name?.trim() ?? '';
    final hasName = value.isNotEmpty;

    return Card(
      child: Padding(
        padding: const EdgeInsets.only(
          left: AppSpacing.md,
          top: AppSpacing.md,
          bottom: AppSpacing.md,
          // Desno manje, jer dugme već ima svoj prazan prostor oko sebe.
          right: AppSpacing.sm,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Organizator',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: AppColors.textSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    hasName ? value : 'Organizator nije unet',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: hasName
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                      fontWeight: hasName ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            if (hasName)
              CopyButton(value: value, label: 'Ime organizatora'),
            if (onEdit != null)
              EditFieldButton(label: 'Organizator', onTap: onEdit!),
          ],
        ),
      ),
    );
  }
}

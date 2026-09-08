import 'package:flutter/material.dart';

import '../../models/vehicle.dart';
import '../../theme/app_theme.dart';

/// Vozilo kojim ekipa ide na događaj: prikaz izabranog, izbor iz liste
/// i dodavanje novog vozila.
///
/// (Zamena za HOME-008/009/010 iz starog spiska.)
///
/// Widget je "glup": dobija spisak vozila i izabrano vozilo kroz konstruktor,
/// a izbor i dodavanje javlja ekranu kroz `onSelected` i `onAdd`. Sam ne zna
/// ni za servis ni za bazu.
class VehiclePicker extends StatelessWidget {
  const VehiclePicker({
    super.key,
    required this.vehicles,
    required this.selectedVehicleId,
    required this.onSelected,
    required this.onAdd,
    this.canEdit = true,
  });

  /// Sva vozila koja ekipa može da izabere.
  final List<Vehicle> vehicles;

  /// Trenutno izabrano vozilo. `null` znači da nije izabrano.
  final String? selectedVehicleId;

  /// Javlja ekranu koje je vozilo izabrano.
  final ValueChanged<String> onSelected;

  /// Javlja ekranu da treba dodati novo vozilo pod datim imenom.
  final ValueChanged<String> onAdd;

  /// Da li korisnik sme da menja vozilo. Bez dozvole se vidi samo naziv.
  final bool canEdit;

  Vehicle? get _selected {
    for (final v in vehicles) {
      if (v.id == selectedVehicleId) return v;
    }
    return null;
  }

  Future<void> _openPicker(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => _VehicleSheet(
        vehicles: vehicles,
        selectedVehicleId: selectedVehicleId,
        onSelected: onSelected,
        onAdd: onAdd,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selected = _selected;

    return Card(
      child: InkWell(
        onTap: canEdit ? () => _openPicker(context) : null,
        borderRadius: BorderRadius.circular(kCardRadius),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              const Icon(
                Icons.local_shipping_rounded,
                color: AppColors.textSecondary,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Vozilo',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: AppColors.textSecondary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      selected?.name ?? 'Vozilo nije izabrano',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: selected != null
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                        fontWeight: selected != null
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              if (canEdit)
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.accent,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Spisak vozila u listi koja se izvuče odozdo, plus red za dodavanje novog.
class _VehicleSheet extends StatefulWidget {
  const _VehicleSheet({
    required this.vehicles,
    required this.selectedVehicleId,
    required this.onSelected,
    required this.onAdd,
  });

  final List<Vehicle> vehicles;
  final String? selectedVehicleId;
  final ValueChanged<String> onSelected;
  final ValueChanged<String> onAdd;

  @override
  State<_VehicleSheet> createState() => _VehicleSheetState();
}

class _VehicleSheetState extends State<_VehicleSheet> {
  final TextEditingController _newVehicle = TextEditingController();
  bool _isAdding = false;

  @override
  void dispose() {
    _newVehicle.dispose();
    super.dispose();
  }

  void _submitNewVehicle() {
    final name = _newVehicle.text.trim();
    // Prazno ime se ne prihvata — ćutke, bez poruke o grešci.
    if (name.isEmpty) return;

    widget.onAdd(name);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        // Tastatura ne sme da prekrije polje za unos novog vozila.
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                0,
                AppSpacing.md,
                AppSpacing.sm,
              ),
              child: Text(
                'Izaberi vozilo',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (widget.vehicles.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                child: Text(
                  'Nijedno vozilo još nije uneto.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: widget.vehicles.length,
                itemBuilder: (context, index) {
                  final vehicle = widget.vehicles[index];
                  final isSelected = vehicle.id == widget.selectedVehicleId;

                  return ListTile(
                    minTileHeight: kMinTouchTarget,
                    tileColor: isSelected
                        ? AppColors.surfaceAlt
                        : Colors.transparent,
                    title: Text(
                      vehicle.name,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(
                            Icons.check_rounded,
                            color: AppColors.accent,
                          )
                        : null,
                    onTap: () {
                      widget.onSelected(vehicle.id);
                      Navigator.of(context).pop();
                    },
                  );
                },
              ),
            ),
            const Divider(),
            if (!_isAdding)
              ListTile(
                minTileHeight: kMinTouchTarget,
                leading: const Icon(Icons.add_rounded, color: AppColors.accent),
                title: const Text(
                  'Dodaj vozilo',
                  style: TextStyle(color: AppColors.accent),
                ),
                onTap: () => setState(() => _isAdding = true),
              )
            else
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _newVehicle,
                        autofocus: true,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _submitNewVehicle(),
                        style: const TextStyle(color: AppColors.textPrimary),
                        decoration: const InputDecoration(
                          hintText: 'Naziv vozila',
                          hintStyle: TextStyle(color: AppColors.textSecondary),
                          filled: true,
                          fillColor: AppColors.surfaceAlt,
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    FilledButton(
                      onPressed: _submitNewVehicle,
                      child: const Text('Sačuvaj'),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../services/led_controller.dart';
import '../theme/app_theme.dart';

/// LED tab — kontrola Magic Home rasvete preko lokalne mreže.
///
/// Telefon i kontroler moraju biti **na istoj Wi-Fi mreži** (obično onoj koju
/// pravi sam kontroler). Kad nisu, ekran to i kaže umesto da se vrti u
/// prazno — to je najčešći razlog zašto ovakve aplikacije „ne rade".
///
/// Ekran je jedini koji priča sa kontrolerom; boje i dugmad ne znaju ništa o
/// mreži.
class LedScreen extends StatefulWidget {
  const LedScreen({super.key, this.controller});

  /// Izvor kontrole. `null` znači pravi Magic Home; testovi ubacuju svoj.
  final LedController? controller;

  @override
  State<LedScreen> createState() => _LedScreenState();
}

class _LedScreenState extends State<LedScreen> {
  late final LedController _led = widget.controller ?? MagicHomeController();

  List<LedDevice> _devices = const [];
  String? _connectedTo;

  bool _isSearching = false;
  bool _isBusy = false;
  String? _message;

  /// Poslednja poslata boja — da se vidi šta je izabrano.
  Color? _color;

  /// Boje koje se zaista koriste na nastupu. Namerno malo njih i krupne:
  /// bira se u mraku, iz ruke.
  static const List<Color> _palette = [
    Color(0xFFFF0000),
    Color(0xFFFF7A00),
    Color(0xFFFFD400),
    Color(0xFF25D366),
    Color(0xFF00C2FF),
    Color(0xFF0038FF),
    Color(0xFF8A2BE2),
    Color(0xFFFF2D95),
    Color(0xFFFFFFFF),
  ];

  @override
  void dispose() {
    _led.disconnect();
    super.dispose();
  }

  Future<void> _search() async {
    setState(() {
      _isSearching = true;
      _message = null;
    });

    final devices = await _led.discover();
    if (!mounted) return;

    setState(() {
      _devices = devices;
      _isSearching = false;
      _message = devices.isEmpty
          ? 'Nijedan kontroler nije nađen. Proveri da li je telefon na '
                'Wi-Fi mreži kontrolera.'
          : null;
    });
  }

  Future<void> _connect(String address) async {
    setState(() {
      _isBusy = true;
      _message = null;
    });

    try {
      await _led.connect(address);
      if (!mounted) return;
      setState(() {
        _connectedTo = address;
        _isBusy = false;
      });
    } on LedConnectionException {
      if (!mounted) return;
      setState(() {
        _isBusy = false;
        _message = 'Kontroler na $address se ne javlja.';
      });
    }
  }

  Future<void> _power(bool on) async {
    await _led.setPower(on);
    if (!mounted) return;
    setState(() => _message = null);
  }

  Future<void> _setColor(Color color) async {
    await _led.setColor(
      (color.r * 255).round(),
      (color.g * 255).round(),
      (color.b * 255).round(),
    );
    if (!mounted) return;
    setState(() => _color = color);
  }

  Future<void> _enterAddress() async {
    final address = await showDialog<String>(
      context: context,
      builder: (context) => const _AddressDialog(),
    );
    if (address == null || address.trim().isEmpty) return;
    await _connect(address.trim());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            if (_connectedTo == null) ..._connectSection() else ..._controls(),
            if (_message != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                _message!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<Widget> _connectSection() {
    final theme = Theme.of(context);

    return [
      Text(
        'Poveži se sa rasvetom',
        style: theme.textTheme.titleMedium?.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
      const SizedBox(height: AppSpacing.xs),
      Text(
        'Telefon mora da bude na istoj Wi-Fi mreži kao kontroler — obično na '
        'onoj koju kontroler sam pravi.',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
      const SizedBox(height: AppSpacing.md),
      FilledButton.icon(
        onPressed: _isSearching || _isBusy ? null : _search,
        icon: _isSearching
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.wifi_find_rounded, size: 20),
        label: Text(_isSearching ? 'Tražim…' : 'Potraži kontroler'),
      ),
      const SizedBox(height: AppSpacing.sm),
      // Broadcast ume da ne prođe kroz neke rutere; bez ručnog unosa bi tab
      // tada bio neupotrebljiv.
      OutlinedButton.icon(
        onPressed: _isBusy ? null : _enterAddress,
        icon: const Icon(Icons.keyboard_rounded, size: 20),
        label: const Text('Unesi adresu ručno'),
      ),
      for (final device in _devices) ...[
        const SizedBox(height: AppSpacing.sm),
        Card(
          child: ListTile(
            title: Text(
              device.label,
              style: const TextStyle(color: AppColors.textPrimary),
            ),
            subtitle: Text(
              device.address,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            trailing: const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.accent,
            ),
            onTap: _isBusy ? null : () => _connect(device.address),
          ),
        ),
      ],
    ];
  }

  List<Widget> _controls() {
    final theme = Theme.of(context);

    return [
      Row(
        children: [
          const Icon(
            Icons.lightbulb_rounded,
            color: AppColors.success,
            size: 20,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Povezano: $_connectedTo',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: AppSpacing.md),
      Row(
        children: [
          Expanded(
            child: FilledButton(
              onPressed: () => _power(true),
              child: const Text('Upali'),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: OutlinedButton(
              onPressed: () => _power(false),
              child: const Text('Ugasi'),
            ),
          ),
        ],
      ),
      const SizedBox(height: AppSpacing.lg),
      Text(
        'Boja',
        style: theme.textTheme.labelMedium?.copyWith(
          color: AppColors.textSecondary,
          letterSpacing: 0.5,
        ),
      ),
      const SizedBox(height: AppSpacing.sm),
      Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: [
          for (final (index, color) in _palette.indexed)
            _Swatch(
              // Ključ nosi redni broj, da se u testu pogodi baš to polje.
              key: ValueKey('boja-$index'),
              color: color,
              isSelected: _color == color,
              onTap: () => _setColor(color),
            ),
        ],
      ),
      const SizedBox(height: AppSpacing.lg),
      Text(
        'Redosled boja',
        style: theme.textTheme.labelMedium?.copyWith(
          color: AppColors.textSecondary,
          letterSpacing: 0.5,
        ),
      ),
      const SizedBox(height: AppSpacing.xs),
      Text(
        'Ako plavo daje zeleno, kontroler očekuje drugi redosled. Probaj '
        'ostale — to je stvar samog uređaja, ne aplikacije.',
        style: theme.textTheme.bodySmall?.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
      const SizedBox(height: AppSpacing.sm),
      Wrap(
        spacing: AppSpacing.sm,
        children: [
          for (final order in ColorOrder.values)
            ChoiceChip(
              label: Text(order.label),
              selected: _orderOf(_led) == order,
              onSelected: (_) => _setOrder(order),
            ),
        ],
      ),
    ];
  }

  ColorOrder? _orderOf(LedController led) =>
      led is MagicHomeController ? led.colorOrder : null;

  Future<void> _setOrder(ColorOrder order) async {
    final led = _led;
    if (led is! MagicHomeController) return;

    setState(() => led.colorOrder = order);
    // Boja se odmah šalje ponovo, da se promena vidi bez ponovnog biranja.
    final color = _color;
    if (color != null) await _setColor(color);
  }
}

/// Jedno polje boje. Krupno je namerno — bira se u mraku, iz ruke.
class _Swatch extends StatelessWidget {
  const _Swatch({
    super.key,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: isSelected,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(kCardRadius),
        child: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(kCardRadius),
            border: Border.all(
              color: isSelected ? AppColors.textPrimary : AppColors.border,
              width: isSelected ? 3 : 1,
            ),
          ),
        ),
      ),
    );
  }
}

/// Ručni unos IP adrese kontrolera.
class _AddressDialog extends StatefulWidget {
  const _AddressDialog();

  @override
  State<_AddressDialog> createState() => _AddressDialogState();
}

class _AddressDialogState extends State<_AddressDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() => Navigator.of(context).pop(_controller.text);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: const Text('Adresa kontrolera'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: TextInputType.number,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _submit(),
        style: const TextStyle(color: AppColors.textPrimary),
        decoration: const InputDecoration(
          hintText: 'na primer 192.168.4.1',
          hintStyle: TextStyle(color: AppColors.textSecondary),
          filled: true,
          fillColor: AppColors.surfaceAlt,
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Odustani'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Poveži se')),
      ],
    );
  }
}

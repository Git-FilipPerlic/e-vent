import 'package:flutter/material.dart';

import '../services/led_controller.dart';
import '../services/led_memory.dart';
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
  final LedMemory _memory = const LedMemory();

  List<LedDevice> _devices = const [];
  String? _connectedTo;

  /// Kontroler sa kog se poslednji put upravljalo. Ponudi se odmah, da se
  /// pred nastup ne traži mreža iznova.
  String? _lastAddress;

  /// Jačina svetla, 0..1.
  double _brightness = 1;

  /// Pokrenut efekat, ako je pokrenut. Boja i efekat se isključuju.
  LedEffect? _effect;

  /// Brzina efekta, 0..1.
  double _speed = 0.5;

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
  void initState() {
    super.initState();
    _loadMemory();
  }

  Future<void> _loadMemory() async {
    final address = await _memory.lastAddress();
    final order = await _memory.colorOrder();
    if (!mounted) return;

    setState(() {
      _lastAddress = address;
      final led = _led;
      if (led is MagicHomeController && order != null) {
        led.colorOrder = ColorOrder.values
            .where((value) => value.name == order)
            .firstOrNull ?? led.colorOrder;
      }
    });
  }

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
        _lastAddress = address;
        _isBusy = false;
      });
      await _remember();
    } on LedConnectionException {
      if (!mounted) return;
      setState(() {
        _isBusy = false;
        _message = 'Kontroler na $address se ne javlja.';
      });
    }
  }

  /// Pamti kontroler i redosled boja — oba su svojstvo samog uređaja.
  Future<void> _remember() async {
    final address = _connectedTo;
    if (address == null) return;

    final led = _led;
    await _memory.remember(
      address: address,
      colorOrder: led is MagicHomeController ? led.colorOrder.name : null,
    );
  }

  Future<void> _setBrightness(double value) async {
    setState(() => _brightness = value);
    await _led.setBrightness(value);
  }

  Future<void> _power(bool on) async {
    await _led.setPower(on);
    if (!mounted) return;
    setState(() => _message = null);
  }

  Future<void> _setColor(Color color) async {
    setState(() => _effect = null);
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
            // Kontrole se vide **i pre povezivanja**, samo ne rade. Ranije
            // ih uopšte nije bilo dok se ne poveže, pa je tab delovao prazno
            // i nije se videlo šta uopšte nudi.
            ..._connectSection(),
            const SizedBox(height: AppSpacing.lg),
            ..._controls(),
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
      // Poruka stoji **uz dugmad za povezivanje**, a ne na dnu ekrana:
      // govori o povezivanju, a dole se ne bi ni videla.
      if (_message != null) ...[
        const SizedBox(height: AppSpacing.sm),
        Text(
          _message!,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
      if (_lastAddress != null) ...[
        const SizedBox(height: AppSpacing.sm),
        // Kontroler gotovo uvek dobije istu adresu, pa se ovo isplati:
        // jedan dodir umesto traženja mreže pred nastup.
        OutlinedButton.icon(
          onPressed: _isBusy ? null : () => _connect(_lastAddress!),
          icon: const Icon(Icons.history_rounded, size: 20),
          label: Text('Poveži se ponovo ($_lastAddress)'),
        ),
      ],
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
    final on = _connectedTo != null;

    return [
      Row(
        children: [
          Icon(
            on ? Icons.lightbulb_rounded : Icons.lightbulb_outline_rounded,
            color: on ? AppColors.success : AppColors.textSecondary,
            size: 20,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              on ? 'Povezano: $_connectedTo' : 'Nije povezano',
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
              onPressed: on ? () => _power(true) : null,
              child: const Text('Upali'),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: OutlinedButton(
              onPressed: on ? () => _power(false) : null,
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
              onTap: on ? () => _setColor(color) : null,
            ),
        ],
      ),
      const SizedBox(height: AppSpacing.lg),
      Row(
        children: [
          Text(
            'Jačina svetla',
            style: theme.textTheme.labelMedium?.copyWith(
              color: AppColors.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
          const Spacer(),
          Text(
            '${(_brightness * 100).round()}%',
            style: theme.textTheme.labelMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
      // Magic Home nema zasebnu komandu za jačinu — šalje se ista boja,
      // utamnjena. Zato jačina i boja žive zajedno u kontroleru.
      Slider(
        value: _brightness,
        min: 0.05,
        onChanged: on
            ? (value) => setState(() => _brightness = value)
            : null,
        // Šalje se tek kad se prst podigne: svaki pomeraj bi bio nova poruka
        // kontroleru, pa bi svetlo poskakivalo.
        onChangeEnd: _setBrightness,
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
              onSelected: on ? (_) => _setOrder(order) : null,
            ),
        ],
      ),

      const SizedBox(height: AppSpacing.lg),
      Text(
        'Efekti',
        style: theme.textTheme.labelMedium?.copyWith(
          color: AppColors.textSecondary,
          letterSpacing: 0.5,
        ),
      ),
      const SizedBox(height: AppSpacing.xs),
      Text(
        // Bitno za nastup: rasveta ne staje ako telefonu padne mreža.
        'Efekat vrti sam kontroler, pa nastavlja da radi i kad se telefon '
        'zaključa ili izgubi Wi-Fi.',
        style: theme.textTheme.bodySmall?.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
      const SizedBox(height: AppSpacing.sm),
      Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: [
          for (final effect in LedEffect.values)
            ChoiceChip(
              label: Text(effect.label),
              selected: _effect == effect,
              onSelected: on ? (_) => _setEffect(effect) : null,
            ),
        ],
      ),
      const SizedBox(height: AppSpacing.sm),
      Row(
        children: [
          Text(
            'Brzina',
            style: theme.textTheme.labelMedium?.copyWith(
              color: AppColors.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
          Expanded(
            child: Slider(
              value: _speed,
              onChanged: on ? (value) => setState(() => _speed = value) : null,
              // Kao i kod jačine: šalje se tek kad se prst podigne.
              onChangeEnd: on ? (_) => _applySpeed() : null,
            ),
          ),
        ],
      ),
    ];
  }

  Future<void> _setEffect(LedEffect effect) async {
    setState(() {
      _effect = effect;
      // Efekat i boja se isključuju: kontroler radi ili jedno ili drugo.
      _color = null;
    });
    await _led.setEffect(effect, speed: _speed);
  }

  Future<void> _applySpeed() async {
    final effect = _effect;
    if (effect == null) return;
    await _led.setEffect(effect, speed: _speed);
  }

  ColorOrder? _orderOf(LedController led) =>
      led is MagicHomeController ? led.colorOrder : null;

  Future<void> _setOrder(ColorOrder order) async {
    final led = _led;
    if (led is! MagicHomeController) return;

    setState(() => led.colorOrder = order);
    await _remember();
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

  /// `null` dok kontroler nije povezan — polje se tada vidi, ali ne radi.
  final VoidCallback? onTap;

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

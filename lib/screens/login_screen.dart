import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/firebase_auth_service.dart';
import '../widgets/common/edit_text_sheet.dart';
import '../theme/app_theme.dart';

/// Prijava, a posle prijave i **konzola**.
///
/// Bez prijave aplikacija radi — samo se **ništa ne menja**: podaci o
/// događaju, vozilo i logotip se vide, ali se ne diraju. Prijava je prekidač
/// između čitanja i unosa, pa se ovaj ekran otvara samo kad zatreba.
///
/// Kad je neko već prijavljen, isti ekran pokazuje **ko je prijavljen,
/// logotip tima i odjavu**. Te stvari ne stoje u headeru na glavnoj strani:
/// tamo su tri ikonice prekrivale baner, a logotip se ionako menja retko i
/// samo uz prijavu.
class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    required this.auth,
    this.onEditLogo,
    this.onRemoveLogo,
    this.hasLogo = false,
    this.onOpenEquipment,
  });

  /// Otvara spisak opreme firme. `null` kad korisnik nema dozvolu.
  final VoidCallback? onOpenEquipment;

  final AuthService auth;

  /// Bira nov logotip tima. `null` kad korisnik nema dozvolu.
  final Future<void> Function()? onEditLogo;

  /// Uklanja logotip. `null` kad nema dozvole.
  final Future<void> Function()? onRemoveLogo;

  /// Da li logotip uopšte postoji — bez njega nema šta da se ukloni.
  final bool hasLogo;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _name = TextEditingController();
  final TextEditingController _pin = TextEditingController();

  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _name.dispose();
    _pin.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final error = await widget.auth.signIn(name: _name.text, pin: _pin.text);
    if (!mounted) return;

    if (error != null) {
      setState(() {
        _isSubmitting = false;
        _errorMessage = error;
      });
      return;
    }

    Navigator.of(context).pop(true);
  }

  /// Menja ime pod kojim te ekipa vidi.
  ///
  /// Podrazumevano stoji deo mejla pre @, a ljudi se pamte po imenu — pa se
  /// ovde upiše „Zvrk", „Mina", „Lole".
  Future<void> _editName() async {
    final auth = widget.auth;
    if (auth is! FirebaseAuthService) return;

    final name = await showEditTextSheet(
      context,
      label: 'Kako te ekipa vidi',
      value: auth.currentUser?.name,
      hint: 'na primer Zvrk',
    );
    if (name == null || !mounted) return;

    final error = await auth.setDisplayName(name);
    if (!mounted) return;

    if (error != null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    setState(() {});
  }

  Future<void> _signOut() async {
    await widget.auth.signOut();
    if (!mounted) return;
    Navigator.of(context).pop(false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = widget.auth.currentUser;

    return Scaffold(
      appBar: AppBar(title: Text(user == null ? 'Prijava' : 'Konzola')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: user != null ? _console(theme, user) : _signInForm(theme),
        ),
      ),
    );
  }

  /// Šta se vidi kad je neko već prijavljen.
  Widget _console(ThemeData theme, AppUser user) {
    final canEditLogo = widget.onEditLogo != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Prijavljen: ${user.name}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (widget.auth is FirebaseAuthService)
              EditFieldButton(label: 'Kako te ekipa vidi', onTap: _editName),
          ],
        ),
        Text(
          // Ovo je ono što ekipa vidi u „Ko radi" — zato se i menja odavde.
          'Pod ovim imenom te ekipa vidi kad ti se dodeli događaj.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          canEditLogo
              ? 'Dok si prijavljen, podaci o događaju se menjaju olovkama na '
                    'karticama.'
              : 'Vidiš sve, ali podatke tima menja onaj ko vodi ekipu.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),

        if (canEditLogo) ...[
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Logotip tima',
            style: theme.textTheme.labelMedium?.copyWith(
              color: AppColors.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Stoji u traci iznad tabova. Menja se odavde, ne sa glavne '
            'strane — tamo bi dugmad prekrivala samu sliku.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton.icon(
            onPressed: widget.onEditLogo,
            icon: const Icon(Icons.image_outlined, size: 20),
            label: const Text('Promeni logotip'),
          ),
          if (widget.hasLogo) ...[
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton.icon(
              onPressed: widget.onRemoveLogo,
              icon: const Icon(Icons.hide_image_outlined, size: 20),
              label: const Text('Ukloni logotip'),
            ),
          ],
        ],

        if (widget.onOpenEquipment != null) ...[
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Oprema firme',
            style: theme.textTheme.labelMedium?.copyWith(
              color: AppColors.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Spisak svih kategorija koje firma ima — Vatra, Svila, Tehnika, '
            'Kablovi… Na svakom događaju biraš koje se tog dana nose.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton.icon(
            onPressed: widget.onOpenEquipment,
            icon: const Icon(Icons.checklist_rounded, size: 20),
            label: const Text('Uredi spisak opreme'),
          ),
        ],

        const SizedBox(height: AppSpacing.xl),
        FilledButton.icon(
          onPressed: _signOut,
          icon: const Icon(Icons.logout_rounded, size: 20),
          label: const Text('Odjavi se'),
        ),
      ],
    );
  }

  /// Obrazac za prijavu.
  Widget _signInForm(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Prijava je potrebna samo za izmene',
          style: theme.textTheme.titleMedium?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Bez prijave se podaci o događaju, oprema i muzika normalno '
          'vide. Prijava otvara unos i deljenje podataka timu.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        TextField(
          controller: _name,
          autofocus: true,
          textInputAction: TextInputAction.next,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: const InputDecoration(
            labelText: 'Ime',
            labelStyle: TextStyle(color: AppColors.textSecondary),
            filled: true,
            fillColor: AppColors.surfaceAlt,
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: _pin,
          obscureText: true,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _submit(),
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: const InputDecoration(
            labelText: 'PIN',
            labelStyle: TextStyle(color: AppColors.textSecondary),
            filled: true,
            fillColor: AppColors.surfaceAlt,
            border: OutlineInputBorder(),
          ),
        ),
        if (_errorMessage != null) ...[
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: AppColors.danger,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  _errorMessage!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.danger,
                  ),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        FilledButton(
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Prijavi se'),
        ),
      ],
    );
  }
}

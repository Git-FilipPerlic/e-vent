import 'package:flutter/material.dart';

import '../services/file_browser.dart';
import '../theme/app_theme.dart';

/// Pregled fajlova na telefonu — kao Moji fajlovi, samo što prikazuje
/// isključivo foldere i numere.
///
/// Vraća spisak numera kroz `Navigator.pop`, ili `null` ako je korisnik
/// odustao.
///
/// Dodir na folder ulazi u njega. Dodir na numeru je označava. Dole stoje dva
/// dugmeta: **"Koristi ovaj folder"** uzima sve numere iz otvorenog foldera, a
/// **"Dodaj označene"** samo ono što je čekirano.
class FileBrowserScreen extends StatefulWidget {
  const FileBrowserScreen({super.key});

  @override
  State<FileBrowserScreen> createState() => _FileBrowserScreenState();
}

class _FileBrowserScreenState extends State<FileBrowserScreen> {
  /// Putanja otvorenog foldera. `null` znači da se gleda spisak nosača
  /// (memorija telefona, SD kartica).
  String? _path;

  List<BrowserEntry> _entries = const [];
  final Set<String> _selected = <String>{};

  bool _isLoading = true;
  bool _hasAccess = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final granted = await FileBrowser.hasAccess();
    if (!mounted) return;

    if (!granted) {
      setState(() {
        _hasAccess = false;
        _isLoading = false;
      });
      return;
    }

    setState(() => _hasAccess = true);
    await _open(null);
  }

  Future<void> _askForAccess() async {
    final granted = await FileBrowser.requestAccess();
    if (!mounted) return;

    if (granted) {
      setState(() => _hasAccess = true);
      await _open(null);
      return;
    }

    // Dozvola je odbijena — jedini put dalje su sistemska podešavanja.
    setState(() => _hasAccess = false);
  }

  /// Otvara folder; `null` vraća na spisak nosača.
  Future<void> _open(String? path) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final entries = path == null
          ? await FileBrowser.roots()
          : await FileBrowser.list(path);
      if (!mounted) return;
      setState(() {
        _path = path;
        _entries = entries;
        _isLoading = false;
      });
    } on FolderNotReadableException {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Ovaj folder ne može da se pročita.';
      });
    }
  }

  /// Folder iznad trenutnog; `null` kad se već gleda spisak nosača.
  String? get _parentPath {
    final path = _path;
    if (path == null) return null;

    final cut = path.lastIndexOf('/');
    if (cut <= 0) return null;

    final parent = path.substring(0, cut);
    // Ispod /storage nema šta da se gleda — vraća se na spisak nosača.
    if (parent == '/storage' || parent.isEmpty) return null;
    return parent;
  }

  void _toggle(BrowserEntry entry) {
    setState(() {
      if (!_selected.remove(entry.path)) _selected.add(entry.path);
    });
  }

  void _useFolder() {
    final tracks = [
      for (final entry in _entries)
        if (!entry.isFolder) FileBrowser.trackFor(entry),
    ];
    Navigator.of(context).pop(tracks);
  }

  void _addSelected() {
    final tracks = [
      for (final entry in _entries)
        if (!entry.isFolder && _selected.contains(entry.path))
          FileBrowser.trackFor(entry),
    ];
    Navigator.of(context).pop(tracks);
  }

  int get _audioCount => _entries.where((e) => !e.isFolder).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_path == null ? 'Izaberi muziku' : _path!.split('/').last),
        leading: IconButton(
          onPressed: () {
            final parent = _parentPath;
            if (_path == null) {
              Navigator.of(context).pop();
            } else {
              _open(parent);
            }
          },
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: _path == null ? 'Odustani' : 'Nazad',
        ),
      ),
      body: _buildBody(),
      bottomNavigationBar: _hasAccess && _path != null ? _actions() : null,
    );
  }

  Widget _buildBody() {
    if (!_hasAccess) return _accessPrompt();

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final error = _errorMessage;
    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                error,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.md),
              FilledButton(
                onPressed: () => _open(_parentPath),
                child: const Text('Nazad'),
              ),
            ],
          ),
        ),
      );
    }

    if (_entries.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.xl),
          child: Text(
            'U ovom folderu nema podfoldera ni numera.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    return Column(
      children: [
        if (_path != null) _breadcrumb(),
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.zero,
            itemCount: _entries.length,
            itemBuilder: (context, index) {
              final entry = _entries[index];
              return _EntryRow(
                entry: entry,
                isSelected: _selected.contains(entry.path),
                onTap: () =>
                    entry.isFolder ? _open(entry.path) : _toggle(entry),
              );
            },
          ),
        ),
      ],
    );
  }

  /// Cela putanja, sitno — da se zna gde se čovek nalazi.
  Widget _breadcrumb() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      color: AppColors.surface,
      child: Text(
        _path!.replaceFirst(FileBrowser.internalStorage, 'Memorija telefona'),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
      ),
    );
  }

  Widget _actions() {
    final selectedCount = _selected.length;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: _audioCount == 0 ? null : _useFolder,
                icon: const Icon(Icons.playlist_add_rounded, size: 20),
                label: Text('Ceo folder ($_audioCount)'),
              ),
            ),
            if (selectedCount > 0) ...[
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _addSelected,
                  icon: const Icon(Icons.check_rounded, size: 20),
                  label: Text('Označene ($selectedCount)'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Ekran koji objašnjava zašto dozvola treba i vodi do nje.
  Widget _accessPrompt() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.folder_off_rounded,
              size: 48,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Aplikacija ne vidi tvoje foldere',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'Od Androida 11 aplikacija sme da čita foldere tek kad joj '
              'odobriš "Pristup svim fajlovima". Dugme ispod otvara to '
              'podešavanje — uključi prekidač i vrati se nazad.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              onPressed: _askForAccess,
              icon: const Icon(Icons.lock_open_rounded, size: 20),
              label: const Text('Odobri pristup'),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextButton(
              onPressed: () async {
                await FileBrowser.openSettings();
              },
              child: const Text('Otvori podešavanja aplikacije'),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextButton(
              onPressed: _start,
              child: const Text('Proveri ponovo'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Jedan red u pregledu: folder ili numera.
class _EntryRow extends StatelessWidget {
  const _EntryRow({
    required this.entry,
    required this.isSelected,
    required this.onTap,
  });

  final BrowserEntry entry;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: isSelected ? AppColors.surfaceAlt : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: kMinTouchTarget,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            children: [
              Icon(
                entry.isFolder
                    ? Icons.folder_rounded
                    : (isSelected
                          ? Icons.check_box_rounded
                          : Icons.audiotrack_rounded),
                size: 20,
                color: entry.isFolder
                    ? AppColors.accent
                    : (isSelected
                          ? AppColors.success
                          : AppColors.textSecondary),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  entry.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (entry.isFolder)
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

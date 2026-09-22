import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../presentation/providers/settings_provider.dart';
import '../../../presentation/providers/workspace_provider.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  Map<String, String> _diagnostics = {};
  bool _isLoadingDiagnostics = false;

  @override
  void initState() {
    super.initState();
    _runDiagnostics();
  }

  Future<void> _runDiagnostics() async {
    setState(() => _isLoadingDiagnostics = true);
    final results = <String, String>{};

    // 1. Git
    try {
      final res = await Process.run('git', ['--version']);
      results['Git'] = res.exitCode == 0 ? res.stdout.toString().trim() : 'Non installé';
    } catch (_) {
      results['Git'] = 'Non installé';
    }

    // 2. Docker
    try {
      final res = await Process.run('docker', ['--version']);
      if (res.exitCode == 0) {
        final psCheck = await Process.run('docker', ['ps']);
        results['Docker'] = psCheck.exitCode == 0 ? '${res.stdout.toString().trim()} (Actif)' : '${res.stdout.toString().trim()} (Démon arrêté)';
      } else {
        results['Docker'] = 'Non installé';
      }
    } catch (_) {
      results['Docker'] = 'Non installé';
    }

    // 3. VS Code
    try {
      final res = await Process.run('code', ['--version']);
      results['VS Code'] = res.exitCode == 0 ? 'Installé (/usr/bin/code)' : 'Non installé';
    } catch (_) {
      results['VS Code'] = 'Non installé';
    }

    // 4. Terminal Emulator
    String detectedTerm = 'Non détecté (fallback sh)';
    for (final term in ['x-terminal-emulator', 'cosmic-term', 'konsole', 'gnome-terminal', 'xterm']) {
      try {
        final res = await Process.run('which', [term]);
        if (res.exitCode == 0) {
          detectedTerm = term;
          break;
        }
      } catch (_) {}
    }
    results['Terminal Emulator'] = detectedTerm;

    // 5. Window Server
    final display = Platform.environment['WAYLAND_DISPLAY'] != null
        ? 'Wayland (${Platform.environment['WAYLAND_DISPLAY']})'
        : (Platform.environment['DISPLAY'] != null ? 'X11 (${Platform.environment['DISPLAY']})' : 'Inconnu');
    results['Serveur d\'affichage'] = display;

    if (mounted) {
      setState(() {
        _diagnostics = results;
        _isLoadingDiagnostics = false;
      });
    }
  }

  void _exportAllWorkspaces() {
    final workspacesAsync = ref.read(workspaceProvider);
    workspacesAsync.whenData((workspaces) {
      final jsonList = workspaces.map((ws) => ref.read(workspaceProvider.notifier).exportToJson(ws.id)).toList();
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Export Global des Workspaces'),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: SelectableText(
                '[\n${jsonList.join(',\n')}\n]',
                style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Fermer')),
          ],
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Paramètres & Diagnostics'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20.0),
        children: [
          // Theme & Appearance
          Card(
            elevation: 0.5,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(
                color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.4),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Apparence',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Thème de l\'interface'),
                    subtitle: const Text('Sélectionnez le mode visuel de l\'application'),
                    trailing: SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'dark', icon: Icon(Icons.dark_mode, size: 16), label: Text('Sombre')),
                        ButtonSegment(value: 'light', icon: Icon(Icons.light_mode, size: 16), label: Text('Clair')),
                        ButtonSegment(value: 'system', icon: Icon(Icons.settings_system_daydream, size: 16), label: Text('Système')),
                      ],
                      selected: {settings.themeMode},
                      onSelectionChanged: (set) => notifier.updateThemeMode(set.first),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Automation & Behavior
          Card(
            elevation: 0.5,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(
                color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.4),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Automatisation & Comportement',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Détection automatique de projet'),
                    subtitle: const Text('Détecte le projet actif du répertoire courant et suggère un workspace'),
                    value: settings.autoDetectProject,
                    onChanged: notifier.updateAutoDetect,
                  ),
                  const Divider(),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Raccourcis clavier globaux'),
                    subtitle: const Text('Permet de switcher de workspace avec Ctrl+1..9'),
                    value: settings.enableGlobalHotkeys,
                    onChanged: notifier.updateGlobalHotkeys,
                  ),
                  const Divider(),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Sauvegarde automatique profil partagé'),
                    subtitle: const Text('Exporte automatiquement chaque snapshot dans shared_profiles'),
                    value: settings.autoSaveToSharedProfile,
                    onChanged: notifier.updateAutoSaveShared,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // System Health & Diagnostics
          Card(
            elevation: 0.5,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(
                color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.4),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Diagnostics Système',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: _isLoadingDiagnostics
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.refresh, size: 20),
                        onPressed: _isLoadingDiagnostics ? null : _runDiagnostics,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ..._diagnostics.entries.map((entry) {
                    final isOk = !entry.value.contains('Non installé') && !entry.value.contains('Inconnu');
                    return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        isOk ? Icons.check_circle_outline : Icons.info_outline,
                        color: isOk ? Colors.green : Colors.amber,
                        size: 20,
                      ),
                      title: Text(entry.key, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      trailing: Text(
                        entry.value,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                          fontFamily: 'monospace',
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Backup & Restore Card
          Card(
            elevation: 0.5,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(
                color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.4),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sauvegarde & Données',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      FilledButton.tonalIcon(
                        onPressed: _exportAllWorkspaces,
                        icon: const Icon(Icons.download, size: 16),
                        label: const Text('Exporter tous les workspaces'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../domain/entities/workspace.dart';
import '../../../../domain/entities/window_snapshot.dart';
import '../../providers/workspace_provider.dart';
import '../../../services/workspace_restoration_service.dart';
import '../../../../platform/factory/platform_factory.dart';

class WorkspaceDetailPage extends ConsumerStatefulWidget {
  final String workspaceId;

  const WorkspaceDetailPage({super.key, required this.workspaceId});

  @override
  ConsumerState<WorkspaceDetailPage> createState() => _WorkspaceDetailPageState();
}

class _WorkspaceDetailPageState extends ConsumerState<WorkspaceDetailPage> {
  bool _restoreGit = true;
  bool _restoreDocker = true;
  bool _restoreProcesses = true;
  bool _restoreTerminals = true;
  bool _restoreBrowsers = true;
  bool _restoreWindows = true;

  bool _isRestoring = false;

  Future<void> _executeRestoration(Workspace workspace) async {
    setState(() => _isRestoring = true);
    try {
      final options = RestoreOptions(
        restoreGit: _restoreGit,
        restoreDocker: _restoreDocker,
        restoreProcesses: _restoreProcesses,
        restoreTerminals: _restoreTerminals,
        restoreBrowsers: _restoreBrowsers,
        restoreWindows: _restoreWindows,
      );

      final report = await ref.read(workspaceProvider.notifier).restore(
            workspace.id,
            options: options,
          );

      if (mounted) {
        _showRestorationReportDialog(report);
      }
    } finally {
      if (mounted) setState(() => _isRestoring = false);
    }
  }

  void _showRestorationReportDialog(RestorationReport report) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(
              report.success ? Icons.check_circle : Icons.warning_amber,
              color: report.success ? Colors.green : Colors.amber,
            ),
            const SizedBox(width: 10),
            Text(report.success ? 'Restauration Réussie' : 'Restauration Terminée'),
          ],
        ),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 10,
                runSpacing: 6,
                children: [
                  Chip(label: Text('${report.restoredTerminals} terminal(ux)')),
                  Chip(label: Text('${report.restoredProcesses} processus')),
                  Chip(label: Text('${report.restoredBrowsers} navigateur(s)')),
                  Chip(label: Text('${report.restoredContainers} docker')),
                ],
              ),
              const SizedBox(height: 14),
              const Text('Journal d\'exécution :', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 6),
              Container(
                constraints: const BoxConstraints(maxHeight: 180),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: report.logs.length,
                  itemBuilder: (context, i) => Text(
                    '• ${report.logs[i]}',
                    style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
        ],
      ),
    );
  }

  Future<void> _openInVsCode(String projectPath) async {
    try {
      final vscode = PlatformFactory.createVscodeManager();
      await vscode.openFolder(projectPath);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ouverture dans VS Code...'), behavior: SnackBarBehavior.floating),
        );
      }
    } catch (_) {}
  }

  Future<void> _openInTerminal(String projectPath) async {
    try {
      final term = PlatformFactory.createTerminalManager();
      await term.openTerminal(workingDirectory: projectPath);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final workspacesAsync = ref.watch(workspaceProvider);

    return workspacesAsync.when(
      data: (workspaces) {
        final workspace = workspaces.firstWhere(
          (w) => w.id == widget.workspaceId,
          orElse: () => throw Exception('Workspace introuvable'),
        );

        return Scaffold(
          appBar: AppBar(
            title: Text(workspace.name),
            actions: [
              IconButton(
                icon: const Icon(Icons.copy),
                tooltip: 'Dupliquer',
                onPressed: () => ref.read(workspaceProvider.notifier).duplicate(workspace.id),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                tooltip: 'Supprimer',
                onPressed: () {
                  ref.read(workspaceProvider.notifier).delete(workspace.id);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(20.0),
            children: [
              // Header Card
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(
                    color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.4),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  workspace.name,
                                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                if (workspace.projectPath != null)
                                  Text(
                                    workspace.projectPath!,
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          FilledButton.icon(
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                            ),
                            onPressed: _isRestoring ? null : () => _executeRestoration(workspace),
                            icon: _isRestoring
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Icon(Icons.restore),
                            label: Text(_isRestoring ? 'Restauration...' : 'Restaurer Tout'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (workspace.projectPath != null) ...[
                        Row(
                          children: [
                            OutlinedButton.icon(
                              onPressed: () => _openInVsCode(workspace.projectPath!),
                              icon: const Icon(Icons.code, size: 16),
                              label: const Text('Ouvrir dans VS Code'),
                            ),
                            const SizedBox(width: 10),
                            OutlinedButton.icon(
                              onPressed: () => _openInTerminal(workspace.projectPath!),
                              icon: const Icon(Icons.terminal, size: 16),
                              label: const Text('Ouvrir dans Terminal'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                      ],
                      // Tags
                      if (workspace.tags.isNotEmpty)
                        Wrap(
                          spacing: 6,
                          children: workspace.tags.map((t) => Chip(label: Text('#$t'))).toList(),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Selective Restoration Options Card
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
                        'Options Sélectives de Restauration',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 10),
                      SwitchListTile(
                        dense: true,
                        title: Text('Terminaux & Répertoires (${workspace.terminals.terminals.length})'),
                        value: _restoreTerminals,
                        onChanged: (v) => setState(() => _restoreTerminals = v),
                      ),
                      SwitchListTile(
                        dense: true,
                        title: Text('Processus applicatifs (${workspace.processes.processes.length})'),
                        value: _restoreProcesses,
                        onChanged: (v) => setState(() => _restoreProcesses = v),
                      ),
                      if (workspace.git != null)
                        SwitchListTile(
                          dense: true,
                          title: Text('Branche Git (${workspace.git!.branch ?? "Actuelle"})'),
                          value: _restoreGit,
                          onChanged: (v) => setState(() => _restoreGit = v),
                        ),
                      if (workspace.docker != null && workspace.docker!.containers.isNotEmpty)
                        SwitchListTile(
                          dense: true,
                          title: Text('Conteneurs Docker (${workspace.docker!.containers.length})'),
                          value: _restoreDocker,
                          onChanged: (v) => setState(() => _restoreDocker = v),
                        ),
                      SwitchListTile(
                        dense: true,
                        title: Text('URLs Navigateur (${workspace.browsers.browsers.length})'),
                        value: _restoreBrowsers,
                        onChanged: (v) => setState(() => _restoreBrowsers = v),
                      ),
                      SwitchListTile(
                        dense: true,
                        title: Text('Disposition des fenêtres (${workspace.windows.windows.length})'),
                        value: _restoreWindows,
                        onChanged: (v) => setState(() => _restoreWindows = v),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Detail Sections
              Text(
                'Éléments enregistrés',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),

              // Terminals
              if (workspace.terminals.terminals.isNotEmpty)
                _buildSection(
                  context,
                  Icons.terminal,
                  'Terminaux (${workspace.terminals.terminals.length})',
                  Colors.teal,
                  workspace.terminals.terminals.map((t) => ListTile(
                        dense: true,
                        title: Text('Shell: ${t.shell}'),
                        subtitle: Text(t.workingDirectory, style: const TextStyle(fontFamily: 'monospace')),
                      )),
                ),

              // Processes
              if (workspace.processes.processes.isNotEmpty)
                _buildSection(
                  context,
                  Icons.memory,
                  'Processus (${workspace.processes.processes.length})',
                  Colors.purple,
                  workspace.processes.processes.map((p) => ListTile(
                        dense: true,
                        title: Text('${p.name} (PID: ${p.pid})'),
                        subtitle: Text(p.commandLine, style: const TextStyle(fontFamily: 'monospace', fontSize: 11)),
                      )),
                ),

              // Windows
              if (workspace.windows.windows.isNotEmpty)
                _buildSection(
                  context,
                  Icons.window_outlined,
                  'Fenêtres (${workspace.windows.windows.length})',
                  Colors.blue,
                  [
                    _buildWindowVisualizer(context, workspace.windows.windows),
                    ...workspace.windows.windows.map((w) => ListTile(
                          dense: true,
                          title: Text(w.title.isEmpty ? w.appName : w.title),
                          subtitle: Text(
                            '${w.appName} • ${w.bounds.width.toInt()}x${w.bounds.height.toInt()} à (${w.bounds.left.toInt()}, ${w.bounds.top.toInt()})',
                          ),
                        )),
                  ],
                ),

              // Docker
              if (workspace.docker != null && workspace.docker!.containers.isNotEmpty)
                _buildSection(
                  context,
                  Icons.grid_view,
                  'Docker (${workspace.docker!.containers.length})',
                  Colors.cyan,
                  workspace.docker!.containers.map((c) => ListTile(
                        dense: true,
                        title: Text(c.name),
                        subtitle: Text('${c.image} • ${c.status}'),
                      )),
                ),

              // Browser URLs
              if (workspace.browsers.browsers.isNotEmpty)
                _buildSection(
                  context,
                  Icons.tab_outlined,
                  'URLs Navigateurs (${workspace.browsers.browsers.length})',
                  Colors.amber,
                  workspace.browsers.browsers.map((b) => ListTile(
                        dense: true,
                        leading: const Icon(Icons.link, size: 16),
                        title: Text(b.url),
                      )),
                ),

              const SizedBox(height: 60),
            ],
          ),
        );
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Erreur: $e'))),
    );
  }

  Widget _buildWindowVisualizer(BuildContext context, List<WindowInfo> windows) {
    if (windows.isEmpty) {
      return const SizedBox.shrink();
    }

    // Simple visualization showing window count and a basic layout representation
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.window, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                '${windows.length} fenêtre${windows.length > 1 ? 's' : ''}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Simple visual representation - just show a grid placeholder
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Center(
                child: Text(
                  'Aperçu des fenêtres',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    IconData icon,
    String title,
    Color color,
    Iterable<Widget> items,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.4),
        ),
      ),
      child: ExpansionTile(
        initiallyExpanded: false,
        leading: Icon(icon, color: color),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        children: items.toList(),
      ),
    );
  }
}

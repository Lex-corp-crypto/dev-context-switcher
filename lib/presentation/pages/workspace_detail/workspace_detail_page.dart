import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../domain/entities/workspace.dart';
import '../../providers/workspace_provider.dart';
import '../../../services/workspace_restoration_service.dart';
import '../../../../platform/factory/platform_factory.dart';
import 'widgets/window_layout_canvas.dart';

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
  bool _runStartupCommands = true;

  bool _isRestoring = false;

  final _taskInputController = TextEditingController();
  final _commandInputController = TextEditingController();
  late final TextEditingController _notesController;
  bool _isNotesInitialized = false;

  @override
  void dispose() {
    _taskInputController.dispose();
    _commandInputController.dispose();
    _notesController.dispose();
    super.dispose();
  }

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
        runStartupCommands: _runStartupCommands,
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
          width: 520,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  Chip(label: Text('${report.restoredTerminals} terminal(ux)')),
                  Chip(label: Text('${report.restoredProcesses} processus')),
                  Chip(label: Text('${report.restoredBrowsers} navigateur(s)')),
                  Chip(label: Text('${report.restoredContainers} docker')),
                  Chip(label: Text('${report.restoredWindows} fenêtres')),
                  if (report.executedStartupCommands > 0)
                    Chip(label: Text('${report.executedStartupCommands} commande(s)')),
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
          FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('Fermer')),
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

  void _saveNotes(Workspace workspace) {
    ref.read(workspaceProvider.notifier).updateNotes(workspace.id, _notesController.text.trim());
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Notes sauvegardées !'), duration: Duration(seconds: 1), behavior: SnackBarBehavior.floating),
    );
  }

  void _addTask(Workspace workspace) {
    final title = _taskInputController.text.trim();
    if (title.isNotEmpty) {
      ref.read(workspaceProvider.notifier).addTask(workspace.id, title);
      _taskInputController.clear();
    }
  }

  void _addCommand(Workspace workspace) {
    final cmd = _commandInputController.text.trim();
    if (cmd.isNotEmpty) {
      final current = [...workspace.startupCommands, cmd];
      ref.read(workspaceProvider.notifier).updateStartupCommands(workspace.id, current);
      _commandInputController.clear();
    }
  }

  void _removeCommand(Workspace workspace, int index) {
    final current = [...workspace.startupCommands]..removeAt(index);
    ref.read(workspaceProvider.notifier).updateStartupCommands(workspace.id, current);
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

        if (!_isNotesInitialized) {
          _notesController = TextEditingController(text: workspace.notes ?? '');
          _isNotesInitialized = true;
        }

        final completedTasks = workspace.tasks.where((t) => t.isCompleted).length;
        final totalTasks = workspace.tasks.length;
        final progress = totalTasks > 0 ? completedTasks / totalTasks : 0.0;

        return Scaffold(
          appBar: AppBar(
            title: Row(
              children: [
                if (workspace.colorHex != null) ...[
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Color(int.parse(workspace.colorHex!, radix: 16)),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Text(workspace.name),
              ],
            ),
            actions: [
              IconButton(
                icon: Icon(
                  workspace.isFavorite ? Icons.star : Icons.star_border,
                  color: workspace.isFavorite ? Colors.amber : null,
                ),
                tooltip: workspace.isFavorite ? 'Retirer des favoris' : 'Marquer comme favori',
                onPressed: () => ref.read(workspaceProvider.notifier).toggleFavorite(workspace.id),
              ),
              IconButton(
                icon: const Icon(Icons.copy_outlined),
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
                elevation: 1.5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
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
                                Row(
                                  children: [
                                    Text(
                                      workspace.name,
                                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    if (workspace.isFavorite) ...[
                                      const SizedBox(width: 8),
                                      const Icon(Icons.star, color: Colors.amber, size: 22),
                                    ],
                                  ],
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
                              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
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
                      const SizedBox(height: 14),

                      // Quick Launchers
                      if (workspace.projectPath != null && workspace.projectPath!.isNotEmpty) ...[
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

                      // Statistics chips
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.repeat, size: 13, color: Colors.indigoAccent),
                                const SizedBox(width: 4),
                                Text(
                                  '${workspace.restoreCount} restaurations',
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                          if (workspace.lastRestoredAt != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.history, size: 13, color: Colors.green),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Dernière: ${_formatDate(workspace.lastRestoredAt!)}',
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.calendar_today, size: 13, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text(
                                  'Créé: ${_formatDate(workspace.createdAt)}',
                                  style: const TextStyle(fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      if (workspace.tags.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 6,
                          children: workspace.tags.map((t) => Chip(label: Text('#$t'))).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Interactive Tasks & Objectives Card
              Card(
                elevation: 1,
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
                          Row(
                            children: [
                              const Icon(Icons.checklist_rtl, color: Colors.green, size: 22),
                              const SizedBox(width: 8),
                              Text(
                                'Objectifs & Tâches ($completedTasks/$totalTasks)',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ],
                          ),
                          if (totalTasks > 0)
                            Text(
                              '${(progress * 100).toInt()}%',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                            ),
                        ],
                      ),
                      if (totalTasks > 0) ...[
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 6,
                            backgroundColor: Colors.grey.withOpacity(0.2),
                            color: Colors.green,
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),

                      // Task List
                      if (workspace.tasks.isNotEmpty)
                        ...workspace.tasks.map((task) {
                          return ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            leading: Checkbox(
                              value: task.isCompleted,
                              activeColor: Colors.green,
                              onChanged: (_) {
                                ref.read(workspaceProvider.notifier).toggleTask(workspace.id, task.id);
                              },
                            ),
                            title: Text(
                              task.title,
                              style: TextStyle(
                                decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                                color: task.isCompleted
                                    ? Theme.of(context).colorScheme.onSurface.withOpacity(0.5)
                                    : null,
                                fontWeight: task.isCompleted ? FontWeight.normal : FontWeight.w500,
                              ),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.close, size: 16, color: Colors.grey),
                              tooltip: 'Supprimer',
                              onPressed: () {
                                ref.read(workspaceProvider.notifier).deleteTask(workspace.id, task.id);
                              },
                            ),
                          );
                        }),

                      // Add task field
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _taskInputController,
                              decoration: const InputDecoration(
                                hintText: 'Ajouter une tâche ou un objectif...',
                                isDense: true,
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              ),
                              onSubmitted: (_) => _addTask(workspace),
                            ),
                          ),
                          const SizedBox(width: 8),
                          FilledButton.tonal(
                            onPressed: () => _addTask(workspace),
                            child: const Text('Ajouter'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Interactive Notes & Scratchpad
              Card(
                elevation: 1,
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
                          Row(
                            children: [
                              const Icon(Icons.note_alt_outlined, color: Colors.amber, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Bloc-notes du Contexte',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ],
                          ),
                          FilledButton.tonalIcon(
                            onPressed: () => _saveNotes(workspace),
                            icon: const Icon(Icons.save, size: 16),
                            label: const Text('Sauvegarder'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _notesController,
                        maxLines: 5,
                        decoration: const InputDecoration(
                          hintText: 'Notez vos rappels, credentials locaux, liens de documentation ou prochaines étapes...',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Custom Startup Commands & Environment Variables
              Card(
                elevation: 1,
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
                        children: [
                          const Icon(Icons.play_circle_outline, color: Colors.deepPurpleAccent, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Commandes de Démarrage Personnalisées',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Exécutées automatiquement dans le répertoire du projet lors de la restauration',
                        style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                      ),
                      const SizedBox(height: 10),

                      if (workspace.startupCommands.isNotEmpty)
                        ...workspace.startupCommands.asMap().entries.map((entry) {
                          return ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.terminal, size: 16, color: Colors.deepPurpleAccent),
                            title: Text(
                              entry.value,
                              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.close, size: 16, color: Colors.grey),
                              onPressed: () => _removeCommand(workspace, entry.key),
                            ),
                          );
                        }),

                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _commandInputController,
                              decoration: const InputDecoration(
                                hintText: 'ex: npm run dev, docker compose up -d, cargo watch',
                                isDense: true,
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              ),
                              onSubmitted: (_) => _addCommand(workspace),
                            ),
                          ),
                          const SizedBox(width: 8),
                          FilledButton.tonal(
                            onPressed: () => _addCommand(workspace),
                            child: const Text('Ajouter'),
                          ),
                        ],
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
                      if (workspace.startupCommands.isNotEmpty)
                        SwitchListTile(
                          dense: true,
                          title: Text('Commandes de démarrage (${workspace.startupCommands.length})'),
                          value: _runStartupCommands,
                          onChanged: (v) => setState(() => _runStartupCommands = v),
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

              // Windows Visualizer
              if (workspace.windows.windows.isNotEmpty)
                _buildSection(
                  context,
                  Icons.window_outlined,
                  'Topologie des Fenêtres (${workspace.windows.windows.length})',
                  Colors.blue,
                  [
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: WindowLayoutCanvas(windows: workspace.windows.windows),
                    ),
                    ...workspace.windows.windows.map((w) => ListTile(
                          dense: true,
                          title: Text(w.title.isEmpty ? w.appName : w.title),
                          subtitle: Text(
                            '${w.appName} • ${w.bounds.width.toInt()}x${w.bounds.height.toInt()} à (${w.bounds.left.toInt()}, ${w.bounds.top.toInt()})',
                          ),
                        )),
                  ],
                ),

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

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'à l\'instant';
    if (diff.inMinutes < 60) return 'il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'il y a ${diff.inHours}h';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../domain/entities/window_snapshot.dart';
import '../../../../domain/entities/process_snapshot.dart';
import '../../../../domain/entities/terminal_snapshot.dart';
import '../../../../domain/entities/browser_snapshot.dart';
import '../../../../domain/entities/docker_snapshot.dart';
import '../../../../domain/entities/git_snapshot.dart';
import '../../../../domain/entities/workspace_task.dart';
import '../../providers/workspace_provider.dart';
import 'widgets/window_picker.dart';
import 'widgets/process_picker.dart';
import 'widgets/terminal_picker.dart';
import 'widgets/browser_picker.dart';

class CapturePage extends ConsumerStatefulWidget {
  final String? initialProjectPath;
  final String? initialName;

  const CapturePage({
    super.key,
    this.initialProjectPath,
    this.initialName,
  });

  @override
  ConsumerState<CapturePage> createState() => _CapturePageState();
}

class _CapturePageState extends ConsumerState<CapturePage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _pathController;
  final _tagController = TextEditingController();
  final _notesController = TextEditingController();
  final _taskInputController = TextEditingController();
  final _startupCommandController = TextEditingController();

  final List<String> _tags = [];
  final List<String> _customUrls = [];
  final List<String> _initialTasks = [];
  final List<String> _startupCommands = [];

  bool _isFavorite = false;
  String _selectedColorHex = 'FF2196F3';

  bool _isLoading = false;
  bool _isSaving = false;

  // Inspected system items
  List<WindowInfo> _windows = [];
  List<ProcessInfo> _processes = [];
  List<TerminalInfo> _terminals = [];
  List<ContainerInfo> _containers = [];
  Map<String, dynamic>? _gitState;

  // Selection states
  final Set<String> _selectedWindowIds = {};
  final Set<int> _selectedProcessPids = {};
  final Set<String> _selectedTerminalIds = {};
  final Set<String> _selectedContainerIds = {};

  static const List<Map<String, dynamic>> _colorPresets = [
    {'name': 'Bleu', 'hex': 'FF2196F3', 'color': Colors.blue},
    {'name': 'Vert', 'hex': 'FF4CAF50', 'color': Colors.green},
    {'name': 'Violet', 'hex': 'FF9C27B0', 'color': Colors.purple},
    {'name': 'Ambre', 'hex': 'FFFFC107', 'color': Colors.amber},
    {'name': 'Orange', 'hex': 'FFFF9800', 'color': Colors.orange},
    {'name': 'Cyan', 'hex': 'FF00BCD4', 'color': Colors.cyan},
    {'name': 'Rose', 'hex': 'FFE91E63', 'color': Colors.pink},
    {'name': 'Teal', 'hex': 'FF009688', 'color': Colors.teal},
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName ?? 'Mon Workspace');
    _pathController = TextEditingController(text: widget.initialProjectPath ?? '');
    _inspectSystem();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _pathController.dispose();
    _tagController.dispose();
    _notesController.dispose();
    _taskInputController.dispose();
    _startupCommandController.dispose();
    super.dispose();
  }

  Future<void> _inspectSystem() async {
    setState(() => _isLoading = true);
    try {
      final captureService = ref.read(captureServiceProvider);
      final inspect = await captureService.inspectCurrentState(
        _pathController.text.trim().isNotEmpty ? _pathController.text.trim() : null,
      );

      setState(() {
        _windows = (inspect['windows'] as List<dynamic>?)?.cast<WindowInfo>() ?? [];
        _processes = (inspect['processes'] as List<dynamic>?)?.cast<ProcessInfo>() ?? [];
        _terminals = (inspect['terminals'] as List<dynamic>?)?.cast<TerminalInfo>() ?? [];
        _containers = (inspect['containers'] as List<dynamic>?)?.cast<ContainerInfo>() ?? [];
        _gitState = inspect['gitState'] as Map<String, dynamic>?;

        // Auto-select all by default
        _selectedWindowIds.addAll(_windows.map((w) => w.id));
        _selectedProcessPids.addAll(_processes.map((p) => p.pid));
        _selectedTerminalIds.addAll(_terminals.map((t) => t.id));
        _selectedContainerIds.addAll(_containers.map((c) => c.id));
      });
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _addTag() {
    final text = _tagController.text.trim();
    if (text.isNotEmpty && !_tags.contains(text)) {
      setState(() {
        _tags.add(text);
        _tagController.clear();
      });
    }
  }

  void _removeTag(String tag) {
    setState(() => _tags.remove(tag));
  }

  void _addTask() {
    final text = _taskInputController.text.trim();
    if (text.isNotEmpty && !_initialTasks.contains(text)) {
      setState(() {
        _initialTasks.add(text);
        _taskInputController.clear();
      });
    }
  }

  void _addStartupCommand() {
    final text = _startupCommandController.text.trim();
    if (text.isNotEmpty && !_startupCommands.contains(text)) {
      setState(() {
        _startupCommands.add(text);
        _startupCommandController.clear();
      });
    }
  }

  Future<void> _saveWorkspace() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final selectedWindows = _windows.where((w) => _selectedWindowIds.contains(w.id)).toList();
      final selectedProcesses = _processes.where((p) => _selectedProcessPids.contains(p.pid)).toList();
      final selectedTerminals = _terminals.where((t) => _selectedTerminalIds.contains(t.id)).toList();
      final selectedContainers = _containers.where((c) => _selectedContainerIds.contains(c.id)).toList();

      final browsers = _customUrls
          .map((url) => BrowserInfo(id: url, url: url, title: url, browserName: 'default'))
          .toList();

      GitSnapshot? gitSnapshot;
      if (_gitState != null) {
        gitSnapshot = GitSnapshot(
          branch: _gitState!['branch'],
          commitHash: _gitState!['commitHash'],
          hasUncommittedChanges: _gitState!['hasUncommittedChanges'] ?? false,
          recentBranches: _gitState!['recentBranches'] ?? [],
        );
      }

      final tasks = _initialTasks.map((t) {
        return WorkspaceTask(
          id: '${DateTime.now().millisecondsSinceEpoch}_${t.hashCode}',
          title: t,
          isCompleted: false,
        );
      }).toList();

      await ref.read(workspaceProvider.notifier).capture(
        name: _nameController.text.trim(),
        projectPath: _pathController.text.trim().isNotEmpty ? _pathController.text.trim() : null,
        tags: _tags,
        selectedWindows: selectedWindows,
        selectedProcesses: selectedProcesses,
        selectedTerminals: selectedTerminals,
        selectedBrowsers: browsers,
        selectedContainers: selectedContainers,
        gitSnapshot: gitSnapshot,
        tasks: tasks,
        notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
        isFavorite: _isFavorite,
        colorHex: _selectedColorHex,
        startupCommands: _startupCommands,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Workspace capturé et enregistré avec succès !'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Capture Studio'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Ré-inspecter le système',
            onPressed: _isLoading ? null : _inspectSystem,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Inspection de l\'environnement en cours...'),
                ],
              ),
            )
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(20.0),
                children: [
                  // Workspace Identity Card
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
                              Text(
                                'Informations Générales',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              Row(
                                children: [
                                  const Text('Favori', style: TextStyle(fontSize: 13)),
                                  IconButton(
                                    icon: Icon(
                                      _isFavorite ? Icons.star : Icons.star_border,
                                      color: _isFavorite ? Colors.amber : Colors.grey,
                                    ),
                                    onPressed: () => setState(() => _isFavorite = !_isFavorite),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              labelText: 'Nom du Workspace *',
                              prefixIcon: Icon(Icons.label_outline),
                              border: OutlineInputBorder(),
                            ),
                            validator: (val) =>
                                (val == null || val.trim().isEmpty) ? 'Veuillez saisir un nom' : null,
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _pathController,
                            decoration: InputDecoration(
                              labelText: 'Répertoire du projet',
                              prefixIcon: const Icon(Icons.folder_open),
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.refresh),
                                tooltip: 'Re-détecter git',
                                onPressed: _inspectSystem,
                              ),
                              border: const OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Color selector
                          const Text('Couleur d\'accent :', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 8,
                            children: _colorPresets.map((preset) {
                              final isSelected = _selectedColorHex == preset['hex'];
                              return GestureDetector(
                                onTap: () => setState(() => _selectedColorHex = preset['hex']),
                                child: Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: preset['color'] as Color,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isSelected ? Colors.white : Colors.transparent,
                                      width: 2.5,
                                    ),
                                    boxShadow: [
                                      if (isSelected)
                                        BoxShadow(
                                          color: (preset['color'] as Color).withOpacity(0.5),
                                          blurRadius: 6,
                                          spreadRadius: 1,
                                        ),
                                    ],
                                  ),
                                  child: isSelected
                                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                                      : null,
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 14),

                          // Tags input
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _tagController,
                                  decoration: const InputDecoration(
                                    labelText: 'Ajouter un tag',
                                    prefixIcon: Icon(Icons.tag),
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                  ),
                                  onSubmitted: (_) => _addTag(),
                                ),
                              ),
                              const SizedBox(width: 8),
                              FilledButton.tonal(
                                onPressed: _addTag,
                                child: const Text('Ajouter'),
                              ),
                            ],
                          ),
                          if (_tags.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 6,
                              children: _tags.map((tag) {
                                return Chip(
                                  label: Text(tag),
                                  deleteIcon: const Icon(Icons.close, size: 14),
                                  onDeleted: () => _removeTag(tag),
                                );
                              }).toList(),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Initial Tasks & Scratchpad Card
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
                          Text(
                            'Objectifs & Bloc-notes Préalables',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _taskInputController,
                                  decoration: const InputDecoration(
                                    labelText: 'Ajouter un objectif ou une tâche',
                                    prefixIcon: Icon(Icons.checklist),
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                  ),
                                  onSubmitted: (_) => _addTask(),
                                ),
                              ),
                              const SizedBox(width: 8),
                              FilledButton.tonal(
                                onPressed: _addTask,
                                child: const Text('Ajouter'),
                              ),
                            ],
                          ),
                          if (_initialTasks.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            ..._initialTasks.map((t) => ListTile(
                                  dense: true,
                                  contentPadding: EdgeInsets.zero,
                                  leading: const Icon(Icons.circle_outlined, size: 16),
                                  title: Text(t),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.close, size: 16),
                                    onPressed: () => setState(() => _initialTasks.remove(t)),
                                  ),
                                )),
                          ],
                          const SizedBox(height: 14),
                          TextField(
                            controller: _notesController,
                            maxLines: 3,
                            decoration: const InputDecoration(
                              labelText: 'Notes préliminaires (optionnel)',
                              hintText: 'Credentials, commandes utiles, contexte de travail...',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 14),
                          // Startup commands
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _startupCommandController,
                                  decoration: const InputDecoration(
                                    labelText: 'Commande de démarrage personnalisée',
                                    hintText: 'ex: npm run dev, docker compose up -d',
                                    prefixIcon: Icon(Icons.play_arrow_outlined),
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                  ),
                                  onSubmitted: (_) => _addStartupCommand(),
                                ),
                              ),
                              const SizedBox(width: 8),
                              FilledButton.tonal(
                                onPressed: _addStartupCommand,
                                child: const Text('Ajouter'),
                              ),
                            ],
                          ),
                          if (_startupCommands.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            ..._startupCommands.map((c) => ListTile(
                                  dense: true,
                                  contentPadding: EdgeInsets.zero,
                                  leading: const Icon(Icons.terminal, size: 16, color: Colors.deepPurpleAccent),
                                  title: Text(c, style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.close, size: 16),
                                    onPressed: () => setState(() => _startupCommands.remove(c)),
                                  ),
                                )),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Section Title & Batch controls
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Composants détectés à capturer',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Row(
                        children: [
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _selectedWindowIds.addAll(_windows.map((w) => w.id));
                                _selectedProcessPids.addAll(_processes.map((p) => p.pid));
                                _selectedTerminalIds.addAll(_terminals.map((t) => t.id));
                                _selectedContainerIds.addAll(_containers.map((c) => c.id));
                              });
                            },
                            child: const Text('Tout cocher'),
                          ),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _selectedWindowIds.clear();
                                _selectedProcessPids.clear();
                                _selectedTerminalIds.clear();
                                _selectedContainerIds.clear();
                              });
                            },
                            child: const Text('Tout décocher'),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Git Card (if detected)
                  if (_gitState != null) ...[
                    Card(
                      elevation: 0.5,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5),
                        ),
                      ),
                      child: ListTile(
                        leading: const Icon(Icons.fork_right, color: Colors.orange),
                        title: Text('Dépôt Git: ${_gitState!['branch']}'),
                        subtitle: Text(
                          _gitState!['hasUncommittedChanges'] == true
                              ? 'Modifications non commitées détectées'
                              : 'Branche propre (aucun changement non commité)',
                        ),
                        trailing: _gitState!['commitHash'] != null
                            ? Chip(label: Text('${_gitState!['commitHash']}'))
                            : null,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],

                  // Docker Containers Picker (if containers found)
                  if (_containers.isNotEmpty) ...[
                    Card(
                      elevation: 0.5,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5),
                        ),
                      ),
                      child: ExpansionTile(
                        initiallyExpanded: true,
                        leading: const Icon(Icons.grid_view, color: Colors.cyan),
                        title: Text('Conteneurs Docker (${_selectedContainerIds.length}/${_containers.length})'),
                        children: _containers.map((c) {
                          final isSelected = _selectedContainerIds.contains(c.id);
                          return CheckboxListTile(
                            dense: true,
                            value: isSelected,
                            onChanged: (val) {
                              setState(() {
                                if (val == true) {
                                  _selectedContainerIds.add(c.id);
                                } else {
                                  _selectedContainerIds.remove(c.id);
                                }
                              });
                            },
                            title: Text(c.name),
                            subtitle: Text('${c.image} • ${c.status}'),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],

                  // Windows Picker
                  WindowPicker(
                    windows: _windows,
                    selectedIds: _selectedWindowIds,
                    onToggle: (id, sel) {
                      setState(() {
                        if (sel) {
                          _selectedWindowIds.add(id);
                        } else {
                          _selectedWindowIds.remove(id);
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 8),

                  // Process Picker
                  ProcessPicker(
                    processes: _processes,
                    selectedPids: _selectedProcessPids,
                    onToggle: (pid, sel) {
                      setState(() {
                        if (sel) {
                          _selectedProcessPids.add(pid);
                        } else {
                          _selectedProcessPids.remove(pid);
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 8),

                  // Terminal Picker
                  TerminalPicker(
                    terminals: _terminals,
                    selectedIds: _selectedTerminalIds,
                    onToggle: (id, sel) {
                      setState(() {
                        if (sel) {
                          _selectedTerminalIds.add(id);
                        } else {
                          _selectedTerminalIds.remove(id);
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 8),

                  // Browser URLs
                  BrowserPicker(
                    browsers: const [],
                    customUrls: _customUrls,
                    onAddUrl: (url) => setState(() => _customUrls.add(url)),
                    onRemoveUrl: (i) => setState(() => _customUrls.removeAt(i)),
                  ),
                  const SizedBox(height: 24),

                  // Submit Button
                  SizedBox(
                    height: 50,
                    child: FilledButton.icon(
                      onPressed: _isSaving ? null : _saveWorkspace,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.check_circle_outline),
                      label: Text(
                        _isSaving ? 'Enregistrement en cours...' : 'Capturer et Enregistrer le Workspace',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/entities/workspace.dart';
import '../../providers/workspace_provider.dart';
import '../../providers/settings_provider.dart';
import 'widgets/workspace_list.dart';
import 'widgets/quick_restore_bar.dart';
import 'widgets/detected_project_banner.dart';
import '../capture/capture_page.dart';
import '../templates/templates_page.dart';
import '../settings/settings_page.dart';
import '../workspace_detail/workspace_detail_page.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  int _currentNavIndex = 0;
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openCapture({String? path, String? name}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CapturePage(
          initialProjectPath: path,
          initialName: name,
        ),
      ),
    );
  }

  void _openDetail(Workspace ws) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WorkspaceDetailPage(workspaceId: ws.id),
      ),
    );
  }

  void _openCommandPalette() {
    showDialog(
      context: context,
      builder: (ctx) {
        String query = '';
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final allWorkspaces = ref.read(workspaceProvider).value ?? [];
            final matches = allWorkspaces.where((w) {
              return query.isEmpty ||
                  w.name.toLowerCase().contains(query.toLowerCase()) ||
                  (w.projectPath?.toLowerCase().contains(query.toLowerCase()) ?? false);
            }).toList();

            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Container(
                width: 580,
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      autofocus: true,
                      decoration: const InputDecoration(
                        hintText: 'Tapez une commande ou un workspace...',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      onChanged: (v) => setDialogState(() => query = v),
                    ),
                    const SizedBox(height: 12),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 320),
                      child: ListView(
                        shrinkWrap: true,
                        children: [
                          if (matches.isNotEmpty) ...[
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              child: Text('Workspaces', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
                            ),
                            ...matches.map((ws) => ListTile(
                              dense: true,
                              leading: const Icon(Icons.devices_other, size: 20),
                              title: Text(ws.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                              subtitle: ws.projectPath != null ? Text(ws.projectPath!, maxLines: 1, overflow: TextOverflow.ellipsis) : null,
                              trailing: FilledButton.tonal(
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  ref.read(workspaceProvider.notifier).restore(ws.id);
                                },
                                child: const Text('Restaurer'),
                              ),
                              onTap: () {
                                Navigator.pop(ctx);
                                _openDetail(ws);
                              },
                            )),
                            const Divider(),
                          ],
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            child: Text('Actions Rapides', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
                          ),
                          ListTile(
                            dense: true,
                            leading: const Icon(Icons.camera_alt, color: Colors.indigoAccent),
                            title: const Text('Capturer un nouveau snapshot'),
                            onTap: () {
                              Navigator.pop(ctx);
                              _openCapture();
                            },
                          ),
                          ListTile(
                            dense: true,
                            leading: const Icon(Icons.widgets, color: Colors.green),
                            title: const Text('Parcourir les modèles de workspaces'),
                            onTap: () {
                              Navigator.pop(ctx);
                              setState(() => _currentNavIndex = 2);
                            },
                          ),
                          ListTile(
                            dense: true,
                            leading: const Icon(Icons.settings, color: Colors.amber),
                            title: const Text('Paramètres et diagnostics système'),
                            onTap: () {
                              Navigator.pop(ctx);
                              setState(() => _currentNavIndex = 3);
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _handleKey(RawKeyEvent event) {
    if (event is! RawKeyDownEvent) return;

    final settings = ref.read(settingsProvider);
    if (!settings.enableGlobalHotkeys) return;

    final isCtrl = event.isControlPressed || event.isMetaPressed;
    if (isCtrl) {
      // Ctrl+K -> Command Palette
      if (event.logicalKey == LogicalKeyboardKey.keyK) {
        _openCommandPalette();
        return;
      }
      // Ctrl+N -> Capture
      if (event.logicalKey == LogicalKeyboardKey.keyN) {
        _openCapture();
        return;
      }
      // Ctrl+1..9 -> Quick restore
      final digitKeys = [
        LogicalKeyboardKey.digit1,
        LogicalKeyboardKey.digit2,
        LogicalKeyboardKey.digit3,
        LogicalKeyboardKey.digit4,
        LogicalKeyboardKey.digit5,
        LogicalKeyboardKey.digit6,
        LogicalKeyboardKey.digit7,
        LogicalKeyboardKey.digit8,
        LogicalKeyboardKey.digit9,
      ];
      for (int i = 0; i < digitKeys.length; i++) {
        if (event.logicalKey == digitKeys[i]) {
          final workspacesAsync = ref.read(workspaceProvider);
          workspacesAsync.whenData((list) {
            if (i < list.length) {
              ref.read(workspaceProvider.notifier).restore(list[i].id);
            }
          });
          break;
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final workspacesAsync = ref.watch(workspaceProvider);
    final filteredWorkspaces = ref.watch(filteredWorkspacesProvider);
    final allTags = ref.watch(allTagsProvider);
    final selectedTag = ref.watch(selectedTagFilterProvider);

    return RawKeyboardListener(
      focusNode: FocusNode()..requestFocus(),
      onKey: _handleKey,
      child: Scaffold(
        body: Row(
          children: [
            // Modern Desktop Navigation Rail
            NavigationRail(
              selectedIndex: _currentNavIndex,
              onDestinationSelected: (idx) => setState(() => _currentNavIndex = idx),
              labelType: NavigationRailLabelType.all,
              leading: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.primary,
                        Theme.of(context).colorScheme.secondary,
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.swap_calls, color: Colors.white, size: 24),
                ),
              ),
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.dashboard_outlined),
                  selectedIcon: Icon(Icons.dashboard),
                  label: Text('Workspaces'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.camera_alt_outlined),
                  selectedIcon: Icon(Icons.camera_alt),
                  label: Text('Capturer'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.widgets_outlined),
                  selectedIcon: Icon(Icons.widgets),
                  label: Text('Modèles'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.settings_outlined),
                  selectedIcon: Icon(Icons.settings),
                  label: Text('Paramètres'),
                ),
              ],
            ),
            const VerticalDivider(thickness: 1, width: 1),

            // Body content depending on index
            Expanded(
              child: _buildBody(
                workspacesAsync,
                filteredWorkspaces,
                allTags,
                selectedTag,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(
    AsyncValue<List<Workspace>> workspacesAsync,
    List<Workspace> filteredWorkspaces,
    List<String> allTags,
    String? selectedTag,
  ) {
    switch (_currentNavIndex) {
      case 1:
        return const CapturePage();
      case 2:
        return const TemplatesPage();
      case 3:
        return const SettingsPage();
      case 0:
      default:
        return _buildWorkspacesDashboard(
          workspacesAsync,
          filteredWorkspaces,
          allTags,
          selectedTag,
        );
    }
  }

  Widget _buildWorkspacesDashboard(
    AsyncValue<List<Workspace>> workspacesAsync,
    List<Workspace> filteredWorkspaces,
    List<String> allTags,
    String? selectedTag,
  ) {
    return Column(
      children: [
        // Top App Bar / Search Header
        Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.3),
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dev Context Switcher',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Text(
                      'Restauration instantanée de vos fenêtres, terminaux et processus',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Search field
              SizedBox(
                width: 240,
                height: 40,
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Rechercher (Ctrl+F)...',
                    prefixIcon: const Icon(Icons.search, size: 18),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 16),
                            onPressed: () {
                              _searchController.clear();
                              ref.read(searchQueryProvider.notifier).state = '';
                            },
                          )
                        : null,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onChanged: (v) => ref.read(searchQueryProvider.notifier).state = v,
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                tooltip: 'Palette de commandes (Ctrl+K)',
                icon: const Icon(Icons.terminal, size: 18),
                onPressed: _openCommandPalette,
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: () => _openCapture(),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Nouveau Snapshot'),
              ),
            ],
          ),
        ),

        // Auto-detected project banner
        DetectedProjectBanner(
          onUseProject: (path, name) => _openCapture(path: path, name: name),
        ),

        // Quick restore hotkeys bar
        workspacesAsync.maybeWhen(
          data: (list) => QuickRestoreBar(workspaces: list),
          orElse: () => const SizedBox.shrink(),
        ),

        // Tags bar if any tags exist
        if (allTags.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ChoiceChip(
                    label: const Text('Tous'),
                    selected: selectedTag == null,
                    onSelected: (_) => ref.read(selectedTagFilterProvider.notifier).state = null,
                  ),
                  const SizedBox(width: 6),
                  ...allTags.map((tag) {
                    final isSel = selectedTag == tag;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6.0),
                      child: ChoiceChip(
                        label: Text('#$tag'),
                        selected: isSel,
                        onSelected: (val) {
                          ref.read(selectedTagFilterProvider.notifier).state = val ? tag : null;
                        },
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),

        // Workspaces list
        Expanded(
          child: workspacesAsync.when(
            data: (_) => WorkspaceList(
              workspaces: filteredWorkspaces,
              onOpenDetail: _openDetail,
              onCreateWorkspace: () => _openCapture(),
            ),
            loading: () => const Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 12),
                    Text('Chargement des contextes...'),
                  ],
                ),
              ),
            ),
            error: (e, _) => Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 40),
                    const SizedBox(height: 10),
                    Text('Erreur de chargement: $e'),
                    const SizedBox(height: 10),
                    FilledButton(
                      onPressed: () => ref.read(workspaceProvider.notifier).loadWorkspaces(),
                      child: const Text('Réessayer'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

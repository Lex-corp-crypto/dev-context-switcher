import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../domain/entities/workspace.dart';
import '../../../providers/workspace_provider.dart';

class WorkspaceList extends ConsumerStatefulWidget {
  final List<Workspace> workspaces;
  final void Function(Workspace workspace)? onOpenDetail;
  final void Function()? onCreateWorkspace;

  const WorkspaceList({
    super.key,
    required this.workspaces,
    this.onOpenDetail,
    this.onCreateWorkspace,
  });

  @override
  ConsumerState<WorkspaceList> createState() => _WorkspaceListState();
}

class _WorkspaceListState extends ConsumerState<WorkspaceList> {
  String? _restoringId;

  Future<void> _restoreWorkspace(Workspace ws) async {
    setState(() => _restoringId = ws.id);
    try {
      final report = await ref.read(workspaceProvider.notifier).restore(ws.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Row(
              children: [
                Icon(
                  report.success ? Icons.check_circle : Icons.warning_amber,
                  color: report.success ? Colors.greenAccent : Colors.amberAccent,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    report.success
                        ? 'Workspace "${ws.name}" restauré !'
                        : 'Restauration partielle de "${ws.name}"',
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _restoringId = null);
    }
  }

  void _showDeleteDialog(Workspace ws) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer le workspace'),
        content: Text('Êtes-vous sûr de vouloir supprimer "${ws.name}" ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              ref.read(workspaceProvider.notifier).delete(ws.id);
              Navigator.pop(ctx);
            },
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  void _showExportDialog(Workspace ws) {
    final jsonStr = ref.read(workspaceProvider.notifier).exportToJson(ws.id);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Export JSON - ${ws.name}'),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: SelectableText(
              jsonStr,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Fermer')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.workspaces.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.workspaces_outline,
                size: 64,
                color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'Aucun workspace trouvé',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Capturez votre environnement de travail actuel en un clic pour pouvoir y revenir instantanément.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: widget.onCreateWorkspace,
                icon: const Icon(Icons.add),
                label: const Text('Créer un Workspace'),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
      itemCount: widget.workspaces.length,
      itemBuilder: (context, index) {
        final ws = widget.workspaces[index];
        final isRestoring = _restoringId == ws.id;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 1.5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(
              color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.4),
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => widget.onOpenDetail?.call(ws),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title row & menu
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.devices_other,
                          color: Theme.of(context).colorScheme.primary,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ws.name,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (ws.projectPath != null && ws.projectPath!.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Icon(Icons.folder_outlined,
                                      size: 13,
                                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      ws.projectPath!,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      // Restore button
                      FilledButton.icon(
                        onPressed: isRestoring ? null : () => _restoreWorkspace(ws),
                        icon: isRestoring
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.restore, size: 16),
                        label: Text(isRestoring ? 'En cours...' : 'Restaurer'),
                      ),
                      const SizedBox(width: 4),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert),
                        onSelected: (action) {
                          if (action == 'detail') widget.onOpenDetail?.call(ws);
                          if (action == 'duplicate') ref.read(workspaceProvider.notifier).duplicate(ws.id);
                          if (action == 'export') _showExportDialog(ws);
                          if (action == 'delete') _showDeleteDialog(ws);
                        },
                        itemBuilder: (ctx) => [
                          const PopupMenuItem(
                            value: 'detail',
                            child: Row(
                              children: [
                                Icon(Icons.visibility_outlined, size: 18),
                                SizedBox(width: 10),
                                Text('Voir les détails'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'duplicate',
                            child: Row(
                              children: [
                                Icon(Icons.copy_outlined, size: 18),
                                SizedBox(width: 10),
                                Text('Dupliquer'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'export',
                            child: Row(
                              children: [
                                Icon(Icons.download_outlined, size: 18),
                                SizedBox(width: 10),
                                Text('Exporter (JSON)'),
                              ],
                            ),
                          ),
                          const PopupMenuDivider(),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete_outline, size: 18, color: Colors.red),
                                SizedBox(width: 10),
                                Text('Supprimer', style: TextStyle(color: Colors.red)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Snapshot badges
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _buildIndicatorChip(
                        context,
                        Icons.window_outlined,
                        '${ws.windows.windows.length} fenêtres',
                        Colors.blue,
                      ),
                      _buildIndicatorChip(
                        context,
                        Icons.terminal_outlined,
                        '${ws.terminals.terminals.length} terminaux',
                        Colors.teal,
                      ),
                      _buildIndicatorChip(
                        context,
                        Icons.memory,
                        '${ws.processes.processes.length} processus',
                        Colors.purple,
                      ),
                      if (ws.browsers.browsers.isNotEmpty)
                        _buildIndicatorChip(
                          context,
                          Icons.tab_outlined,
                          '${ws.browsers.browsers.length} onglets',
                          Colors.amber,
                        ),
                      if (ws.docker != null && ws.docker!.containers.isNotEmpty)
                        _buildIndicatorChip(
                          context,
                          Icons.grid_view,
                          '${ws.docker!.containers.length} docker',
                          Colors.cyan,
                        ),
                      if (ws.git != null && ws.git!.branch != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.orange.withOpacity(0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.fork_right, size: 14, color: Colors.orange),
                              const SizedBox(width: 4),
                              Text(
                                ws.git!.branch!,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange,
                                ),
                              ),
                              if (ws.git!.hasUncommittedChanges) ...[
                                const SizedBox(width: 4),
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: Colors.redAccent,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                    ],
                  ),

                  // Tags & Timestamps
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      if (ws.tags.isNotEmpty)
                        Expanded(
                          child: Wrap(
                            spacing: 4,
                            children: ws.tags.map((t) {
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.surfaceVariant,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '#$t',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        )
                      else
                        const Spacer(),
                      Text(
                        ws.lastRestoredAt != null
                            ? 'Restauré: ${_formatDate(ws.lastRestoredAt!)}'
                            : 'Créé: ${_formatDate(ws.createdAt)}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildIndicatorChip(BuildContext context, IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
          ),
        ],
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

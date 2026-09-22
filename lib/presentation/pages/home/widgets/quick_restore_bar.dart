import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../domain/entities/workspace.dart';
import '../../../providers/workspace_provider.dart';

class QuickRestoreBar extends ConsumerStatefulWidget {
  final List<Workspace> workspaces;
  final void Function(Workspace workspace)? onRestoreWorkspace;

  const QuickRestoreBar({
    super.key,
    required this.workspaces,
    this.onRestoreWorkspace,
  });

  @override
  ConsumerState<QuickRestoreBar> createState() => _QuickRestoreBarState();
}

class _QuickRestoreBarState extends ConsumerState<QuickRestoreBar> {
  String? _restoringId;

  Future<void> _triggerRestore(Workspace ws) async {
    setState(() => _restoringId = ws.id);
    try {
      final report = await ref.read(workspaceProvider.notifier).restore(ws.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
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
                        ? 'Workspace "${ws.name}" restauré avec succès !'
                        : 'Restauration partielle de "${ws.name}"',
                  ),
                ),
              ],
            ),
            backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _restoringId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.workspaces.isEmpty) return const SizedBox.shrink();

    final quickList = widget.workspaces.take(6).toList();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5),
        ),
      ),
      child: Row(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.bolt, size: 18, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 6),
              Text(
                'Accès Rapide',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
            ],
          ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(quickList.length, (index) {
                  final ws = quickList[index];
                  final isRestoring = _restoringId == ws.id;

                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Tooltip(
                      message: 'Restaurer ${ws.name} (Raccourci: Ctrl+${index + 1})',
                      child: ActionChip(
                        avatar: isRestoring
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              ),
                        label: Text(
                          ws.name,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                        onPressed: isRestoring ? null : () => _triggerRestore(ws),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

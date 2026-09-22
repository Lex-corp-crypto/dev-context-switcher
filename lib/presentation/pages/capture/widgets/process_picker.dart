import 'package:flutter/material.dart';
import '../../../../domain/entities/process_snapshot.dart';

class ProcessPicker extends StatelessWidget {
  final List<ProcessInfo> processes;
  final Set<int> selectedPids;
  final void Function(int pid, bool selected) onToggle;

  const ProcessPicker({
    super.key,
    required this.processes,
    required this.selectedPids,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: ExpansionTile(
        initiallyExpanded: processes.isNotEmpty,
        leading: const Icon(Icons.memory, color: Colors.purple),
        title: Text(
          'Processus Développeur (${selectedPids.length}/${processes.length})',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: Text(
          processes.isEmpty
              ? 'Aucun processus détecté'
              : '${selectedPids.length} sélectionné(s)',
          style: const TextStyle(fontSize: 12),
        ),
        children: [
          if (processes.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Aucun processus de développement actif trouvé.',
                style: TextStyle(fontStyle: FontStyle.italic, fontSize: 13),
              ),
            )
          else
            ...processes.map((proc) {
              final isSelected = selectedPids.contains(proc.pid);
              return CheckboxListTile(
                dense: true,
                value: isSelected,
                onChanged: (val) => onToggle(proc.pid, val ?? false),
                title: Text(
                  '${proc.name} (PID ${proc.pid})',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                ),
                subtitle: Text(
                  proc.commandLine,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                ),
                secondary: proc.cpuUsage != null || proc.memoryUsage != null
                    ? Text(
                        '${proc.cpuUsage != null ? '${proc.cpuUsage!.toStringAsFixed(1)}% CPU' : ''} '
                        '${proc.memoryUsage != null ? '${proc.memoryUsage}% RAM' : ''}',
                        style: const TextStyle(fontSize: 10, color: Colors.grey),
                      )
                    : null,
              );
            }),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../../../domain/entities/terminal_snapshot.dart';

class TerminalPicker extends StatelessWidget {
  final List<TerminalInfo> terminals;
  final Set<String> selectedIds;
  final void Function(String id, bool selected) onToggle;

  const TerminalPicker({
    super.key,
    required this.terminals,
    required this.selectedIds,
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
        initiallyExpanded: terminals.isNotEmpty,
        leading: const Icon(Icons.terminal, color: Colors.teal),
        title: Text(
          'Sessions Terminal (${selectedIds.length}/${terminals.length})',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: Text(
          terminals.isEmpty
              ? 'Aucun terminal actif détecté'
              : '${selectedIds.length} sélectionné(s)',
          style: const TextStyle(fontSize: 12),
        ),
        children: [
          if (terminals.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Aucune session shell trouvée.',
                style: TextStyle(fontStyle: FontStyle.italic, fontSize: 13),
              ),
            )
          else
            ...terminals.map((term) {
              final isSelected = selectedIds.contains(term.id);
              return CheckboxListTile(
                dense: true,
                value: isSelected,
                onChanged: (val) => onToggle(term.id, val ?? false),
                title: Text(
                  'Shell: ${term.shell}',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                ),
                subtitle: Text(
                  term.workingDirectory,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                ),
              );
            }),
        ],
      ),
    );
  }
}

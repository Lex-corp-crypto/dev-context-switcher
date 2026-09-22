import 'package:flutter/material.dart';
import '../../../../domain/entities/window_snapshot.dart';

class WindowPicker extends StatelessWidget {
  final List<WindowInfo> windows;
  final Set<String> selectedIds;
  final void Function(String id, bool selected) onToggle;

  const WindowPicker({
    super.key,
    required this.windows,
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
        initiallyExpanded: windows.isNotEmpty,
        leading: const Icon(Icons.window_outlined, color: Colors.blue),
        title: Text(
          'Fenêtres Applicatives (${selectedIds.length}/${windows.length})',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: Text(
          windows.isEmpty
              ? 'Aucune fenêtre détectée'
              : '${selectedIds.length} sélectionnée(s)',
          style: const TextStyle(fontSize: 12),
        ),
        children: [
          if (windows.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Aucune fenêtre active détectée sur ce display.',
                style: TextStyle(fontStyle: FontStyle.italic, fontSize: 13),
              ),
            )
          else
            ...windows.map((win) {
              final isSelected = selectedIds.contains(win.id);
              return CheckboxListTile(
                dense: true,
                value: isSelected,
                onChanged: (val) => onToggle(win.id, val ?? false),
                title: Text(
                  win.title.isEmpty ? '(Sans titre)' : win.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                ),
                subtitle: Text(
                  'Application: ${win.appName} • ${win.bounds.width.toInt()}x${win.bounds.height.toInt()} à (${win.bounds.left.toInt()}, ${win.bounds.top.toInt()})',
                  style: const TextStyle(fontSize: 11),
                ),
              );
            }),
        ],
      ),
    );
  }
}

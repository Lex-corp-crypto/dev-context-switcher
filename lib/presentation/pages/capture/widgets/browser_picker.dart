import 'package:flutter/material.dart';
import '../../../../domain/entities/browser_snapshot.dart';

class BrowserPicker extends StatefulWidget {
  final List<BrowserInfo> browsers;
  final List<String> customUrls;
  final void Function(String url) onAddUrl;
  final void Function(int index) onRemoveUrl;

  const BrowserPicker({
    super.key,
    required this.browsers,
    required this.customUrls,
    required this.onAddUrl,
    required this.onRemoveUrl,
  });

  @override
  State<BrowserPicker> createState() => _BrowserPickerState();
}

class _BrowserPickerState extends State<BrowserPicker> {
  final _urlController = TextEditingController();

  void _addCurrentUrl() {
    final url = _urlController.text.trim();
    if (url.isNotEmpty) {
      final formatted = url.startsWith('http') ? url : 'https://$url';
      widget.onAddUrl(formatted);
      _urlController.clear();
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final totalCount = widget.browsers.length + widget.customUrls.length;

    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: ExpansionTile(
        initiallyExpanded: totalCount > 0,
        leading: const Icon(Icons.tab_outlined, color: Colors.amber),
        title: Text(
          'URLs & Onglets Navigateur ($totalCount)',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: Text(
          '$totalCount onglet(s) configuré(s)',
          style: const TextStyle(fontSize: 12),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _urlController,
                    decoration: const InputDecoration(
                      hintText: 'Ex: http://localhost:3000 ou https://github.com',
                      isDense: true,
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.link, size: 18),
                    ),
                    onSubmitted: (_) => _addCurrentUrl(),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: _addCurrentUrl,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Ajouter'),
                ),
              ],
            ),
          ),
          if (totalCount == 0)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Ajoutez des URLs importantes à ouvrir automatiquement lors de la restauration.',
                style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
              ),
            ),
          ...widget.customUrls.asMap().entries.map((entry) {
            return ListTile(
              dense: true,
              leading: const Icon(Icons.web, size: 18, color: Colors.amber),
              title: Text(
                entry.value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.close, size: 16),
                onPressed: () => widget.onRemoveUrl(entry.key),
              ),
            );
          }),
        ],
      ),
    );
  }
}

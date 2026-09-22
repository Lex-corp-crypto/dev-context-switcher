import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/active_project_provider.dart';

class DetectedProjectBanner extends ConsumerWidget {
  final void Function(String path, String? suggestedName)? onUseProject;

  const DetectedProjectBanner({super.key, this.onUseProject});

  IconData _getIconForType(String? type) {
    switch (type) {
      case 'flutter':
        return Icons.flutter_dash;
      case 'node':
      case 'react':
      case 'nextjs':
      case 'vue':
        return Icons.javascript;
      case 'python':
        return Icons.code;
      case 'rust':
        return Icons.settings_suggest;
      case 'go':
        return Icons.bolt;
      case 'java':
        return Icons.coffee;
      default:
        return Icons.folder_special_outlined;
    }
  }

  Color _getColorForType(String? type) {
    switch (type) {
      case 'flutter':
        return Colors.blue;
      case 'node':
      case 'react':
      case 'nextjs':
        return Colors.green;
      case 'python':
        return Colors.amber;
      case 'rust':
        return Colors.deepOrange;
      default:
        return Colors.indigoAccent;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeProjectAsync = ref.watch(activeProjectProvider);

    return activeProjectAsync.when(
      data: (project) {
        if (project == null) return const SizedBox.shrink();

        final projectName = project.projectPath?.split('/').last ?? 'Project';
        final projectType = (project.projectType ?? 'project').toUpperCase();
        final typeColor = _getColorForType(project.projectType);

        return Container(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: typeColor.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: typeColor.withOpacity(0.3), width: 1.5),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: typeColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(_getIconForType(project.projectType), color: typeColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Projet Actif Détecté: ',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: typeColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            projectType,
                            style: TextStyle(
                              color: typeColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$projectName (${project.projectPath})',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.tonalIcon(
                style: FilledButton.styleFrom(
                  backgroundColor: typeColor.withOpacity(0.2),
                  foregroundColor: typeColor,
                ),
                onPressed: () {
                  if (onUseProject != null && project.projectPath != null) {
                    onUseProject!(project.projectPath!, projectName);
                  }
                },
                icon: const Icon(Icons.camera_alt_outlined, size: 16),
                label: const Text('Capturer ce contexte'),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

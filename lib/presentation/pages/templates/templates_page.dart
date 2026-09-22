import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../domain/entities/workspace.dart';
import '../../../../domain/entities/window_snapshot.dart';
import '../../../../domain/entities/process_snapshot.dart';
import '../../../../domain/entities/terminal_snapshot.dart';
import '../../../../domain/entities/browser_snapshot.dart';
import '../../../../domain/entities/docker_snapshot.dart';
import '../../providers/workspace_provider.dart';

class TemplateItem {
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  final List<String> tags;
  final Workspace Function() createWorkspace;

  const TemplateItem({
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    required this.tags,
    required this.createWorkspace,
  });
}

class TemplatesPage extends ConsumerWidget {
  const TemplatesPage({super.key});

  static final List<TemplateItem> templates = [
    TemplateItem(
      name: 'Flutter Desktop & Web',
      description: 'Environnement Flutter complet avec terminaux d\'exécution, tests et navigateurs de dev.',
      icon: Icons.flutter_dash,
      color: Colors.blue,
      tags: ['flutter', 'mobile', 'desktop', 'dart'],
      createWorkspace: () => Workspace(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: 'Flutter Dev Studio',
        projectPath: '',
        tags: const ['flutter', 'dart', 'mobile'],
        createdAt: DateTime.now(),
        windows: const WindowSnapshot(windows: []),
        processes: const ProcessSnapshot(processes: [
          ProcessInfo(pid: 0, name: 'dart', commandLine: 'dart run'),
        ]),
        terminals: const TerminalSnapshot(terminals: [
          TerminalInfo(id: '1', workingDirectory: '.', shell: 'bash', recentCommands: ['flutter run -d linux']),
          TerminalInfo(id: '2', workingDirectory: '.', shell: 'bash', recentCommands: ['flutter test']),
        ]),
        browsers: const BrowserSnapshot(browsers: [
          BrowserInfo(id: '1', url: 'https://docs.flutter.dev', title: 'Flutter Docs', browserName: 'default'),
          BrowserInfo(id: '2', url: 'https://pub.dev', title: 'Pub.dev', browserName: 'default'),
        ]),
      ),
    ),
    TemplateItem(
      name: 'Full-Stack Web (Node & React)',
      description: 'Serveur backend Node/Express + Frontend React/Next.js avec onglets localhost.',
      icon: Icons.javascript,
      color: Colors.green,
      tags: ['react', 'node', 'fullstack', 'typescript'],
      createWorkspace: () => Workspace(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: 'Full-Stack Web Workspace',
        projectPath: '',
        tags: const ['node', 'react', 'web'],
        createdAt: DateTime.now(),
        windows: const WindowSnapshot(windows: []),
        processes: const ProcessSnapshot(processes: [
          ProcessInfo(pid: 0, name: 'node', commandLine: 'npm run dev'),
        ]),
        terminals: const TerminalSnapshot(terminals: [
          TerminalInfo(id: '1', workingDirectory: './frontend', shell: 'bash', recentCommands: ['npm run dev']),
          TerminalInfo(id: '2', workingDirectory: './backend', shell: 'bash', recentCommands: ['npm start']),
        ]),
        browsers: const BrowserSnapshot(browsers: [
          BrowserInfo(id: '1', url: 'http://localhost:3000', title: 'Frontend App', browserName: 'default'),
          BrowserInfo(id: '2', url: 'http://localhost:5000/api', title: 'Backend API', browserName: 'default'),
        ]),
      ),
    ),
    TemplateItem(
      name: 'Python AI & Data Science',
      description: 'Stack IA avec Jupyter Notebook, FastAPI server et dashboard de données.',
      icon: Icons.code,
      color: Colors.amber,
      tags: ['python', 'ai', 'fastapi', 'data'],
      createWorkspace: () => Workspace(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: 'Python AI & Machine Learning',
        projectPath: '',
        tags: const ['python', 'ai', 'fastapi'],
        createdAt: DateTime.now(),
        windows: const WindowSnapshot(windows: []),
        processes: const ProcessSnapshot(processes: [
          ProcessInfo(pid: 0, name: 'uvicorn', commandLine: 'uvicorn main:app --reload'),
        ]),
        terminals: const TerminalSnapshot(terminals: [
          TerminalInfo(id: '1', workingDirectory: '.', shell: 'bash', recentCommands: ['source venv/bin/activate', 'jupyter notebook']),
        ]),
        browsers: const BrowserSnapshot(browsers: [
          BrowserInfo(id: '1', url: 'http://localhost:8888', title: 'Jupyter Lab', browserName: 'default'),
          BrowserInfo(id: '2', url: 'http://localhost:8000/docs', title: 'FastAPI Swagger', browserName: 'default'),
        ]),
      ),
    ),
    TemplateItem(
      name: 'DevOps & Docker Microservices',
      description: 'Stack conteneurisée avec PostgreSQL, Redis et outils de surveillance réseau.',
      icon: Icons.grid_view,
      color: Colors.cyan,
      tags: ['docker', 'devops', 'microservices'],
      createWorkspace: () => Workspace(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: 'DevOps & Services',
        projectPath: '',
        tags: const ['docker', 'devops', 'database'],
        createdAt: DateTime.now(),
        windows: const WindowSnapshot(windows: []),
        processes: const ProcessSnapshot(processes: []),
        terminals: const TerminalSnapshot(terminals: [
          TerminalInfo(id: '1', workingDirectory: '.', shell: 'bash', recentCommands: ['docker-compose up -d', 'docker-compose logs -f']),
        ]),
        browsers: const BrowserSnapshot(browsers: [
          BrowserInfo(id: '1', url: 'http://localhost:8080', title: 'Adminer DB Manager', browserName: 'default'),
        ]),
        docker: DockerSnapshot(
          images: const [],
          containers: [
            ContainerInfo(id: 'db', name: 'postgres-db', image: 'postgres:15', command: 'postgres', createdAt: DateTime.now(), status: 'running', ports: const ['5432:5432'], mounts: const []),
            ContainerInfo(id: 'redis', name: 'redis-cache', image: 'redis:alpine', command: 'redis-server', createdAt: DateTime.now(), status: 'running', ports: const ['6379:6379'], mounts: const []),
          ],
        ),
      ),
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Modèles de Workspaces'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20.0),
        children: [
          Text(
            'Choisissez un modèle préconfiguré pour démarrer immédiatement :',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          ...templates.map((tpl) {
            return Card(
              margin: const EdgeInsets.only(bottom: 14),
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(
                  color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.4),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(18.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: tpl.color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(tpl.icon, color: tpl.color, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tpl.name,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            tpl.description,
                            style: TextStyle(
                              fontSize: 13,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 6,
                            children: tpl.tags.map((tag) {
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.surfaceVariant,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text('#$tag', style: const TextStyle(fontSize: 11)),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    FilledButton.tonalIcon(
                      onPressed: () async {
                        final ws = tpl.createWorkspace();
                        await ref.read(workspaceRepositoryProvider).save(ws);
                        ref.read(workspaceProvider.notifier).loadWorkspaces();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Workspace "${tpl.name}" ajouté à votre tableau de bord !'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Utiliser'),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

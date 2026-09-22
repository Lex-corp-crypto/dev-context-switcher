import '../../../domain/entities/workspace.dart';
import '../../../domain/entities/window_snapshot.dart';
import '../../../domain/entities/process_snapshot.dart';
import '../../../domain/entities/terminal_snapshot.dart';
import '../../../domain/entities/browser_snapshot.dart';
import '../../../domain/entities/git_snapshot.dart';
import '../../../domain/entities/docker_snapshot.dart';
import '../../../domain/entities/project_detection.dart';

class WorkspaceModel {
  final String id;
  final String name;
  final String? projectPath;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime? lastRestoredAt;
  final Map<String, dynamic> windows;
  final Map<String, dynamic> processes;
  final Map<String, dynamic> terminals;
  final Map<String, dynamic> browsers;
  final Map<String, dynamic>? git;
  final Map<String, dynamic>? docker;
  final Map<String, dynamic>? projectDetection;

  WorkspaceModel({
    required this.id,
    required this.name,
    this.projectPath,
    this.tags = const [],
    required this.createdAt,
    this.lastRestoredAt,
    required this.windows,
    required this.processes,
    required this.terminals,
    required this.browsers,
    this.git,
    this.docker,
    this.projectDetection,
  });

  factory WorkspaceModel.fromEntity(Workspace entity) {
    return WorkspaceModel(
      id: entity.id,
      name: entity.name,
      projectPath: entity.projectPath,
      tags: entity.tags,
      createdAt: entity.createdAt,
      lastRestoredAt: entity.lastRestoredAt,
      windows: entity.windows.toJson(),
      processes: entity.processes.toJson(),
      terminals: entity.terminals.toJson(),
      browsers: entity.browsers.toJson(),
      git: entity.git?.toJson(),
      docker: entity.docker?.toJson(),
      projectDetection: entity.projectDetection?.toJson(),
    );
  }

  Workspace toEntity() {
    return Workspace(
      id: id,
      name: name,
      projectPath: projectPath,
      tags: tags,
      createdAt: createdAt,
      lastRestoredAt: lastRestoredAt,
      windows: WindowSnapshot.fromJson(windows),
      processes: ProcessSnapshot.fromJson(processes),
      terminals: TerminalSnapshot.fromJson(terminals),
      browsers: BrowserSnapshot.fromJson(browsers),
      git: git != null ? GitSnapshot.fromJson(git!) : null,
      docker: docker != null ? DockerSnapshot.fromJson(docker!) : null,
      projectDetection: projectDetection != null
          ? ProjectDetection.fromJson(projectDetection!)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'projectPath': projectPath,
        'tags': tags,
        'createdAt': createdAt.toIso8601String(),
        'lastRestoredAt': lastRestoredAt?.toIso8601String(),
        'windows': windows,
        'processes': processes,
        'terminals': terminals,
        'browsers': browsers,
        'git': git,
        'docker': docker,
        'projectDetection': projectDetection,
      };

  factory WorkspaceModel.fromJson(Map<String, dynamic> json) => WorkspaceModel(
        id: json['id'],
        name: json['name'],
        projectPath: json['projectPath'],
        tags: List<String>.from(json['tags'] ?? []),
        createdAt: DateTime.parse(json['createdAt']),
        lastRestoredAt: json['lastRestoredAt'] != null
            ? DateTime.parse(json['lastRestoredAt'])
            : null,
        windows: json['windows'] ?? {},
        processes: json['processes'] ?? {},
        terminals: json['terminals'] ?? {},
        browsers: json['browsers'] ?? {},
        git: json['git'],
        docker: json['docker'],
        projectDetection: json['projectDetection'],
      );
}

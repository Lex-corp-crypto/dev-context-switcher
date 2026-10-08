import '../../../domain/entities/workspace.dart';
import '../../../domain/entities/window_snapshot.dart';
import '../../../domain/entities/process_snapshot.dart';
import '../../../domain/entities/terminal_snapshot.dart';
import '../../../domain/entities/browser_snapshot.dart';
import '../../../domain/entities/git_snapshot.dart';
import '../../../domain/entities/docker_snapshot.dart';
import '../../../domain/entities/project_detection.dart';
import '../../../domain/entities/workspace_task.dart';

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
  final List<Map<String, dynamic>> tasks;
  final String? notes;
  final bool isFavorite;
  final String? colorHex;
  final String? iconName;
  final List<String> startupCommands;
  final Map<String, String> envVars;
  final int restoreCount;

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
    this.tasks = const [],
    this.notes,
    this.isFavorite = false,
    this.colorHex,
    this.iconName,
    this.startupCommands = const [],
    this.envVars = const {},
    this.restoreCount = 0,
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
      tasks: entity.tasks.map((t) => t.toJson()).toList(),
      notes: entity.notes,
      isFavorite: entity.isFavorite,
      colorHex: entity.colorHex,
      iconName: entity.iconName,
      startupCommands: entity.startupCommands,
      envVars: entity.envVars,
      restoreCount: entity.restoreCount,
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
      tasks: tasks.map((t) => WorkspaceTask.fromJson(t)).toList(),
      notes: notes,
      isFavorite: isFavorite,
      colorHex: colorHex,
      iconName: iconName,
      startupCommands: startupCommands,
      envVars: envVars,
      restoreCount: restoreCount,
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
        'tasks': tasks,
        'notes': notes,
        'isFavorite': isFavorite,
        'colorHex': colorHex,
        'iconName': iconName,
        'startupCommands': startupCommands,
        'envVars': envVars,
        'restoreCount': restoreCount,
      };

  factory WorkspaceModel.fromJson(Map<String, dynamic> json) => WorkspaceModel(
        id: json['id'] as String,
        name: json['name'] as String,
        projectPath: json['projectPath'] as String?,
        tags: List<String>.from(json['tags'] ?? []),
        createdAt: DateTime.parse(json['createdAt'] as String),
        lastRestoredAt: json['lastRestoredAt'] != null
            ? DateTime.parse(json['lastRestoredAt'] as String)
            : null,
        windows: (json['windows'] as Map<String, dynamic>?) ?? {},
        processes: (json['processes'] as Map<String, dynamic>?) ?? {},
        terminals: (json['terminals'] as Map<String, dynamic>?) ?? {},
        browsers: (json['browsers'] as Map<String, dynamic>?) ?? {},
        git: json['git'] as Map<String, dynamic>?,
        docker: json['docker'] as Map<String, dynamic>?,
        projectDetection: json['projectDetection'] as Map<String, dynamic>?,
        tasks: (json['tasks'] as List<dynamic>?)
                ?.map((e) => Map<String, dynamic>.from(e as Map))
                .toList() ??
            [],
        notes: json['notes'] as String?,
        isFavorite: json['isFavorite'] as bool? ?? false,
        colorHex: json['colorHex'] as String?,
        iconName: json['iconName'] as String?,
        startupCommands: List<String>.from(json['startupCommands'] ?? []),
        envVars: Map<String, String>.from(json['envVars'] ?? {}),
        restoreCount: json['restoreCount'] as int? ?? 0,
      );
}

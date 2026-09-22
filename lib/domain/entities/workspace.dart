import 'package:equatable/equatable.dart';
import 'window_snapshot.dart';
import 'process_snapshot.dart';
import 'terminal_snapshot.dart';
import 'browser_snapshot.dart';
import 'git_snapshot.dart';
import 'docker_snapshot.dart';
import 'project_detection.dart';

class Workspace extends Equatable {
  final String id;
  final String name;
  final String? projectPath;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime? lastRestoredAt;
  final WindowSnapshot windows;
  final ProcessSnapshot processes;
  final TerminalSnapshot terminals;
  final BrowserSnapshot browsers;
  final GitSnapshot? git;
  final DockerSnapshot? docker;
  final ProjectDetection? projectDetection;

  const Workspace({
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

  Workspace copyWith({
    String? id,
    String? name,
    String? projectPath,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? lastRestoredAt,
    WindowSnapshot? windows,
    ProcessSnapshot? processes,
    TerminalSnapshot? terminals,
    BrowserSnapshot? browsers,
    GitSnapshot? git,
    DockerSnapshot? docker,
    ProjectDetection? projectDetection,
  }) {
    return Workspace(
      id: id ?? this.id,
      name: name ?? this.name,
      projectPath: projectPath ?? this.projectPath,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      lastRestoredAt: lastRestoredAt ?? this.lastRestoredAt,
      windows: windows ?? this.windows,
      processes: processes ?? this.processes,
      terminals: terminals ?? this.terminals,
      browsers: browsers ?? this.browsers,
      git: git ?? this.git,
      docker: docker ?? this.docker,
      projectDetection: projectDetection ?? this.projectDetection,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    projectPath,
    tags,
    createdAt,
    lastRestoredAt,
    windows,
    processes,
    terminals,
    browsers,
    git,
    docker,
    projectDetection,
  ];
}

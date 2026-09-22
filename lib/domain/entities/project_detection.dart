import 'package:equatable/equatable.dart';

class ProjectDetection extends Equatable {
  final String? projectType;
  final String? projectPath;
  final String? detectedBy; // e.g., 'git', 'package.json', 'pom.xml', etc.
  final Map<String, String> environmentVariables;
  final List<String> dependencies;

  const ProjectDetection({
    this.projectType,
    this.projectPath,
    this.detectedBy,
    this.environmentVariables = const {},
    this.dependencies = const [],
  });

  ProjectDetection copyWith({
    String? projectType,
    String? projectPath,
    String? detectedBy,
    Map<String, String>? environmentVariables,
    List<String>? dependencies,
  }) {
    return ProjectDetection(
      projectType: projectType ?? this.projectType,
      projectPath: projectPath ?? this.projectPath,
      detectedBy: detectedBy ?? this.detectedBy,
      environmentVariables: environmentVariables ?? this.environmentVariables,
      dependencies: dependencies ?? this.dependencies,
    );
  }

  Map<String, dynamic> toJson() => {
        'projectType': projectType,
        'projectPath': projectPath,
        'detectedBy': detectedBy,
        'environmentVariables': environmentVariables,
        'dependencies': dependencies,
      };

  factory ProjectDetection.fromJson(Map<String, dynamic> json) => ProjectDetection(
        projectType: json['projectType'],
        projectPath: json['projectPath'],
        detectedBy: json['detectedBy'],
        environmentVariables: Map<String, String>.from(json['environmentVariables']),
        dependencies: List<String>.from(json['dependencies']),
      );

  @override
  List<Object?> get props => [
    projectType,
    projectPath,
    detectedBy,
    environmentVariables,
    dependencies,
  ];
}

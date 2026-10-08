import 'package:equatable/equatable.dart';

class WorkspaceTask extends Equatable {
  final String id;
  final String title;
  final bool isCompleted;
  final DateTime createdAt;

  WorkspaceTask({
    required this.id,
    required this.title,
    this.isCompleted = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  WorkspaceTask copyWith({
    String? id,
    String? title,
    bool? isCompleted,
    DateTime? createdAt,
  }) {
    return WorkspaceTask(
      id: id ?? this.id,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'isCompleted': isCompleted,
        'createdAt': createdAt.toIso8601String(),
      };

  factory WorkspaceTask.fromJson(Map<String, dynamic> json) => WorkspaceTask(
        id: json['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
        title: json['title'] as String? ?? '',
        isCompleted: json['isCompleted'] as bool? ?? false,
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
            : DateTime.now(),
      );

  @override
  List<Object?> get props => [id, title, isCompleted, createdAt];
}

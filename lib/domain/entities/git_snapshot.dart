import 'package:equatable/equatable.dart';

class GitSnapshot extends Equatable {
  final String? branch;
  final String? commitHash;
  final bool hasUncommittedChanges;
  final List<String> recentBranches;

  const GitSnapshot({
    this.branch,
    this.commitHash,
    this.hasUncommittedChanges = false,
    this.recentBranches = const [],
  });

  GitSnapshot copyWith({
    String? branch,
    String? commitHash,
    bool? hasUncommittedChanges,
    List<String>? recentBranches,
  }) {
    return GitSnapshot(
      branch: branch ?? this.branch,
      commitHash: commitHash ?? this.commitHash,
      hasUncommittedChanges: hasUncommittedChanges ?? this.hasUncommittedChanges,
      recentBranches: recentBranches ?? this.recentBranches,
    );
  }

  Map<String, dynamic> toJson() => {
        'branch': branch,
        'commitHash': commitHash,
        'hasUncommittedChanges': hasUncommittedChanges,
        'recentBranches': recentBranches,
      };

  factory GitSnapshot.fromJson(Map<String, dynamic> json) => GitSnapshot(
        branch: json['branch'],
        commitHash: json['commitHash'],
        hasUncommittedChanges: json['hasUncommittedChanges'] ?? false,
        recentBranches: List<String>.from(json['recentBranches']),
      );

  @override
  List<Object?> get props => [
    branch,
    commitHash,
    hasUncommittedChanges,
    recentBranches,
  ];
}

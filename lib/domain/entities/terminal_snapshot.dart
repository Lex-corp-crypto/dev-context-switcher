import 'package:equatable/equatable.dart';

class TerminalSnapshot extends Equatable {
  final List<TerminalInfo> terminals;

  const TerminalSnapshot({required this.terminals});

  TerminalSnapshot copyWith({List<TerminalInfo>? terminals}) {
    return TerminalSnapshot(
      terminals: terminals ?? this.terminals,
    );
  }

  Map<String, dynamic> toJson() => {
        'terminals': terminals.map((t) => t.toJson()).toList(),
      };

  factory TerminalSnapshot.fromJson(Map<String, dynamic> json) => TerminalSnapshot(
        terminals: List<TerminalInfo>.from(
            json['terminals'].map((t) => TerminalInfo.fromJson(t))),
      );

  @override
  List<Object?> get props => [terminals];
}

class TerminalInfo extends Equatable {
  final String id;
  final String workingDirectory;
  final String shell;
  final List<String> recentCommands;
  final String? title;

  const TerminalInfo({
    required this.id,
    required this.workingDirectory,
    required this.shell,
    this.recentCommands = const [],
    this.title,
  });

  TerminalInfo copyWith({
    String? id,
    String? workingDirectory,
    String? shell,
    List<String>? recentCommands,
    String? title,
  }) {
    return TerminalInfo(
      id: id ?? this.id,
      workingDirectory: workingDirectory ?? this.workingDirectory,
      shell: shell ?? this.shell,
      recentCommands: recentCommands ?? this.recentCommands,
      title: title ?? this.title,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'workingDirectory': workingDirectory,
        'shell': shell,
        'recentCommands': recentCommands,
        'title': title,
      };

  factory TerminalInfo.fromJson(Map<String, dynamic> json) => TerminalInfo(
        id: json['id'],
        workingDirectory: json['workingDirectory'],
        shell: json['shell'],
        recentCommands: List<String>.from(json['recentCommands']),
        title: json['title'],
      );

  @override
  List<Object?> get props => [
    id,
    workingDirectory,
    shell,
    recentCommands,
    title,
  ];
}

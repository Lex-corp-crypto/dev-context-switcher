import 'package:equatable/equatable.dart';

class ProcessSnapshot extends Equatable {
  final List<ProcessInfo> processes;

  const ProcessSnapshot({required this.processes});

  ProcessSnapshot copyWith({List<ProcessInfo>? processes}) {
    return ProcessSnapshot(
      processes: processes ?? this.processes,
    );
  }

  Map<String, dynamic> toJson() => {
        'processes': processes.map((p) => p.toJson()).toList(),
      };

  factory ProcessSnapshot.fromJson(Map<String, dynamic> json) => ProcessSnapshot(
        processes: List<ProcessInfo>.from(
            json['processes'].map((p) => ProcessInfo.fromJson(p))),
      );

  @override
  List<Object?> get props => [processes];
}

class ProcessInfo extends Equatable {
  final int pid;
  final String name;
  final String commandLine;
  final int? memoryUsage; // in MB
  final double? cpuUsage; // percentage

  const ProcessInfo({
    required this.pid,
    required this.name,
    required this.commandLine,
    this.memoryUsage,
    this.cpuUsage,
  });

  ProcessInfo copyWith({
    int? pid,
    String? name,
    String? commandLine,
    int? memoryUsage,
    double? cpuUsage,
  }) {
    return ProcessInfo(
      pid: pid ?? this.pid,
      name: name ?? this.name,
      commandLine: commandLine ?? this.commandLine,
      memoryUsage: memoryUsage ?? this.memoryUsage,
      cpuUsage: cpuUsage ?? this.cpuUsage,
    );
  }

  Map<String, dynamic> toJson() => {
        'pid': pid,
        'name': name,
        'commandLine': commandLine,
        'memoryUsage': memoryUsage,
        'cpuUsage': cpuUsage,
      };

  factory ProcessInfo.fromJson(Map<String, dynamic> json) => ProcessInfo(
        pid: json['pid'],
        name: json['name'],
        commandLine: json['commandLine'],
        memoryUsage: json['memoryUsage'],
        cpuUsage: json['cpuUsage'],
      );

  @override
  List<Object?> get props => [
    pid,
    name,
    commandLine,
    memoryUsage,
    cpuUsage,
  ];
}

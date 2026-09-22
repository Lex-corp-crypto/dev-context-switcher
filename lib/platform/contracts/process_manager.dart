import 'package:equatable/equatable.dart';

abstract class ProcessManager {
  /// Liste les processus de développement (node, docker, python, etc.)
  Future<List<ProcessInfo>> listDevProcesses();

  /// Tue un processus
  Future<void> killProcess(int pid);
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

  @override
  List<Object?> get props => [
    pid,
    name,
    commandLine,
    memoryUsage,
    cpuUsage,
  ];
}

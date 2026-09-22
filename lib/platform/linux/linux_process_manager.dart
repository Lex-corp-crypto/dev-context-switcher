import 'package:process_run/shell.dart';
import '../contracts/process_manager.dart';

class LinuxProcessManager implements ProcessManager {
  final _shell = Shell();

  static const _devKeywords = [
    'code', 'vscode', 'idea', 'pycharm', 'webstorm', 'nvim', 'vim', 'sublime',
    'node', 'npm', 'pnpm', 'yarn', 'bun', 'deno',
    'python', 'python3', 'gunicorn', 'uvicorn', 'flask', 'django',
    'dart', 'flutter', 'cargo', 'rustc', 'go', 'java', 'gradle',
    'docker', 'containerd', 'postgres', 'mysqld', 'redis',
    'chrome', 'firefox', 'brave', 'chromium',
    'bash', 'zsh', 'fish', 'git',
  ];

  @override
  Future<List<ProcessInfo>> listDevProcesses() async {
    try {
      final result = await _shell.run('ps -eo pid,%cpu,%mem,comm,args --sort=-%mem | head -80');
      final List<ProcessInfo> processes = [];

      final stdout = result.isNotEmpty ? result.first.stdout.toString() : '';
      final lines = stdout.split('\n');
      for (int i = 1; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;
        final parts = line.split(RegExp(r'\s+'));
        if (parts.length >= 5) {
          final pid = int.tryParse(parts[0]) ?? 0;
          final cpu = double.tryParse(parts[1]);
          final memPercent = double.tryParse(parts[2]);
          final comm = parts[3];
          final commandLine = parts.sublist(4).join(' ');

          // Filter dev-related processes
          final isDev = _devKeywords.any((k) =>
            comm.toLowerCase().contains(k) || commandLine.toLowerCase().contains(k)
          );

          if (isDev) {
            processes.add(ProcessInfo(
              pid: pid,
              name: comm,
              commandLine: commandLine,
              memoryUsage: memPercent?.toInt(),
              cpuUsage: cpu,
            ));
          }
        }
      }
      return processes;
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> killProcess(int pid) async {
    await _shell.run('kill $pid');
  }
}

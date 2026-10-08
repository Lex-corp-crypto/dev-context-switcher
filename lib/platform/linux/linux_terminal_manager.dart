import 'dart:io';
import 'package:process_run/shell.dart';
import '../contracts/terminal_manager.dart';

class LinuxTerminalManager implements TerminalManager {
  final _shell = Shell();

  @override
  Future<List<TerminalInfo>> listTerminals() async {
    final List<TerminalInfo> terminals = [];
    try {
      final result = await _shell.run("ps -eo pid,comm | grep -E 'bash|zsh|fish|sh' | head -20");
      final stdout = result.isNotEmpty ? result.first.stdout.toString() : '';
      for (final line in stdout.split('\n')) {
        final parts = line.trim().split(RegExp(r'\s+'));
        if (parts.length >= 2) {
          final pid = parts[0];
          final shellName = parts[1];
          try {
            final link = Link('/proc/$pid/cwd');
            if (await link.exists()) {
              final target = await link.target();
              if (target.isNotEmpty && !terminals.any((t) => t.workingDirectory == target)) {
                terminals.add(TerminalInfo(
                  id: pid,
                  workingDirectory: target,
                  shell: shellName,
                  recentCommands: const [],
                  title: '$shellName ($target)',
                ));
              }
            }
          } catch (_) {}
        }
      }
    } catch (_) {}

    return terminals;
  }

  @override
  Future<String> openTerminal({
    required String workingDirectory,
    String? command,
    String? profile,
    bool runInBackground = false,
  }) async {
    final shell = profile ?? 'bash';
    final cmd = command ?? '';

    // Prefer detected terminal emulator
    final candidates = ['ptyxis', 'cosmic-term', 'konsole', 'gnome-terminal', 'alacritty', 'kitty', 'foot', 'xfce4-terminal', 'x-terminal-emulator', 'xterm'];
    String? chosenTerminal;
    for (final cand in candidates) {
      try {
        final check = await Process.run('which', [cand]);
        if (check.exitCode == 0) {
          chosenTerminal = cand;
          break;
        }
      } catch (_) {}
    }

    try {
      if (chosenTerminal != null) {
        if (cmd.isNotEmpty) {
          await Process.start(
            chosenTerminal,
            chosenTerminal == 'xterm'
                ? ['-e', '$shell -c "cd \'$workingDirectory\' && $cmd; exec $shell"']
                : ['--working-directory=$workingDirectory', '-e', '$shell -c "$cmd; exec $shell"'],
            mode: ProcessStartMode.detached,
          );
        } else {
          await Process.start(
            chosenTerminal,
            chosenTerminal == 'xterm'
                ? ['-e', '$shell -c "cd \'$workingDirectory\'; exec $shell"']
                : ['--working-directory=$workingDirectory'],
            mode: ProcessStartMode.detached,
          );
        }
        return chosenTerminal;
      }
    } catch (_) {}

    // Fallback detached background process
    final result = await Process.start(
      shell,
      ['-c', 'cd "$workingDirectory" && $cmd'],
      workingDirectory: workingDirectory,
      mode: ProcessStartMode.detached,
    );
    return result.pid.toString();
  }

  @override
  Future<List<String>> listProfiles() async {
    final List<String> profiles = [];
    try {
      final file = File('/etc/shells');
      if (await file.exists()) {
        final lines = await file.readAsLines();
        for (final line in lines) {
          final trimmed = line.trim();
          if (trimmed.isNotEmpty && trimmed.startsWith('/')) {
            profiles.add(trimmed.split('/').last);
          }
        }
      }
    } catch (_) {}
    if (profiles.isEmpty) {
      profiles.addAll(['bash', 'sh']);
    }
    return profiles.toSet().toList();
  }
}

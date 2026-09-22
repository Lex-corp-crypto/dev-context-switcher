import '../contracts/terminal_manager.dart';
import 'dart:io';

class WinTerminalManager implements TerminalManager {
  @override
  Future<String> openTerminal({
    required String workingDirectory,
    String? command,
    String? profile,
    bool runInBackground = false,
  }) async {
    // Windows Terminal (wt.exe) si dispo, sinon cmd
    final shell = profile ?? 'wt';
    final cmd = command ?? '';
    final result = await Process.run(
      shell,
      ['-d', workingDirectory, 'pwsh', '-NoExit', '-Command', cmd],
    );
    return result.pid.toString();
  }

  @override
  Future<List<TerminalInfo>> listTerminals() async {
    // TODO: Implement listing terminals on Windows
    return [];
  }

  @override
  Future<List<String>> listProfiles() async {
    // TODO: List available profiles (Windows Terminal, Command Prompt, PowerShell, etc.)
    return ['Command Prompt', 'PowerShell', 'Windows Terminal'];
  }
}

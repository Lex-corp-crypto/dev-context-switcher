import 'dart:io';
import '../contracts/terminal_manager.dart';

class MacOSTerminalManager implements TerminalManager {
  @override
  Future<List<TerminalInfo>> listTerminals() async {
    // TODO: Implement using AppleScript to get terminal windows and their working directories
    return [];
  }

  @override
  Future<String> openTerminal({
    required String workingDirectory,
    String? command,
    String? profile,
    bool runInBackground = false,
  }) async {
    final cmd = command ?? '';
    // Use osascript to open Terminal.app and execute command
    final script = '''
      tell application "Terminal"
        do script "cd $workingDirectory && $cmd"
      end tell
    ''';
    await Process.run('osascript', ['-e', script]);
    // Return a dummy ID since we can't easily get the terminal PID
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  @override
  Future<List<String>> listProfiles() async {
    // TODO: List available shells (bash, zsh, fish, etc.)
    return ['bash', 'zsh', 'fish'];
  }
}

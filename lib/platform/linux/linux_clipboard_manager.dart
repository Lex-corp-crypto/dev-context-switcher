import '../contracts/clipboard_manager.dart';
import 'package:process_run/shell.dart';

class LinuxClipboardManager implements ClipboardManager {
  final _shell = Shell();

  @override
  Future<void> copyText(String text) async {
    // Use xclip to copy text to clipboard
    // We'll use echo to pipe the text to xclip
    await _shell.run('echo "$text" | xclip -selection clipboard');
  }

  @override
  Future<String> pasteText() async {
    // Use xclip to paste text from clipboard
    final result = await _shell.run('xclip -selection clipboard -o');
    final stdout = result.isNotEmpty ? result.first.stdout.toString() : '';
    return stdout.trim();
  }
}
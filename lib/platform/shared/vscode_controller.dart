import 'dart:io';
import '../contracts/vscode_manager.dart';

class VscodeController implements VscodeManager {
  @override
  Future<void> openFolder(String folderPath) async {
    await Process.run('code', [folderPath]);
  }

  @override
  Future<void> openFile(String filePath, {int? line, int? column}) async {
    final args = <String>[filePath];
    if (line != null) {
      args.add('--goto');
      args.add('$line:$column');
    }
    await Process.run('code', args);
  }

  @override
  Future<bool> isInstalled() async {
    final result = await Process.run('code', ['--version']);
    return result.exitCode == 0;
  }
}

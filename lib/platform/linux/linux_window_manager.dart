import 'dart:ui';
import 'package:process_run/shell.dart';
import '../contracts/window_manager.dart';

class LinuxWindowManager implements WindowManager {
  final _shell = Shell();

  @override
  Future<List<WindowInfo>> listWindows() async {
    try {
      // 1. Try xdotool if installed
      final result = await _shell.run('''
        for id in \$(xdotool search --onlyvisible --name "" 2>/dev/null); do
          name=\$(xdotool getwindowname \$id 2>/dev/null)
          geom=\$(xdotool getwindowgeometry --shell \$id 2>/dev/null)
          echo "---"
          echo "ID=\$id"
          echo "NAME=\$name"
          echo "\$geom"
        done
      ''');
      final stdout = result.isNotEmpty ? result.first.stdout.toString() : '';
      final parsed = _parseXdotoolOutput(stdout);
      if (parsed.isNotEmpty) return parsed;
    } catch (_) {
      // xdotool failed or not installed, try alternative
    }

    try {
      // 2. Try wmctrl if installed
      final wmctrlResult = await _shell.run('wmctrl -l -G 2>/dev/null');
      final stdout = wmctrlResult.isNotEmpty ? wmctrlResult.first.stdout.toString() : '';
      if (stdout.trim().isNotEmpty) {
        final List<WindowInfo> windows = [];
        for (final line in stdout.split('\n')) {
          final parts = line.trim().split(RegExp(r'\s+'));
          if (parts.length >= 8) {
            final id = parts[0];
            final x = double.tryParse(parts[2]) ?? 0;
            final y = double.tryParse(parts[3]) ?? 0;
            final w = double.tryParse(parts[4]) ?? 800;
            final h = double.tryParse(parts[5]) ?? 600;
            final title = parts.sublist(7).join(' ');
            windows.add(WindowInfo(
              id: id,
              title: title,
              appName: _extractAppName(title),
              bounds: Rect.fromLTWH(x, y, w, h),
              isMinimized: false,
              isFocused: false,
            ));
          }
        }
        if (windows.isNotEmpty) return windows;
      }
    } catch (_) {}

    return [];
  }

  List<WindowInfo> _parseXdotoolOutput(String output) {
    final List<WindowInfo> windows = [];
    final lines = output.split('\n');
    String? id;
    String? name;
    Map<String, String> geom = {};

    for (final line in lines) {
      if (line == '---') {
        if (id != null && name != null && geom.isNotEmpty) {
          windows.add(WindowInfo(
            id: id,
            title: name,
            appName: _extractAppName(name),
            executablePath: null, // TODO: extract from window
            bounds: Rect.fromLTWH(
              double.parse(geom['X']!),
              double.parse(geom['Y']!),
              double.parse(geom['WIDTH']!),
              double.parse(geom['HEIGHT']!),
            ),
            isMinimized: false, // TODO: check if minimized
            isFocused: false, // TODO: check if focused
            monitorIndex: null, // TODO: get monitor index
          ));
        }
        id = null;
        name = null;
        geom = {};
        continue;
      }

      if (line.startsWith('ID=')) {
        id = line.substring(3);
      } else if (line.startsWith('NAME=')) {
        name = line.substring(5);
      } else if (line.contains('=')) {
        final parts = line.split('=');
        if (parts.length == 2) {
          geom[parts[0]] = parts[1];
        }
      }
    }
    // Handle last window
    if (id != null && name != null && geom.isNotEmpty) {
      windows.add(WindowInfo(
        id: id,
        title: name,
        appName: _extractAppName(name),
        executablePath: null,
        bounds: Rect.fromLTWH(
          double.parse(geom['X']!),
          double.parse(geom['Y']!),
          double.parse(geom['WIDTH']!),
          double.parse(geom['HEIGHT']!),
        ),
        isMinimized: false,
        isFocused: false,
        monitorIndex: null,
      ));
    }

    return windows;
  }

  String _extractAppName(String title) {
    // Simple extraction: take the first word or common separators
    // This is a placeholder and should be improved
    return title.split(' ')[0];
  }

  @override
  Future<void> moveWindow(String windowId, Rect bounds) async {
    await _shell.run(
      'xdotool windowmove $windowId ${bounds.left.toInt()} ${bounds.top.toInt()} '
      'windowsize $windowId ${bounds.width.toInt()} ${bounds.height.toInt()}',
    );
  }

  @override
  Future<void> focusWindow(String windowId) async {
    await _shell.run('xdotool windowactivate $windowId');
  }

  @override
  Future<void> closeWindow(String windowId) async {
    await _shell.run('xdotool windowclose $windowId');
  }

  @override
  Future<String> launchApp(String executable, {List<String>? args}) async {
    final argStr = args?.join(' ') ?? '';
    final result = await _shell.run('$executable $argStr & echo \$!');
    final stdout = result.isNotEmpty ? result.first.stdout.toString() : '';
    return stdout.trim();
  }

  @override
  Future<List<MonitorInfo>> listMonitors() async {
    // Use xrandr to get monitor information
    final result = await _shell.run('xrandr --query');
    final List<MonitorInfo> monitors = [];
    int index = 0;

    final stdout = result.isNotEmpty ? result.first.stdout.toString() : '';
    for (final line in stdout.split('\n')) {
      if (line.contains(' connected ')) {
        // Example: "DP-1 connected primary 1920x1080+0+0"
        final parts = line.split(' ');
        final name = parts[0];
        final bool isPrimary = parts.contains('primary');
        // Find the resolution part
        String? resolution;
        for (final part in parts) {
          if (part.contains('x') && part.contains('+')) {
            resolution = part.split('+')[0];
            break;
          }
        }
        if (resolution != null) {
          final resParts = resolution.split('x');
          final width = int.parse(resParts[0]);
          final height = int.parse(resParts[1]);
          // Get position
          final posPart = parts.firstWhere((p) => p.contains('+'), orElse: () => '');
          final pos = posPart.split('+');
          final x = int.parse(pos[1]);
          final y = int.parse(pos[2]);

          monitors.add(MonitorInfo(
            index: index++,
            name: name,
            bounds: Rect.fromLTWH(x.toDouble(), y.toDouble(), width.toDouble(), height.toDouble()),
            isPrimary: isPrimary,
          ));
        }
      }
    }

    return monitors;
  }
}

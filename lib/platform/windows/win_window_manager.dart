import '../contracts/window_manager.dart';
import 'dart:io';
import 'dart:ui';

class WinWindowManager implements WindowManager {
  @override
  Future<List<WindowInfo>> listWindows() async {
    // TODO: Implement using FFI or Win32 API
    return [];
  }

  @override
  Future<void> moveWindow(String windowId, Rect bounds) async {
    // TODO: Implement using FFI or Win32 API
  }

  @override
  Future<void> focusWindow(String windowId) async {
    // TODO: Implement using FFI or Win32 API
  }

  @override
  Future<void> closeWindow(String windowId) async {
    // TODO: Implement using FFI or Win32 API (send WM_CLOSE)
  }

  @override
  Future<String> launchApp(String executable, {List<String>? args}) async {
    final argStr = args?.join(' ') ?? '';
    final List<String> arguments = [];
    if (argStr.isNotEmpty) {
      arguments.addAll(['/c', 'start', '', executable, argStr]);
    } else {
      arguments.addAll(['/c', 'start', '', executable]);
    }
    final result = await Process.run('cmd', arguments);
    return result.pid.toString();
  }

  @override
  Future<List<MonitorInfo>> listMonitors() async {
    // TODO: Implement monitor enumeration on Windows
    return [];
  }
}

import 'dart:io' show Platform;
import '../contracts/window_manager.dart';
import '../contracts/terminal_manager.dart';
import '../contracts/process_manager.dart';
import '../contracts/browser_manager.dart';
import '../contracts/git_manager.dart';
import '../contracts/docker_manager.dart';
import '../contracts/clipboard_manager.dart';
import '../contracts/vscode_manager.dart';

import '../linux/linux_window_manager.dart';
import '../linux/linux_process_manager.dart';
import '../linux/linux_terminal_manager.dart';
import '../linux/linux_docker_manager.dart';
import '../linux/linux_clipboard_manager.dart';

import '../windows/win_window_manager.dart';
import '../windows/win_process_manager.dart';
import '../windows/win_terminal_manager.dart';
import '../windows/win_docker_manager.dart';

import '../macos/macos_window_manager.dart';
import '../macos/macos_process_manager.dart';
import '../macos/macos_terminal_manager.dart';
import '../macos/macos_docker_manager.dart';

import '../shared/browser_controller.dart';
import '../shared/git_controller.dart';
import '../shared/vscode_controller.dart';

class PlatformFactory {
  static WindowManager createWindowManager() {
    if (Platform.isLinux) return LinuxWindowManager();
    if (Platform.isWindows) return WinWindowManager();
    if (Platform.isMacOS) return MacOSWindowManager();
    throw UnsupportedError('OS non supporté');
  }

  static TerminalManager createTerminalManager() {
    if (Platform.isLinux) return LinuxTerminalManager();
    if (Platform.isWindows) return WinTerminalManager();
    if (Platform.isMacOS) return MacOSTerminalManager();
    throw UnsupportedError('OS non supporté');
  }

  static ProcessManager createProcessManager() {
    if (Platform.isLinux) return LinuxProcessManager();
    if (Platform.isWindows) return WinProcessManager();
    if (Platform.isMacOS) return MacOSProcessManager();
    throw UnsupportedError('OS non supporté');
  }

  static BrowserManager createBrowserManager() {
    // Shared implementation for all platforms
    return BrowserController();
  }

  static GitManager createGitManager() {
    // Shared implementation for all platforms
    return GitController();
  }

  static DockerManager createDockerManager() {
    if (Platform.isLinux) return LinuxDockerManager();
    if (Platform.isWindows) return WinDockerManager();
    if (Platform.isMacOS) return MacOSDockerManager();
    throw UnsupportedError('OS non supporté');
  }

  static ClipboardManager createClipboardManager() {
    if (Platform.isLinux) return LinuxClipboardManager();
    if (Platform.isWindows) throw UnimplementedError('ClipboardManager not implemented for Windows');
    if (Platform.isMacOS) throw UnimplementedError('ClipboardManager not implemented for macOS');
    throw UnsupportedError('OS non supporté');
  }

  static VscodeManager createVscodeManager() {
    // Shared implementation for all platforms
    return VscodeController();
  }
}

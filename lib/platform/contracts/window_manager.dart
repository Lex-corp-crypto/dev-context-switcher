import 'dart:ui';

abstract class WindowManager {
  /// Liste toutes les fenêtres visibles avec leur position/taille
  Future<List<WindowInfo>> listWindows();

  /// Déplace et redimensionne une fenêtre
  Future<void> moveWindow(String windowId, Rect bounds);

  /// Met une fenêtre au premier plan
  Future<void> focusWindow(String windowId);

  /// Ferme une fenêtre (proprement, pas kill)
  Future<void> closeWindow(String windowId);

  /// Lance une app avec des arguments (et éventuellement un fichier)
  Future<String> launchApp(String executable, {List<String>? args});

  /// Récupère l'écran principal (pour le multi-monitor)
  Future<List<MonitorInfo>> listMonitors();
}

class WindowInfo {
  final String id;           // handle natif
  final String title;
  final String appName;
  final String? executablePath;
  final Rect bounds;
  final bool isMinimized;
  final bool isFocused;
  final int? monitorIndex;

  WindowInfo({
    required this.id,
    required this.title,
    required this.appName,
    this.executablePath,
    required this.bounds,
    required this.isMinimized,
    required this.isFocused,
    this.monitorIndex,
  });
}

class MonitorInfo {
  final int index;
  final String name;
  final Rect bounds;
  final bool isPrimary;

  MonitorInfo({
    required this.index,
    required this.name,
    required this.bounds,
    required this.isPrimary,
  });
}

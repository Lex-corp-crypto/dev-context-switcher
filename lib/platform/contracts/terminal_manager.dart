abstract class TerminalManager {
  /// Détecte les terminaux ouverts et leurs répertoires de travail
  Future<List<TerminalInfo>> listTerminals();

  /// Ouvre un terminal dans un dossier, exécute une commande
  Future<String> openTerminal({
    required String workingDirectory,
    String? command,
    String? profile,          // ex: 'bash', 'zsh', 'pwsh', 'wsl'
    bool runInBackground = false,
  });

  /// Liste les profils disponibles (Windows Terminal, iTerm, etc.)
  Future<List<String>> listProfiles();
}

class TerminalInfo {
  final String id;
  final String workingDirectory;
  final String shell;
  final List<String> recentCommands;   // si détectable
  final String? title;

  TerminalInfo({
    required this.id,
    required this.workingDirectory,
    required this.shell,
    this.recentCommands = const [],
    this.title,
  });
}

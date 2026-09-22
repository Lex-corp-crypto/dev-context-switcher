abstract class GitManager {
  /// Obtient la branche Git actuelle dans le chemin du projet spécifié
  Future<String> getCurrentBranch(String projectPath);

  /// Effectue un checkout sur la branche spécifiée
  Future<void> checkout(String projectPath, String branch);

  /// Vérifie s'il y a des modifications non commitées
  Future<bool> hasUncommittedChanges(String projectPath);

  /// Obtient les branches récentes triées par date de commit
  Future<List<String>> getRecentBranches(String projectPath, {int limit = 10});
}

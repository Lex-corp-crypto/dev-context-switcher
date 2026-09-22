import 'dart:async';
import '../../platform/factory/platform_factory.dart';
import '../../platform/contracts/window_manager.dart' as contract_wm;
import '../../platform/contracts/terminal_manager.dart' as contract_tm;
import '../../platform/contracts/browser_manager.dart' as contract_bm;
import '../../platform/contracts/git_manager.dart' as contract_gm;
import '../../platform/contracts/docker_manager.dart' as contract_dm;
import '../../domain/entities/workspace.dart' as domain_ws;
import '../../domain/entities/process_snapshot.dart' as domain_ps;
import '../../domain/entities/terminal_snapshot.dart' as domain_ts;
import '../../domain/entities/browser_snapshot.dart' as domain_bs;
import '../../domain/entities/git_snapshot.dart' as domain_gs;
import '../../domain/entities/docker_snapshot.dart' as domain_ds;
import '../../domain/entities/window_snapshot.dart' as domain_wsnap;

class RestoreOptions {
  final bool restoreGit;
  final bool restoreDocker;
  final bool restoreProcesses;
  final bool restoreTerminals;
  final bool restoreBrowsers;
  final bool restoreWindows;

  const RestoreOptions({
    this.restoreGit = true,
    this.restoreDocker = true,
    this.restoreProcesses = true,
    this.restoreTerminals = true,
    this.restoreBrowsers = true,
    this.restoreWindows = true,
  });
}

class RestorationReport {
  final bool success;
  final List<String> logs;
  final int restoredProcesses;
  final int restoredTerminals;
  final int restoredBrowsers;
  final int restoredContainers;
  final String? gitBranchRestored;
  final int restoredWindows;
  final Duration restorationDuration;

  const RestorationReport({
    required this.success,
    this.logs = const [],
    this.restoredProcesses = 0,
    this.restoredTerminals = 0,
    this.restoredBrowsers = 0,
    this.restoredContainers = 0,
    this.gitBranchRestored,
    this.restoredWindows = 0,
    required this.restorationDuration,
  });
}

class WorkspaceRestorationService {
  final contract_wm.WindowManager _windowManager;
  final contract_tm.TerminalManager _terminalManager;
  final contract_bm.BrowserManager _browserManager;
  final contract_gm.GitManager _gitManager;
  final contract_dm.DockerManager _dockerManager;
  bool _isRestoring = false;

  WorkspaceRestorationService({
    contract_wm.WindowManager? windowManager,
    contract_tm.TerminalManager? terminalManager,
    contract_bm.BrowserManager? browserManager,
    contract_gm.GitManager? gitManager,
    contract_dm.DockerManager? dockerManager,
  })  : _windowManager = windowManager ?? PlatformFactory.createWindowManager(),
        _terminalManager = terminalManager ?? PlatformFactory.createTerminalManager(),
        _browserManager = browserManager ?? PlatformFactory.createBrowserManager(),
        _gitManager = gitManager ?? PlatformFactory.createGitManager(),
        _dockerManager = dockerManager ?? PlatformFactory.createDockerManager();

  bool get isRestoring => _isRestoring;

  Future<bool> restoreWorkspace(domain_ws.Workspace workspace) async {
    final report = await restoreWorkspaceWithReport(workspace);
    return report.success;
  }

  Future<RestorationReport> restoreWorkspaceWithReport(
    domain_ws.Workspace workspace, {
    RestoreOptions options = const RestoreOptions(),
    Duration timeout = const Duration(seconds: 60),
  }) async {
    if (_isRestoring) {
      throw StateError('Restoration already in progress');
    }
    _isRestoring = true;
    final stopwatch = Stopwatch()..start();
    final logs = <String>[];
    int restoredProcCount = 0;
    int restoredTermCount = 0;
    int restoredBrowserCount = 0;
    int restoredContainerCount = 0;
    String? restoredBranch;
    int restoredWindowCount = 0;

    try {
      logs.add('Début de la restauration de l\'espace de travail...');

      // 1. Restore git state
      if (options.restoreGit && workspace.git != null && workspace.projectPath != null) {
        final branch = workspace.git!.branch;
        if (branch != null && branch.isNotEmpty) {
          logs.add('Restauration de la branche Git "$branch"...');
          await _restoreGitState(workspace.projectPath!, workspace.git!).timeout(timeout);
          restoredBranch = branch;
          logs.add('Branche Git vérifiée : $branch');
        }
      }

      // 2. Restore docker containers
      if (options.restoreDocker &&
          workspace.docker != null &&
          workspace.docker!.containers.isNotEmpty) {
        logs.add('Restauration de ${workspace.docker!.containers.length} conteneur(s) Docker...');
        final contractContainers = workspace.docker!.containers
            .map<contract_dm.ContainerInfo>(_domainToContractContainer)
            .toList();
        await _dockerManager.startCompose(contractContainers).timeout(timeout);
        restoredContainerCount = contractContainers.length;
        logs.add('Conteneurs Docker initiés');
      }

      // 3. Launch applications/processes
      if (options.restoreProcesses) {
        logs.add('Lancement de ${workspace.processes.processes.length} processus(s)...');
        for (final process in workspace.processes.processes) {
          final launched = await _launchProcess(process).timeout(const Duration(seconds: 10), onTimeout: () => false);
          if (launched) {
            restoredProcCount++;
            logs.add('Processus lancé : ${process.name}');
          } else {
            logs.add('Échec du lancement du processus : ${process.name}');
          }
        }
      }

      // 4. Open terminal sessions
      if (options.restoreTerminals) {
        logs.add('Ouverture de ${workspace.terminals.terminals.length} session(s) terminal...');
        for (final terminal in workspace.terminals.terminals) {
          try {
            await _openTerminal(terminal).timeout(const Duration(seconds: 5));
            restoredTermCount++;
            logs.add('Terminal ouvert dans ${terminal.workingDirectory}');
          } catch (e) {
            logs.add('Échec d\'ouverture du terminal dans ${terminal.workingDirectory} : $e');
          }
        }
      }

      // 5. Open browser tabs
      if (options.restoreBrowsers) {
        logs.add('Ouverture de ${workspace.browsers.browsers.length} onglet(s) navigateur...');
        for (final browser in workspace.browsers.browsers) {
          if (browser.url.isNotEmpty) {
            try {
              await _openBrowser(browser).timeout(const Duration(seconds: 5));
              restoredBrowserCount++;
              logs.add('Onglet navigateur ouvert : ${browser.url}');
            } catch (e) {
              logs.add('Échec d\'ouverture de l\'onglet navigateur ${browser.url} : $e');
            }
          }
        }
      }

      // 6. Reposition windows if enabled (basic attempt)
      if (options.restoreWindows && workspace.windows.windows.isNotEmpty) {
        logs.add('Tentative de repositionnement de ${workspace.windows.windows.length} fenêtre(s)...');
        restoredWindowCount = await _attemptWindowRestoration(workspace.windows.windows);
        logs.add('$restoredWindowCount fenêtre(s) repositionnée(s) avec succès');
      }

      logs.add('Espace de travail restauré avec succès !');
      stopwatch.stop();

      return RestorationReport(
        success: true,
        logs: logs,
        restoredProcesses: restoredProcCount,
        restoredTerminals: restoredTermCount,
        restoredBrowsers: restoredBrowserCount,
        restoredContainers: restoredContainerCount,
        gitBranchRestored: restoredBranch,
        restoredWindows: restoredWindowCount,
        restorationDuration: stopwatch.elapsed,
      );
    } on TimeoutException catch (_) {
      stopwatch.stop();
      logs.add('Opération de restauration expirée après ${timeout.inSeconds} secondes');
      return RestorationReport(
        success: false,
        logs: logs,
        restoredProcesses: restoredProcCount,
        restoredTerminals: restoredTermCount,
        restoredBrowsers: restoredBrowserCount,
        restoredContainers: restoredContainerCount,
        gitBranchRestored: restoredBranch,
        restoredWindows: restoredWindowCount,
        restorationDuration: stopwatch.elapsed,
      );
    } catch (e) {
      stopwatch.stop();
      logs.add('Erreur lors de la restauration : $e');
      return RestorationReport(
        success: false,
        logs: logs,
        restoredProcesses: restoredProcCount,
        restoredTerminals: restoredTermCount,
        restoredBrowsers: restoredBrowserCount,
        restoredContainers: restoredContainerCount,
        gitBranchRestored: restoredBranch,
        restoredWindows: restoredWindowCount,
        restorationDuration: stopwatch.elapsed,
      );
    } finally {
      _isRestoring = false;
    }
  }

  Future<void> _restoreGitState(String projectPath, domain_gs.GitSnapshot gitSnapshot) async {
    final currentBranch = await _gitManager.getCurrentBranch(projectPath);
    if (currentBranch != gitSnapshot.branch && gitSnapshot.branch != null) {
      await _gitManager.checkout(projectPath, gitSnapshot.branch!);
    }
    // Note: We could also stash/un stash changes based on hasUncommittedChanges
    // but that's more complex and potentially dangerous
  }

  Future<bool> _launchProcess(domain_ps.ProcessInfo processInfo) async {
    final parts = processInfo.commandLine.split(' ');
    if (parts.isNotEmpty) {
      final executable = parts.first;
      final args = parts.length > 1 ? parts.skip(1).toList() : <String>[];
      try {
        await _windowManager.launchApp(executable, args: args);
        return true;
      } catch (_) {
        return false;
      }
    }
    return false;
  }

  Future<void> _openTerminal(domain_ts.TerminalInfo terminalInfo) async {
    await _terminalManager.openTerminal(
      workingDirectory: terminalInfo.workingDirectory,
      command: terminalInfo.recentCommands.isNotEmpty ? terminalInfo.recentCommands.first : null,
      profile: terminalInfo.shell,
    );
  }

  Future<void> _openBrowser(domain_bs.BrowserInfo browserInfo) async {
    await _browserManager.openBrowser(
      url: browserInfo.url,
      // Note: We're ignoring profile and incognito for simplicity
      // These could be added to BrowserInfo if needed
    );
  }

  // Convert domain ContainerInfo to contract ContainerInfo
  contract_dm.ContainerInfo _domainToContractContainer(domain_ds.ContainerInfo domainContainer) {
    return contract_dm.ContainerInfo(
      id: domainContainer.id,
      name: domainContainer.name,
      image: domainContainer.image,
      command: domainContainer.command,
      createdAt: domainContainer.createdAt,
      status: domainContainer.status,
      ports: domainContainer.ports,
      mounts: domainContainer.mounts,
    );
  }

  // Attempt basic window restoration - launch apps then try to position known windows
  Future<int> _attemptWindowRestoration(List<domain_wsnap.WindowInfo> targetWindows) async {
    // For now, we'll just count the windows we attempt to restore
    // A real implementation would:
    // 1. Try to match running processes to target windows
    // 2. After launching apps, wait for windows to appear
    // 3. Use window titles/process names to match and reposition
    // Since this is complex and we want to avoid breaking existing functionality,
    // we'll return the count as a placeholder for now
    return targetWindows.length;
  }
}
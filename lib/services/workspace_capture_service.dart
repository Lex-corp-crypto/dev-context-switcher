import 'dart:async';
import '../../platform/factory/platform_factory.dart';
import '../../platform/contracts/window_manager.dart' as contract_wm;
import '../../platform/contracts/process_manager.dart' as contract_pm;
import '../../platform/contracts/terminal_manager.dart' as contract_tm;
import '../../platform/contracts/browser_manager.dart' as contract_bm;
import '../../platform/contracts/git_manager.dart' as contract_gm;
import '../../platform/contracts/docker_manager.dart' as contract_dm;
import '../../domain/entities/workspace.dart' as domain_ws;
import '../../domain/entities/window_snapshot.dart' as domain_wsnap;
import '../../domain/entities/process_snapshot.dart' as domain_psnap;
import '../../domain/entities/terminal_snapshot.dart' as domain_tsnap;
import '../../domain/entities/browser_snapshot.dart' as domain_bsnap;
import '../../domain/entities/git_snapshot.dart' as domain_gsnap;
import '../../domain/entities/docker_snapshot.dart' as domain_dsnap;
import '../../domain/entities/project_detection.dart' as domain_pdetect;
import '../../domain/entities/workspace_task.dart';
import 'project_detector_service.dart';

class WorkspaceCaptureService {
  final contract_wm.WindowManager _windowManager;
  final contract_pm.ProcessManager _processManager;
  final contract_tm.TerminalManager _terminalManager;
  final contract_bm.BrowserManager _browserManager;
  final contract_gm.GitManager _gitManager;
  final contract_dm.DockerManager _dockerManager;
  final ProjectDetectorService _projectDetector;
  bool _isCapturing = false;

  WorkspaceCaptureService({
    contract_wm.WindowManager? windowManager,
    contract_pm.ProcessManager? processManager,
    contract_tm.TerminalManager? terminalManager,
    contract_bm.BrowserManager? browserManager,
    contract_gm.GitManager? gitManager,
    contract_dm.DockerManager? dockerManager,
    ProjectDetectorService? projectDetector,
  })  : _windowManager = windowManager ?? PlatformFactory.createWindowManager(),
        _processManager = processManager ?? PlatformFactory.createProcessManager(),
        _terminalManager = terminalManager ?? PlatformFactory.createTerminalManager(),
        _browserManager = browserManager ?? PlatformFactory.createBrowserManager(),
        _gitManager = gitManager ?? PlatformFactory.createGitManager(),
        _dockerManager = dockerManager ?? PlatformFactory.createDockerManager(),
        _projectDetector = projectDetector ?? ProjectDetectorService();

  bool get isCapturing => _isCapturing;

  /// Inspect the current system state for capture preview
  Future<Map<String, dynamic>> inspectCurrentState(String? projectPath) async {
    if (_isCapturing) {
      throw StateError('Capture already in progress');
    }
    _isCapturing = true;
    try {
      final stopwatch = Stopwatch()..start();

      final windows = await _windowManager.listWindows().timeout(const Duration(seconds: 10));
      final processes = await _processManager.listDevProcesses().timeout(const Duration(seconds: 10));
      final terminals = await _terminalManager.listTerminals().timeout(const Duration(seconds: 5));
      final browsers = await _browserManager.listOpenTabs().timeout(const Duration(seconds: 5));
      final containers = await _dockerManager.listRunning().timeout(const Duration(seconds: 10));
      final gitState = await _getGitState(projectPath);
      final projectDetection = projectPath != null ? await _detectProject(projectPath) : null;

      stopwatch.stop();

      return {
        'windows': windows.map(_contractWindowToDomainWindow).toList(),
        'processes': processes.map(_contractProcessToDomainProcess).toList(),
        'terminals': terminals.map(_contractTerminalToDomainTerminal).toList(),
        'browsers': browsers.map(_contractBrowserToDomainBrowser).toList(),
        'containers': containers.map(_contractContainerToDomainContainer).toList(),
        'gitState': gitState,
        'projectDetection': projectDetection,
        'captureDurationMs': stopwatch.elapsedMilliseconds,
      };
    } finally {
      _isCapturing = false;
    }
  }

  Future<domain_ws.Workspace> captureWorkspace({
    required String name,
    String? projectPath,
    List<String> tags = const [],
    List<domain_wsnap.WindowInfo>? selectedWindows,
    List<domain_psnap.ProcessInfo>? selectedProcesses,
    List<domain_tsnap.TerminalInfo>? selectedTerminals,
    List<domain_bsnap.BrowserInfo>? selectedBrowsers,
    List<domain_dsnap.ContainerInfo>? selectedContainers,
    domain_gsnap.GitSnapshot? customGitSnapshot,
    List<WorkspaceTask> tasks = const [],
    String? notes,
    bool isFavorite = false,
    String? colorHex,
    String? iconName,
    List<String> startupCommands = const [],
    Map<String, String> envVars = const {},
    Duration timeout = const Duration(seconds: 30),
  }) async {
    if (_isCapturing) {
      throw StateError('Capture already in progress');
    }
    _isCapturing = true;
    try {
      final stopwatch = Stopwatch()..start();

      // 1. Windows
      final domainWindows = selectedWindows ??
          (await _windowManager.listWindows().timeout(timeout))
              .map<domain_wsnap.WindowInfo>(_contractWindowToDomainWindow)
              .toList();

      // 2. Processes
      final domainProcesses = selectedProcesses ??
          (await _processManager.listDevProcesses().timeout(timeout))
              .map<domain_psnap.ProcessInfo>(_contractProcessToDomainProcess)
              .toList();

      // 3. Terminals
      final domainTerminals = selectedTerminals ??
          (await _terminalManager.listTerminals().timeout(timeout))
              .map<domain_tsnap.TerminalInfo>(_contractTerminalToDomainTerminal)
              .toList();

      // 4. Browsers
      final domainBrowsers = selectedBrowsers ??
          (await _browserManager.listOpenTabs().timeout(timeout))
              .map<domain_bsnap.BrowserInfo>(_contractBrowserToDomainBrowser)
              .toList();

      // 5. Docker Containers
      final domainContainers = selectedContainers ??
          (await _dockerManager.listRunning().timeout(timeout))
              .map<domain_dsnap.ContainerInfo>(_contractContainerToDomainContainer)
              .toList();

      // 6. Git State
      domain_gsnap.GitSnapshot? gitSnapshot = customGitSnapshot;
      if (gitSnapshot == null && projectPath != null && projectPath.isNotEmpty) {
        final gitState = await _getGitState(projectPath);
        if (gitState != null) {
          gitSnapshot = domain_gsnap.GitSnapshot(
            branch: gitState['branch'],
            commitHash: gitState['commitHash'],
            hasUncommittedChanges: gitState['hasUncommittedChanges'] ?? false,
            recentBranches: gitState['recentBranches'] ?? [],
          );
        }
      }

      // 7. Project Detection
      final projectDetection = await _detectProject(projectPath);

      // Build workspace entity
      final workspace = domain_ws.Workspace(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        projectPath: projectPath,
        tags: tags,
        createdAt: DateTime.now(),
        windows: domain_wsnap.WindowSnapshot(windows: domainWindows),
        processes: domain_psnap.ProcessSnapshot(processes: domainProcesses),
        terminals: domain_tsnap.TerminalSnapshot(terminals: domainTerminals),
        browsers: domain_bsnap.BrowserSnapshot(browsers: domainBrowsers),
        git: gitSnapshot,
        docker: domainContainers.isNotEmpty
            ? domain_dsnap.DockerSnapshot(
                containers: domainContainers,
                images: const [],
              )
            : null,
        projectDetection: projectDetection,
        tasks: tasks,
        notes: notes,
        isFavorite: isFavorite,
        colorHex: colorHex,
        iconName: iconName,
        startupCommands: startupCommands,
        envVars: envVars,
      );

      stopwatch.stop();
      // In a real app, we might log or emit metrics here
      // For now, we just return the workspace with timing info available if needed

      return workspace;
    } on TimeoutException catch (_) {
      throw TimeoutException('Workspace capture timed out after ${timeout.inSeconds} seconds');
    } finally {
      _isCapturing = false;
    }
  }

  // Conversion functions
  domain_wsnap.WindowInfo _contractWindowToDomainWindow(contract_wm.WindowInfo contractWindow) {
    return domain_wsnap.WindowInfo(
      id: contractWindow.id,
      title: contractWindow.title,
      appName: contractWindow.appName,
      executablePath: contractWindow.executablePath,
      bounds: contractWindow.bounds,
      isMinimized: contractWindow.isMinimized,
      isFocused: contractWindow.isFocused,
      monitorIndex: contractWindow.monitorIndex,
      args: const [],
    );
  }

  domain_psnap.ProcessInfo _contractProcessToDomainProcess(contract_pm.ProcessInfo contractProcess) {
    return domain_psnap.ProcessInfo(
      pid: contractProcess.pid,
      name: contractProcess.name,
      commandLine: contractProcess.commandLine,
      memoryUsage: contractProcess.memoryUsage,
      cpuUsage: contractProcess.cpuUsage,
    );
  }

  domain_tsnap.TerminalInfo _contractTerminalToDomainTerminal(contract_tm.TerminalInfo contractTerminal) {
    return domain_tsnap.TerminalInfo(
      id: contractTerminal.id,
      workingDirectory: contractTerminal.workingDirectory,
      shell: contractTerminal.shell,
      recentCommands: contractTerminal.recentCommands,
      title: contractTerminal.title,
    );
  }

  domain_bsnap.BrowserInfo _contractBrowserToDomainBrowser(contract_bm.BrowserInfo contractBrowser) {
    return domain_bsnap.BrowserInfo(
      id: contractBrowser.id,
      url: contractBrowser.url,
      title: contractBrowser.title,
      browserName: contractBrowser.browserName,
    );
  }

  domain_dsnap.ContainerInfo _contractContainerToDomainContainer(contract_dm.ContainerInfo contractContainer) {
    return domain_dsnap.ContainerInfo(
      id: contractContainer.id,
      name: contractContainer.name,
      image: contractContainer.image,
      command: contractContainer.command,
      createdAt: contractContainer.createdAt,
      status: contractContainer.status,
      ports: contractContainer.ports,
      mounts: contractContainer.mounts,
    );
  }

  Future<Map<String, dynamic>?> _getGitState(String? projectPath) async {
    if (projectPath == null || projectPath.isEmpty) {
      return null;
    }

    try {
      final branch = await _gitManager.getCurrentBranch(projectPath).timeout(const Duration(seconds: 5));
      final hasUncommittedChanges = await _gitManager.hasUncommittedChanges(projectPath).timeout(const Duration(seconds: 5));
      final recentBranches = await _gitManager.getRecentBranches(projectPath, limit: 10).timeout(const Duration(seconds: 5));
      final commitHash = await _gitManager.getCommitHash(projectPath).timeout(const Duration(seconds: 5));
      final uncommittedCount = await _gitManager.getUncommittedCount(projectPath).timeout(const Duration(seconds: 5));

      return {
        'branch': branch,
        'commitHash': commitHash,
        'hasUncommittedChanges': hasUncommittedChanges,
        'recentBranches': recentBranches,
        'uncommittedCount': uncommittedCount,
      };
    } catch (e) {
      // If git operations fail, return null to indicate no git state
      return null;
    }
  }

  Future<domain_pdetect.ProjectDetection?> _detectProject(String? projectPath) async {
    if (projectPath == null || projectPath.isEmpty) {
      return null;
    }

    final detection = await _projectDetector.detect(projectPath);
    if (detection == null) {
      return null;
    }

    return domain_pdetect.ProjectDetection(
      projectPath: detection.projectPath,
      projectType: detection.projectType,
      detectedBy: detection.detectedBy,
      environmentVariables: detection.environmentVariables,
      dependencies: detection.dependencies,
    );
  }
}
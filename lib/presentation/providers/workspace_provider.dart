import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/workspace.dart';
import '../../domain/entities/window_snapshot.dart';
import '../../domain/entities/process_snapshot.dart';
import '../../domain/entities/terminal_snapshot.dart';
import '../../domain/entities/browser_snapshot.dart';
import '../../domain/entities/docker_snapshot.dart';
import '../../domain/entities/git_snapshot.dart';
import '../../data/models/workspace_model.dart';
import '../../data/repositories/workspace_repository_impl.dart';
import '../../services/workspace_capture_service.dart';
import '../../services/workspace_restoration_service.dart';

// Dependency injection providers
final workspaceRepositoryProvider = Provider<WorkspaceRepositoryImpl>((ref) {
  return WorkspaceRepositoryImpl();
});

final captureServiceProvider = Provider<WorkspaceCaptureService>((ref) {
  return WorkspaceCaptureService();
});

final restorationServiceProvider = Provider<WorkspaceRestorationService>((ref) {
  return WorkspaceRestorationService();
});

// Search & Tag Filter state providers
final searchQueryProvider = StateProvider<String>((ref) => '');
final selectedTagFilterProvider = StateProvider<String?>((ref) => null);

// Main Workspace state notifier
final workspaceProvider = StateNotifierProvider<WorkspaceNotifier, AsyncValue<List<Workspace>>>((ref) {
  final repo = ref.watch(workspaceRepositoryProvider);
  final capture = ref.watch(captureServiceProvider);
  final restore = ref.watch(restorationServiceProvider);
  return WorkspaceNotifier(repo, capture, restore);
});

// Filtered workspaces selector
final filteredWorkspacesProvider = Provider<List<Workspace>>((ref) {
  final workspacesAsync = ref.watch(workspaceProvider);
  final query = ref.watch(searchQueryProvider).trim().toLowerCase();
  final tagFilter = ref.watch(selectedTagFilterProvider);

  return workspacesAsync.maybeWhen(
    data: (workspaces) {
      return workspaces.where((ws) {
        final matchesQuery = query.isEmpty ||
            ws.name.toLowerCase().contains(query) ||
            (ws.projectPath?.toLowerCase().contains(query) ?? false) ||
            ws.tags.any((t) => t.toLowerCase().contains(query));

        final matchesTag = tagFilter == null || ws.tags.contains(tagFilter);

        return matchesQuery && matchesTag;
      }).toList();
    },
    orElse: () => [],
  );
});

// All unique tags provider
final allTagsProvider = Provider<List<String>>((ref) {
  final workspacesAsync = ref.watch(workspaceProvider);
  return workspacesAsync.maybeWhen(
    data: (workspaces) {
      final tags = <String>{};
      for (final ws in workspaces) {
        tags.addAll(ws.tags);
      }
      return tags.toList()..sort();
    },
    orElse: () => [],
  );
});

class WorkspaceNotifier extends StateNotifier<AsyncValue<List<Workspace>>> {
  final WorkspaceRepositoryImpl _repository;
  final WorkspaceCaptureService _captureService;
  final WorkspaceRestorationService _restorationService;

  WorkspaceNotifier(this._repository, this._captureService, this._restorationService)
      : super(const AsyncValue.loading()) {
    loadWorkspaces();
  }

  Future<void> loadWorkspaces() async {
    state = const AsyncValue.loading();
    try {
      final list = await _repository.getAll();
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<Workspace?> capture({
    required String name,
    String? projectPath,
    List<String> tags = const [],
    List<WindowInfo>? selectedWindows,
    List<ProcessInfo>? selectedProcesses,
    List<TerminalInfo>? selectedTerminals,
    List<BrowserInfo>? selectedBrowsers,
    List<ContainerInfo>? selectedContainers,
    GitSnapshot? gitSnapshot,
  }) async {
    try {
      final workspace = await _captureService.captureWorkspace(
        name: name,
        projectPath: projectPath,
        tags: tags,
        selectedWindows: selectedWindows,
        selectedProcesses: selectedProcesses,
        selectedTerminals: selectedTerminals,
        selectedBrowsers: selectedBrowsers,
        selectedContainers: selectedContainers,
        customGitSnapshot: gitSnapshot,
      );

      await _repository.save(workspace);
      final currentList = state.value ?? [];
      state = AsyncValue.data([workspace, ...currentList.where((w) => w.id != workspace.id)]);
      return workspace;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<RestorationReport> restore(String workspaceId, {RestoreOptions options = const RestoreOptions()}) async {
    final currentList = state.value ?? [];
    final workspace = currentList.firstWhere(
      (w) => w.id == workspaceId,
      orElse: () => throw Exception('Workspace not found'),
    );

    final report = await _restorationService.restoreWorkspaceWithReport(workspace, options: options);
    if (report.success) {
      await _repository.markAsRestored(workspaceId);
      final updatedList = currentList.map((w) {
        if (w.id == workspaceId) {
          return w.copyWith(lastRestoredAt: DateTime.now());
        }
        return w;
      }).toList();
      state = AsyncValue.data(updatedList);
    }
    return report;
  }

  Future<void> delete(String workspaceId) async {
    try {
      await _repository.delete(workspaceId);
      final currentList = state.value ?? [];
      state = AsyncValue.data(currentList.where((w) => w.id != workspaceId).toList());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> update(Workspace updated) async {
    try {
      await _repository.update(updated);
      final currentList = state.value ?? [];
      state = AsyncValue.data(currentList.map((w) => w.id == updated.id ? updated : w).toList());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<Workspace?> duplicate(String workspaceId) async {
    final currentList = state.value ?? [];
    final original = currentList.firstWhere((w) => w.id == workspaceId, orElse: () => throw Exception('Not found'));
    final duplicate = original.copyWith(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: '${original.name} (Copy)',
      createdAt: DateTime.now(),
      lastRestoredAt: null,
    );
    await _repository.save(duplicate);
    state = AsyncValue.data([duplicate, ...currentList]);
    return duplicate;
  }

  String exportToJson(String workspaceId) {
    final currentList = state.value ?? [];
    final workspace = currentList.firstWhere((w) => w.id == workspaceId);
    final model = WorkspaceModel.fromEntity(workspace);
    return const JsonEncoder.withIndent('  ').convert(model.toJson());
  }

  Future<Workspace> importFromJson(String jsonContent) async {
    final Map<String, dynamic> json = jsonDecode(jsonContent);
    // Assign new ID to prevent collisions
    json['id'] = DateTime.now().millisecondsSinceEpoch.toString();
    json['name'] = '${json['name'] ?? 'Imported'} (Imported)';
    json['createdAt'] = DateTime.now().toIso8601String();
    final model = WorkspaceModel.fromJson(json);
    final entity = model.toEntity();
    await _repository.save(entity);
    final currentList = state.value ?? [];
    state = AsyncValue.data([entity, ...currentList]);
    return entity;
  }
}

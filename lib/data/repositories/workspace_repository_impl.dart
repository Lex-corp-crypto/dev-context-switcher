import 'dart:convert';
import 'dart:io';

import '../../../domain/entities/workspace.dart';
import '../../../domain/repositories/workspace_repository.dart';
import '../models/workspace_model.dart';

class WorkspaceRepositoryImpl implements WorkspaceRepository {
  final String _workspaceFilePath;

  WorkspaceRepositoryImpl([String? workspaceFilePath])
      : _workspaceFilePath = workspaceFilePath ?? _defaultWorkspacePath();

  static String _defaultWorkspacePath() {
    final home = Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
    if (home != null && home.isNotEmpty) {
      return '$home/.config/dev_context_switcher/workspaces';
    }
    return '${Directory.current.path}/workspaces';
  }

  @override
  Future<void> save(Workspace workspace) async {
    try {
      final file = File('$_workspaceFilePath/workspace_${workspace.id}.json');
      await file.create(recursive: true);
      final json = WorkspaceModel.fromEntity(workspace).toJson();
      await file.writeAsString(jsonEncode(json));
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<Workspace?> getById(String id) async {
    try {
      final file = File('$_workspaceFilePath/workspace_$id.json');
      if (!await file.exists()) return null;
      final json = jsonDecode(await file.readAsString());
      return WorkspaceModel.fromJson(json).toEntity();
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<Workspace>> getAll() async {
    try {
      final dir = Directory(_workspaceFilePath);
      if (!await dir.exists()) return [];
      final entities = await dir.list().where((entity) =>
          entity is File && entity.path.endsWith('.json')).toList();
      final workspaces = <Workspace>[];
      for (final entity in entities) {
        try {
          final file = entity as File;
          final json = jsonDecode(await file.readAsString());
          final workspace = WorkspaceModel.fromJson(json).toEntity();
          workspaces.add(workspace);
        } catch (_) {}
      }
      // Sort newest first
      workspaces.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return workspaces;
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> delete(String id) async {
    try {
      final file = File('$_workspaceFilePath/workspace_$id.json');
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
  }

  @override
  Future<void> update(Workspace workspace) async {
    await save(workspace);
  }

  @override
  Future<void> markAsRestored(String id) async {
    final workspace = await getById(id);
    if (workspace != null) {
      final updated = workspace.copyWith(
        lastRestoredAt: DateTime.now(),
        restoreCount: workspace.restoreCount + 1,
      );
      await update(updated);
    }
  }
}

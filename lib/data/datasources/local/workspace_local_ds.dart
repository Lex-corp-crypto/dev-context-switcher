import 'dart:convert';
import 'dart:io';

import '../../../domain/entities/workspace.dart';
import '../../../domain/repositories/workspace_repository.dart';
import '../../models/workspace_model.dart';

class WorkspaceLocalDs implements WorkspaceRepository {
  final String _workspaceFilePath;

  WorkspaceLocalDs(this._workspaceFilePath);

  @override
  Future<void> save(Workspace workspace) async {
    final file = File('$_workspaceFilePath/workspace_${workspace.id}.json');
    await file.create(recursive: true);
    final json = WorkspaceModel.fromEntity(workspace).toJson();
    await file.writeAsString(jsonEncode(json));
  }

  @override
  Future<Workspace?> getById(String id) async {
    final file = File('$_workspaceFilePath/workspace_$id.json');
    if (!await file.exists()) return null;
    final json = jsonDecode(await file.readAsString());
    return WorkspaceModel.fromJson(json).toEntity();
  }

  @override
  Future<List<Workspace>> getAll() async {
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
      } catch (e) {
        // Skip invalid files
      }
    }
    return workspaces;
  }

  @override
  Future<void> delete(String id) async {
    final file = File('$_workspaceFilePath/workspace_$id.json');
    if (await file.exists()) {
      await file.delete();
    }
  }

  @override
  Future<void> update(Workspace workspace) async {
    await save(workspace); // For simplicity, we just save again
  }

  @override
  Future<void> markAsRestored(String id) async {
    // We could add a restoredAt field to the workspace, but for simplicity,
    // we'll just update the workspace with a tag or something.
    final workspace = await getById(id);
    if (workspace != null) {
      final updated = workspace.copyWith(
        tags: [...workspace.tags, 'restored:${DateTime.now().toIso8601String()}'],
      );
      await update(updated);
    }
  }
}

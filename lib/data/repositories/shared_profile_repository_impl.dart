import 'dart:convert';
import 'dart:io';

import '../../../domain/entities/workspace.dart';
import '../../../domain/repositories/shared_profile_repository.dart';
import '../models/workspace_model.dart';

class SharedProfileRepositoryImpl implements SharedProfileRepository {
  final String _sharedProfileFilePath;

  SharedProfileRepositoryImpl([String? sharedProfileFilePath])
      : _sharedProfileFilePath = sharedProfileFilePath ?? _defaultSharedPath();

  static String _defaultSharedPath() {
    final home = Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
    if (home != null && home.isNotEmpty) {
      return '$home/.config/dev_context_switcher/shared_profiles';
    }
    return '${Directory.current.path}/shared_profiles';
  }

  @override
  Future<void> saveWorkspace(Workspace workspace) async {
    try {
      final file = File('$_sharedProfileFilePath/workspace_${workspace.id}.json');
      await file.create(recursive: true);
      final json = WorkspaceModel.fromEntity(workspace).toJson();
      await file.writeAsString(jsonEncode(json));
    } catch (_) {}
  }

  @override
  Future<Workspace?> loadWorkspace(String id) async {
    try {
      final file = File('$_sharedProfileFilePath/workspace_$id.json');
      if (!await file.exists()) return null;
      final json = jsonDecode(await file.readAsString());
      return WorkspaceModel.fromJson(json).toEntity();
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<Workspace>> getAllSharedWorkspaces() async {
    try {
      final dir = Directory(_sharedProfileFilePath);
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
      return workspaces;
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> deleteWorkspace(String id) async {
    try {
      final file = File('$_sharedProfileFilePath/workspace_$id.json');
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
  }
}

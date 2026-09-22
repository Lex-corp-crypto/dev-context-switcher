import '../entities/workspace.dart';

abstract class WorkspaceRepository {
  Future<void> save(Workspace workspace);
  Future<Workspace?> getById(String id);
  Future<List<Workspace>> getAll();
  Future<void> delete(String id);
  Future<void> update(Workspace workspace);
  Future<void> markAsRestored(String id);
}

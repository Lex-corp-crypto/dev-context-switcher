import '../entities/workspace.dart';

abstract class SharedProfileRepository {
  Future<void> saveWorkspace(Workspace workspace);
  Future<Workspace?> loadWorkspace(String id);
  Future<List<Workspace>> getAllSharedWorkspaces();
  Future<void> deleteWorkspace(String id);
}

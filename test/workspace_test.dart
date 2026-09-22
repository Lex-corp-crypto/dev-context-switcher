import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:dev_context_switcher/services/project_detector_service.dart';
import 'package:dev_context_switcher/services/workspace_restoration_service.dart';
import 'package:dev_context_switcher/domain/entities/workspace.dart';
import 'package:dev_context_switcher/domain/entities/window_snapshot.dart';
import 'package:dev_context_switcher/domain/entities/process_snapshot.dart';
import 'package:dev_context_switcher/domain/entities/terminal_snapshot.dart';
import 'package:dev_context_switcher/domain/entities/browser_snapshot.dart';
import 'package:dev_context_switcher/data/models/workspace_model.dart';
import 'package:dev_context_switcher/data/repositories/workspace_repository_impl.dart';

void main() {
  group('ProjectDetectorService Tests', () {
    test('detects Flutter project from current directory', () async {
      final detector = ProjectDetectorService();
      final result = await detector.detect(Directory.current.path);

      expect(result, isNotNull);
      expect(result!.projectType, equals('flutter'));
      expect(result.detectedBy, equals('pubspec.yaml'));
      expect(result.dependencies, contains('equatable'));
    });

    test('returns null for non-existent directory', () async {
      final detector = ProjectDetectorService();
      final result = await detector.detect('/path/that/does/not/exist/anywhere');
      expect(result, isNull);
    });
  });

  group('WorkspaceModel and Serialization Tests', () {
    test('converts entity to model and back accurately', () {
      final now = DateTime.now();
      final original = Workspace(
        id: 'test-123',
        name: 'Backend API Context',
        projectPath: '/home/user/backend',
        tags: const ['backend', 'api'],
        createdAt: now,
        windows: const WindowSnapshot(windows: []),
        processes: const ProcessSnapshot(processes: [
          ProcessInfo(pid: 1234, name: 'node', commandLine: 'node server.js'),
        ]),
        terminals: const TerminalSnapshot(terminals: [
          TerminalInfo(id: 'term-1', workingDirectory: '/home/user/backend', shell: 'zsh'),
        ]),
        browsers: const BrowserSnapshot(browsers: [
          BrowserInfo(id: 'b1', url: 'http://localhost:8000', title: 'Localhost', browserName: 'chrome'),
        ]),
      );

      final model = WorkspaceModel.fromEntity(original);
      final json = model.toJson();
      final deserialized = WorkspaceModel.fromJson(json).toEntity();

      expect(deserialized.id, equals(original.id));
      expect(deserialized.name, equals(original.name));
      expect(deserialized.projectPath, equals(original.projectPath));
      expect(deserialized.tags, equals(original.tags));
      expect(deserialized.processes.processes.length, equals(1));
      expect(deserialized.terminals.terminals.length, equals(1));
      expect(deserialized.browsers.browsers.length, equals(1));
    });
  });

  group('WorkspaceRepositoryImpl Tests', () {
    late Directory tempDir;
    late WorkspaceRepositoryImpl repo;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('workspace_repo_test_');
      repo = WorkspaceRepositoryImpl(tempDir.path);
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('save, getById, getAll, markAsRestored, and delete', () async {
      final ws = Workspace(
        id: 'w-1',
        name: 'Test Workspace',
        createdAt: DateTime.now(),
        windows: const WindowSnapshot(windows: []),
        processes: const ProcessSnapshot(processes: []),
        terminals: const TerminalSnapshot(terminals: []),
        browsers: const BrowserSnapshot(browsers: []),
      );

      // Save
      await repo.save(ws);

      // GetById
      final fetched = await repo.getById('w-1');
      expect(fetched, isNotNull);
      expect(fetched!.name, equals('Test Workspace'));

      // GetAll
      final all = await repo.getAll();
      expect(all.length, equals(1));

      // Mark as restored
      await repo.markAsRestored('w-1');
      final restored = await repo.getById('w-1');
      expect(restored!.lastRestoredAt, isNotNull);

      // Delete
      await repo.delete('w-1');
      final afterDelete = await repo.getById('w-1');
      expect(afterDelete, isNull);
    });
  });

  group('WorkspaceRestorationService Tests', () {
    test('restores workspace and generates detailed report', () async {
      final ws = Workspace(
        id: 'w-restore',
        name: 'Restore Test Workspace',
        projectPath: Directory.current.path,
        createdAt: DateTime.now(),
        windows: const WindowSnapshot(windows: []),
        processes: const ProcessSnapshot(processes: []),
        terminals: const TerminalSnapshot(terminals: []),
        browsers: const BrowserSnapshot(browsers: []),
      );

      final service = WorkspaceRestorationService();
      final report = await service.restoreWorkspaceWithReport(ws);

      expect(report.success, isTrue);
      expect(report.logs, isNotEmpty);
      expect(report.logs.last, contains('Workspace restored successfully'));
    });
  });
}


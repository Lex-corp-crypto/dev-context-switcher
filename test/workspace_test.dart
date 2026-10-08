import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:dev_context_switcher/services/project_detector_service.dart';
import 'package:dev_context_switcher/services/workspace_restoration_service.dart';
import 'package:dev_context_switcher/domain/entities/workspace.dart';
import 'package:dev_context_switcher/domain/entities/workspace_task.dart';
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

    test('detects Rust project from temp directory with Cargo.toml', () async {
      final tempDir = await Directory.systemTemp.createTemp('rust_project_test_');
      try {
        final cargoFile = File('${tempDir.path}/Cargo.toml');
        await cargoFile.writeAsString('''
[package]
name = "hyper_service"
version = "0.1.0"

[dependencies]
serde = "1.0"
tokio = "1.0"
''');
        final detector = ProjectDetectorService();
        final result = await detector.detect(tempDir.path);

        expect(result, isNotNull);
        expect(result!.projectType, equals('rust'));
        expect(result.detectedBy, equals('Cargo.toml'));
        expect(result.dependencies, contains('serde'));
        expect(result.dependencies, contains('tokio'));
      } finally {
        await tempDir.delete(recursive: true);
      }
    });

    test('detects Python project from temp directory with requirements.txt', () async {
      final tempDir = await Directory.systemTemp.createTemp('python_project_test_');
      try {
        final reqFile = File('${tempDir.path}/requirements.txt');
        await reqFile.writeAsString('''
fastapi>=0.100.0
uvicorn==0.23.0
pydantic
''');
        final detector = ProjectDetectorService();
        final result = await detector.detect(tempDir.path);

        expect(result, isNotNull);
        expect(result!.projectType, equals('python'));
        expect(result.detectedBy, equals('requirements.txt'));
        expect(result.dependencies, contains('fastapi'));
        expect(result.dependencies, contains('uvicorn'));
      } finally {
        await tempDir.delete(recursive: true);
      }
    });

    test('returns null for non-existent directory', () async {
      final detector = ProjectDetectorService();
      final result = await detector.detect('/path/that/does/not/exist/anywhere');
      expect(result, isNull);
    });
  });

  group('WorkspaceTask Tests', () {
    test('creates, serializes, deserializes and toggles tasks accurately', () {
      final task = WorkspaceTask(
        id: 'task-1',
        title: 'Review pull request #42',
        isCompleted: false,
      );

      final json = task.toJson();
      final fromJson = WorkspaceTask.fromJson(json);

      expect(fromJson.id, equals('task-1'));
      expect(fromJson.title, equals('Review pull request #42'));
      expect(fromJson.isCompleted, isFalse);

      final completed = fromJson.copyWith(isCompleted: true);
      expect(completed.isCompleted, isTrue);
    });
  });

  group('WorkspaceModel and Serialization Tests', () {
    test('converts full entity to model and back with all ultimate properties', () {
      final now = DateTime.now();
      final original = Workspace(
        id: 'test-123',
        name: 'Backend API Context',
        projectPath: '/home/user/backend',
        tags: const ['backend', 'api'],
        createdAt: now,
        isFavorite: true,
        colorHex: 'FF4CAF50',
        notes: 'API server documentation: http://localhost:8000/docs',
        startupCommands: const ['npm run dev', 'docker compose up -d'],
        envVars: const {'PORT': '8000', 'NODE_ENV': 'development'},
        restoreCount: 5,
        tasks: [
          WorkspaceTask(id: 't1', title: 'Implement JWT Auth', isCompleted: true),
          WorkspaceTask(id: 't2', title: 'Write integration tests', isCompleted: false),
        ],
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
      expect(deserialized.isFavorite, isTrue);
      expect(deserialized.colorHex, equals('FF4CAF50'));
      expect(deserialized.notes, equals('API server documentation: http://localhost:8000/docs'));
      expect(deserialized.startupCommands.length, equals(2));
      expect(deserialized.envVars['PORT'], equals('8000'));
      expect(deserialized.restoreCount, equals(5));
      expect(deserialized.tasks.length, equals(2));
      expect(deserialized.tasks.first.isCompleted, isTrue);
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
      expect(fetched.restoreCount, equals(0));

      // GetAll
      final all = await repo.getAll();
      expect(all.length, equals(1));

      // Mark as restored
      await repo.markAsRestored('w-1');
      final restored = await repo.getById('w-1');
      expect(restored!.lastRestoredAt, isNotNull);
      expect(restored.restoreCount, equals(1));

      // Delete
      await repo.delete('w-1');
      final afterDelete = await repo.getById('w-1');
      expect(afterDelete, isNull);
    });
  });

  group('WorkspaceRestorationService Tests', () {
    test('restores workspace and generates detailed report with startup commands', () async {
      final ws = Workspace(
        id: 'w-restore',
        name: 'Restore Test Workspace',
        projectPath: Directory.current.path,
        createdAt: DateTime.now(),
        startupCommands: const ['echo "dev context ready"'],
        windows: const WindowSnapshot(windows: []),
        processes: const ProcessSnapshot(processes: []),
        terminals: const TerminalSnapshot(terminals: []),
        browsers: const BrowserSnapshot(browsers: []),
      );

      final service = WorkspaceRestorationService();
      final report = await service.restoreWorkspaceWithReport(ws);

      expect(report.success, isTrue);
      expect(report.logs, isNotEmpty);
      expect(report.executedStartupCommands, equals(1));
      expect(report.logs.last, contains('Workspace restored successfully'));
    });
  });
}

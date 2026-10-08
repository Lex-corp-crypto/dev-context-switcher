import 'dart:io';
import '../contracts/git_manager.dart';

class GitController implements GitManager {
  @override
  Future<String> getCurrentBranch(String projectPath) async {
    try {
      final result = await Process.run('git', ['rev-parse', '--abbrev-ref', 'HEAD'],
          workingDirectory: projectPath);
      return result.exitCode == 0 ? result.stdout.toString().trim() : '';
    } catch (_) {
      return '';
    }
  }

  @override
  Future<void> checkout(String projectPath, String branch) async {
    if (branch.isEmpty) return;
    try {
      await Process.run('git', ['checkout', branch],
          workingDirectory: projectPath);
    } catch (_) {}
  }

  @override
  Future<bool> hasUncommittedChanges(String projectPath) async {
    try {
      final result = await Process.run('git', ['diff-index', '--quiet', 'HEAD', '--'],
          workingDirectory: projectPath);
      return result.exitCode != 0;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<List<String>> getRecentBranches(String projectPath, {int limit = 10}) async {
    try {
      final result = await Process.run('git', ['for-each-ref', '--sort=-committerdate',
          '--format=%(refname:short)', 'refs/heads'],
          workingDirectory: projectPath);
      if (result.exitCode != 0) return [];
      final branches = result.stdout.toString().split('\n')
          .map((b) => b.trim())
          .where((branch) => branch.isNotEmpty)
          .take(limit)
          .toList();
      return branches;
    } catch (_) {
      return [];
    }
  }

  @override
  Future<String?> getCommitHash(String projectPath) async {
    try {
      final result = await Process.run(
        'git',
        ['rev-parse', '--short', 'HEAD'],
        workingDirectory: projectPath,
      );
      if (result.exitCode == 0) {
        final hash = result.stdout.toString().trim();
        return hash.isNotEmpty ? hash : null;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<int> getUncommittedCount(String projectPath) async {
    try {
      final result = await Process.run(
        'git',
        ['status', '--porcelain'],
        workingDirectory: projectPath,
      );
      if (result.exitCode == 0) {
        final lines = result.stdout.toString().trim().split('\n');
        return lines.where((l) => l.trim().isNotEmpty).length;
      }
      return 0;
    } catch (_) {
      return 0;
    }
  }
}

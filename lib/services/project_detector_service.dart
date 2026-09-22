import 'dart:io';
import '../domain/entities/project_detection.dart';

class ProjectDetectorService {
  Future<ProjectDetection?> detect(String directoryPath) async {
    final dir = Directory(directoryPath);
    if (!await dir.exists()) return null;

    String? projectType;
    String? detectedBy;
    final List<String> dependencies = [];
    final Map<String, String> envVars = {};

    // 1. Check for Flutter / Dart
    final pubspec = File('${dir.path}/pubspec.yaml');
    if (await pubspec.exists()) {
      projectType = 'flutter';
      detectedBy = 'pubspec.yaml';
      try {
        final lines = await pubspec.readAsLines();
        bool inDependencies = false;
        for (final line in lines) {
          final trimmed = line.trim();
          if (trimmed.startsWith('dependencies:')) {
            inDependencies = true;
            continue;
          }
          if (inDependencies && (line.startsWith('dev_dependencies:') || line.startsWith('flutter:'))) {
            inDependencies = false;
          }
          if (inDependencies && trimmed.isNotEmpty && !trimmed.startsWith('#') && trimmed.contains(':')) {
            final depName = trimmed.split(':').first.trim();
            if (depName != 'flutter' && depName != 'sdk') {
              dependencies.add(depName);
            }
          }
        }
      } catch (_) {}
    }

    // 2. Check for Node.js / TypeScript / React / Next.js
    final packageJson = File('${dir.path}/package.json');
    if (projectType == null && await packageJson.exists()) {
      projectType = 'node';
      detectedBy = 'package.json';
      try {
        final content = await packageJson.readAsString();
        if (content.contains('"next"')) {
          projectType = 'nextjs';
        } else if (content.contains('"react"')) {
          projectType = 'react';
        } else if (content.contains('"vue"')) {
          projectType = 'vue';
        } else if (content.contains('"@angular/core"')) {
          projectType = 'angular';
        }
        // Extract basic package names
        final depMatch = RegExp(r'"dependencies"\s*:\s*\{([^}]+)\}').firstMatch(content);
        if (depMatch != null) {
          final depBlock = depMatch.group(1) ?? '';
          for (final line in depBlock.split('\n')) {
            final m = RegExp(r'"([^"]+)"\s*:').firstMatch(line);
            if (m != null) dependencies.add(m.group(1)!);
          }
        }
      } catch (_) {}
    }

    // 3. Check for Python
    final pyproject = File('${dir.path}/pyproject.toml');
    final reqs = File('${dir.path}/requirements.txt');
    if (projectType == null && (await pyproject.exists() || await reqs.exists())) {
      projectType = 'python';
      detectedBy = await pyproject.exists() ? 'pyproject.toml' : 'requirements.txt';
      if (await reqs.exists()) {
        try {
          final lines = await reqs.readAsLines();
          for (final line in lines) {
            final trimmed = line.trim();
            if (trimmed.isNotEmpty && !trimmed.startsWith('#')) {
              dependencies.add(trimmed.split(RegExp(r'[==|>=|<=|<|>]')).first.trim());
            }
          }
        } catch (_) {}
      }
    }

    // 4. Check for Rust
    final cargo = File('${dir.path}/Cargo.toml');
    if (projectType == null && await cargo.exists()) {
      projectType = 'rust';
      detectedBy = 'Cargo.toml';
    }

    // 5. Check for Go
    final goMod = File('${dir.path}/go.mod');
    if (projectType == null && await goMod.exists()) {
      projectType = 'go';
      detectedBy = 'go.mod';
    }

    // 6. Check for Java / Kotlin
    final pom = File('${dir.path}/pom.xml');
    final gradle = File('${dir.path}/build.gradle');
    if (projectType == null && (await pom.exists() || await gradle.exists())) {
      projectType = 'java';
      detectedBy = await pom.exists() ? 'pom.xml' : 'build.gradle';
    }

    // 7. Check for Git repository
    final gitDir = Directory('${dir.path}/.git');
    if (await gitDir.exists() && projectType == null) {
      projectType = 'git';
      detectedBy = '.git';
    }

    if (projectType == null) return null;

    // Check for .env file
    final envFile = File('${dir.path}/.env');
    if (await envFile.exists()) {
      try {
        final lines = await envFile.readAsLines();
        for (final line in lines) {
          final trimmed = line.trim();
          if (trimmed.isNotEmpty && !trimmed.startsWith('#') && trimmed.contains('=')) {
            final parts = trimmed.split('=');
            envVars[parts[0].trim()] = parts.sublist(1).join('=').trim();
          }
        }
      } catch (_) {}
    }

    return ProjectDetection(
      projectType: projectType,
      projectPath: dir.path,
      detectedBy: detectedBy,
      environmentVariables: envVars,
      dependencies: dependencies.take(20).toList(),
    );
  }
}

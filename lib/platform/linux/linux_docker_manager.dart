import 'dart:convert';
import 'package:process_run/shell.dart';
import '../contracts/docker_manager.dart';

class LinuxDockerManager implements DockerManager {
  final _shell = Shell();

  @override
  Future<List<ContainerInfo>> listRunning() async {
    try {
      final result = await _shell.run('docker ps --format "{{json .}}"');
      final List<ContainerInfo> containers = [];

      final stdout = result.isNotEmpty ? result.first.stdout.toString() : '';
      final lines = stdout.split('\n');
      for (final line in lines) {
        final trimmed = line.trim();
        if (trimmed.isEmpty) continue;
        try {
          final Map<String, dynamic> data = jsonDecode(trimmed);
          final id = (data['ID'] ?? data['id'] ?? '').toString();
          final name = (data['Names'] ?? data['names'] ?? data['Name'] ?? 'container').toString();
          final image = (data['Image'] ?? data['image'] ?? '').toString();
          final command = (data['Command'] ?? data['command'] ?? '').toString();
          final status = (data['Status'] ?? data['status'] ?? 'running').toString();
          final portsStr = (data['Ports'] ?? data['ports'] ?? '').toString();
          final ports = portsStr.isNotEmpty ? portsStr.split(',').map((p) => p.trim()).toList() : <String>[];

          containers.add(ContainerInfo(
            id: id,
            name: name,
            image: image,
            command: command,
            createdAt: DateTime.now(),
            status: status,
            ports: ports,
            mounts: const [],
          ));
        } catch (_) {}
      }

      return containers;
    } catch (_) {
      // Docker not running or no permissions
      return [];
    }
  }

  @override
  Future<void> startCompose(List<ContainerInfo> containers) async {
    for (final c in containers) {
      if (c.id.isNotEmpty) {
        try {
          await _shell.run('docker start ${c.id}');
        } catch (_) {}
      }
    }
  }

  @override
  Future<void> stopAll() async {
    try {
      await _shell.run('docker stop \$(docker ps -q)');
    } catch (_) {}
  }
}


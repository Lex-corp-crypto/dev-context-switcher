import 'package:equatable/equatable.dart';

abstract class DockerManager {
  /// Liste les conteneurs en cours d'exécution
  Future<List<ContainerInfo>> listRunning();

  /// Démarre les conteneurs définis dans un fichier docker-compose.yml
  Future<void> startCompose(List<ContainerInfo> containers);

  /// Arrête les conteneurs en cours d'exécution
  Future<void> stopAll();
}

class ContainerInfo extends Equatable {
  final String id;
  final String name;
  final String image;
  final String command;
  final DateTime createdAt;
  final String status;
  final List<String> ports;
  final List<String> mounts;

  const ContainerInfo({
    required this.id,
    required this.name,
    required this.image,
    required this.command,
    required this.createdAt,
    required this.status,
    this.ports = const [],
    this.mounts = const [],
  });

  ContainerInfo copyWith({
    String? id,
    String? name,
    String? image,
    String? command,
    DateTime? createdAt,
    String? status,
    List<String>? ports,
    List<String>? mounts,
  }) {
    return ContainerInfo(
      id: id ?? this.id,
      name: name ?? this.name,
      image: image ?? this.image,
      command: command ?? this.command,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      ports: ports ?? this.ports,
      mounts: mounts ?? this.mounts,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    image,
    command,
    createdAt,
    status,
    ports,
    mounts,
  ];
}

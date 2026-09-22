import 'package:equatable/equatable.dart';

class DockerSnapshot extends Equatable {
  final List<ContainerInfo> containers;
  final List<ImageInfo> images;

  const DockerSnapshot({
    required this.containers,
    required this.images,
  });

  DockerSnapshot copyWith({
    List<ContainerInfo>? containers,
    List<ImageInfo>? images,
  }) {
    return DockerSnapshot(
      containers: containers ?? this.containers,
      images: images ?? this.images,
    );
  }

  Map<String, dynamic> toJson() => {
        'containers': containers.map((c) => c.toJson()).toList(),
        'images': images.map((i) => i.toJson()).toList(),
      };

  factory DockerSnapshot.fromJson(Map<String, dynamic> json) => DockerSnapshot(
        containers: List<ContainerInfo>.from(
            json['containers'].map((c) => ContainerInfo.fromJson(c))),
        images: List<ImageInfo>.from(
            json['images'].map((i) => ImageInfo.fromJson(i))),
      );

  @override
  List<Object?> get props => [
    containers,
    images,
  ];
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

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'image': image,
        'command': command,
        'createdAt': createdAt.toIso8601String(),
        'status': status,
        'ports': ports,
        'mounts': mounts,
      };

  factory ContainerInfo.fromJson(Map<String, dynamic> json) => ContainerInfo(
        id: json['id'],
        name: json['name'],
        image: json['image'],
        command: json['command'],
        createdAt: DateTime.parse(json['createdAt']),
        status: json['status'],
        ports: List<String>.from(json['ports']),
        mounts: List<String>.from(json['mounts']),
      );

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

class ImageInfo extends Equatable {
  final String id;
  final String repository;
  final String tag;
  final DateTime createdAt;
  final String size;

  const ImageInfo({
    required this.id,
    required this.repository,
    required this.tag,
    required this.createdAt,
    required this.size,
  });

  ImageInfo copyWith({
    String? id,
    String? repository,
    String? tag,
    DateTime? createdAt,
    String? size,
  }) {
    return ImageInfo(
      id: id ?? this.id,
      repository: repository ?? this.repository,
      tag: tag ?? this.tag,
      createdAt: createdAt ?? this.createdAt,
      size: size ?? this.size,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'repository': repository,
        'tag': tag,
        'createdAt': createdAt.toIso8601String(),
        'size': size,
      };

  factory ImageInfo.fromJson(Map<String, dynamic> json) => ImageInfo(
        id: json['id'],
        repository: json['repository'],
        tag: json['tag'],
        createdAt: DateTime.parse(json['createdAt']),
        size: json['size'],
      );

  @override
  List<Object?> get props => [
    id,
    repository,
    tag,
    createdAt,
    size,
  ];
}

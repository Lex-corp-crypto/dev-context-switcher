import '../contracts/docker_manager.dart';

class MacOSDockerManager implements DockerManager {
  @override
  Future<List<ContainerInfo>> listRunning() async {
    // TODO: Implement using Docker CLI
    return [];
  }

  @override
  Future<void> startCompose(List<ContainerInfo> containers) async {
    // TODO: Implement using docker-compose up
  }

  @override
  Future<void> stopAll() async {
    // TODO: Implement using docker stop
  }
}

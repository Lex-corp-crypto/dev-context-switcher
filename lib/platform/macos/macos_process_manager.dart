import '../contracts/process_manager.dart';

class MacOSProcessManager implements ProcessManager {
  @override
  Future<List<ProcessInfo>> listDevProcesses() async {
    // TODO: Implement using ps or Activity Monitor APIs
    return [];
  }

  @override
  Future<void> killProcess(int pid) async {
    // TODO: Implement using kill command
  }
}

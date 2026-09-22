import '../contracts/process_manager.dart';

class WinProcessManager implements ProcessManager {
  @override
  Future<List<ProcessInfo>> listDevProcesses() async {
    // TODO: Implement using WMI or PowerShell
    return [];
  }

  @override
  Future<void> killProcess(int pid) async {
    // TODO: Implement using taskkill
  }
}

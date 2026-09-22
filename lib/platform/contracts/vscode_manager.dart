abstract class VscodeManager {
  Future<void> openFolder(String folderPath);
  Future<void> openFile(String filePath, {int? line, int? column});
  Future<bool> isInstalled();
}

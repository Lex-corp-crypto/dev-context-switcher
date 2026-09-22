abstract class ClipboardManager {
  /// Copie du texte dans le presse-papiers
  Future<void> copyText(String text);

  /// Colle du texte depuis le presse-papiers
  Future<String> pasteText();
}

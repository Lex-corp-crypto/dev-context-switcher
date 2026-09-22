import 'dart:convert';
import 'dart:io';

import '../../../domain/entities/settings.dart';
import '../../../domain/repositories/settings_repository.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  final String _settingsFilePath;

  SettingsRepositoryImpl([String? settingsFilePath])
      : _settingsFilePath = settingsFilePath ?? _defaultSettingsPath();

  static String _defaultSettingsPath() {
    final home = Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
    if (home != null && home.isNotEmpty) {
      return '$home/.config/dev_context_switcher/settings.json';
    }
    return '${Directory.current.path}/settings.json';
  }

  @override
  Future<Settings> getSettings() async {
    try {
      final file = File(_settingsFilePath);
      if (!await file.exists()) {
        return const Settings();
      }
      final json = jsonDecode(await file.readAsString());
      return Settings.fromJson(json);
    } catch (_) {
      return const Settings();
    }
  }

  @override
  Future<void> saveSettings(Settings settings) async {
    try {
      final file = File(_settingsFilePath);
      await file.create(recursive: true);
      await file.writeAsString(jsonEncode(settings.toJson()));
    } catch (_) {}
  }
}

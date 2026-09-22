import 'dart:convert';
import 'dart:io';

import '../../../domain/entities/settings.dart';
import '../../../domain/repositories/settings_repository.dart';

class SettingsLocalDs implements SettingsRepository {
  final String _settingsFilePath;

  SettingsLocalDs(this._settingsFilePath);

  @override
  Future<Settings> getSettings() async {
    final file = File(_settingsFilePath);
    if (!await file.exists()) {
      // Return default settings
      return const Settings();
    }
    final json = jsonDecode(await file.readAsString());
    return Settings.fromJson(json);
  }

  @override
  Future<void> saveSettings(Settings settings) async {
    final file = File(_settingsFilePath);
    await file.create(recursive: true);
    await file.writeAsString(jsonEncode(settings.toJson()));
  }
}

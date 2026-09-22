import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/settings.dart';
import '../../data/repositories/settings_repository_impl.dart';

final settingsRepositoryProvider = Provider<SettingsRepositoryImpl>((ref) {
  return SettingsRepositoryImpl();
});

final settingsProvider = StateNotifierProvider<SettingsNotifier, Settings>((ref) {
  final repo = ref.watch(settingsRepositoryProvider);
  return SettingsNotifier(repo);
});

class SettingsNotifier extends StateNotifier<Settings> {
  final SettingsRepositoryImpl _repository;

  SettingsNotifier(this._repository) : super(const Settings()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final s = await _repository.getSettings();
    state = s;
  }

  Future<void> updateThemeMode(String themeMode) async {
    state = state.copyWith(themeMode: themeMode);
    await _repository.saveSettings(state);
  }

  Future<void> updateAutoDetect(bool autoDetect) async {
    state = state.copyWith(autoDetectProject: autoDetect);
    await _repository.saveSettings(state);
  }

  Future<void> updateGlobalHotkeys(bool enable) async {
    state = state.copyWith(enableGlobalHotkeys: enable);
    await _repository.saveSettings(state);
  }

  Future<void> updateAutoSaveShared(bool autoSave) async {
    state = state.copyWith(autoSaveToSharedProfile: autoSave);
    await _repository.saveSettings(state);
  }

  Future<void> updateStoragePath(String? path) async {
    state = state.copyWith(storagePath: path);
    await _repository.saveSettings(state);
  }
}

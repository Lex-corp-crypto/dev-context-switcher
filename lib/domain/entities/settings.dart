class Settings {
  final bool autoSaveToSharedProfile;
  final bool enableGlobalHotkeys;
  final String themeMode; // 'system', 'dark', 'light'
  final bool autoDetectProject;
  final String? storagePath;

  const Settings({
    this.autoSaveToSharedProfile = false,
    this.enableGlobalHotkeys = false,
    this.themeMode = 'dark',
    this.autoDetectProject = true,
    this.storagePath,
  });

  Settings copyWith({
    bool? autoSaveToSharedProfile,
    bool? enableGlobalHotkeys,
    String? themeMode,
    bool? autoDetectProject,
    String? storagePath,
  }) {
    return Settings(
      autoSaveToSharedProfile: autoSaveToSharedProfile ?? this.autoSaveToSharedProfile,
      enableGlobalHotkeys: enableGlobalHotkeys ?? this.enableGlobalHotkeys,
      themeMode: themeMode ?? this.themeMode,
      autoDetectProject: autoDetectProject ?? this.autoDetectProject,
      storagePath: storagePath ?? this.storagePath,
    );
  }

  factory Settings.fromJson(Map<String, dynamic> json) {
    return Settings(
      autoSaveToSharedProfile: json['autoSaveToSharedProfile'] ?? false,
      enableGlobalHotkeys: json['enableGlobalHotkeys'] ?? false,
      themeMode: json['themeMode'] ?? 'dark',
      autoDetectProject: json['autoDetectProject'] ?? true,
      storagePath: json['storagePath'],
    );
  }

  Map<String, dynamic> toJson() => {
        'autoSaveToSharedProfile': autoSaveToSharedProfile,
        'enableGlobalHotkeys': enableGlobalHotkeys,
        'themeMode': themeMode,
        'autoDetectProject': autoDetectProject,
        'storagePath': storagePath,
      };
}

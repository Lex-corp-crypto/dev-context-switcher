import 'package:equatable/equatable.dart';
import 'dart:ui';

class WindowSnapshot extends Equatable {
  final List<WindowInfo> windows;

  const WindowSnapshot({required this.windows});

  WindowSnapshot copyWith({List<WindowInfo>? windows}) {
    return WindowSnapshot(
      windows: windows ?? this.windows,
    );
  }

  Map<String, dynamic> toJson() => {
        'windows': windows.map((w) => w.toJson()).toList(),
      };

  factory WindowSnapshot.fromJson(Map<String, dynamic> json) => WindowSnapshot(
        windows: List<WindowInfo>.from(
            json['windows'].map((w) => WindowInfo.fromJson(w))),
      );

  @override
  List<Object?> get props => [windows];
}

class WindowInfo extends Equatable {
  final String id;
  final String title;
  final String appName;
  final String? executablePath;
  final Rect bounds;
  final bool isMinimized;
  final bool isFocused;
  final int? monitorIndex;
  final List<String> args; // Arguments used to launch the app

  const WindowInfo({
    required this.id,
    required this.title,
    required this.appName,
    this.executablePath,
    required this.bounds,
    required this.isMinimized,
    required this.isFocused,
    this.monitorIndex,
    this.args = const [],
  });

  WindowInfo copyWith({
    String? id,
    String? title,
    String? appName,
    String? executablePath,
    Rect? bounds,
    bool? isMinimized,
    bool? isFocused,
    int? monitorIndex,
    List<String>? args,
  }) {
    return WindowInfo(
      id: id ?? this.id,
      title: title ?? this.title,
      appName: appName ?? this.appName,
      executablePath: executablePath ?? this.executablePath,
      bounds: bounds ?? this.bounds,
      isMinimized: isMinimized ?? this.isMinimized,
      isFocused: isFocused ?? this.isFocused,
      monitorIndex: monitorIndex ?? this.monitorIndex,
      args: args ?? this.args,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'appName': appName,
        'executablePath': executablePath,
        'bounds': {
          'left': bounds.left,
          'top': bounds.top,
          'right': bounds.right,
          'bottom': bounds.bottom,
        },
        'isMinimized': isMinimized,
        'isFocused': isFocused,
        'monitorIndex': monitorIndex,
        'args': args,
      };

  factory WindowInfo.fromJson(Map<String, dynamic> json) => WindowInfo(
        id: json['id'],
        title: json['title'],
        appName: json['appName'],
        executablePath: json['executablePath'],
        bounds: Rect.fromLTRB(
          json['bounds']['left'],
          json['bounds']['top'],
          json['bounds']['right'],
          json['bounds']['bottom'],
        ),
        isMinimized: json['isMinimized'],
        isFocused: json['isFocused'],
        monitorIndex: json['monitorIndex'],
        args: List<String>.from(json['args']),
      );

  @override
  List<Object?> get props => [
    id,
    title,
    appName,
    executablePath,
    bounds,
    isMinimized,
    isFocused,
    monitorIndex,
    args,
  ];
}

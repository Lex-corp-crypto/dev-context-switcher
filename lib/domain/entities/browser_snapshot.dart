import 'package:equatable/equatable.dart';

class BrowserSnapshot extends Equatable {
  final List<BrowserInfo> browsers;

  const BrowserSnapshot({required this.browsers});

  BrowserSnapshot copyWith({List<BrowserInfo>? browsers}) {
    return BrowserSnapshot(
      browsers: browsers ?? this.browsers,
    );
  }

  Map<String, dynamic> toJson() => {
        'browsers': browsers.map((b) => b.toJson()).toList(),
      };

  factory BrowserSnapshot.fromJson(Map<String, dynamic> json) => BrowserSnapshot(
        browsers: List<BrowserInfo>.from(
            json['browsers'].map((b) => BrowserInfo.fromJson(b))),
      );

  @override
  List<Object?> get props => [browsers];
}

class BrowserInfo extends Equatable {
  final String id;
  final String url;
  final String title;
  final String browserName;

  const BrowserInfo({
    required this.id,
    required this.url,
    required this.title,
    required this.browserName,
  });

  BrowserInfo copyWith({
    String? id,
    String? url,
    String? title,
    String? browserName,
  }) {
    return BrowserInfo(
      id: id ?? this.id,
      url: url ?? this.url,
      title: title ?? this.title,
      browserName: browserName ?? this.browserName,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'url': url,
        'title': title,
        'browserName': browserName,
      };

  factory BrowserInfo.fromJson(Map<String, dynamic> json) => BrowserInfo(
        id: json['id'],
        url: json['url'],
        title: json['title'],
        browserName: json['browserName'],
      );

  @override
  List<Object?> get props => [
    id,
    url,
    title,
    browserName,
  ];
}

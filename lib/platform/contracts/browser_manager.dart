import 'package:equatable/equatable.dart';

abstract class BrowserManager {
  /// Liste les onglets ouverts dans les navigateurs pris en charge
  Future<List<BrowserInfo>> listOpenTabs();

  /// Ouvre un onglet dans le navigateur
  Future<String> openBrowser({
    required String url,
    String? profile,
    bool incognito = false,
  });

  /// Ferme un onglet de navigateur par son ID
  Future<void> closeBrowser(String browserId);
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

  @override
  List<Object?> get props => [
    id,
    url,
    title,
    browserName,
  ];
}

import 'package:flutter/material.dart';
import 'routes.dart';
import '../presentation/pages/home/home_page.dart';
import '../presentation/pages/capture/capture_page.dart';
import '../presentation/pages/workspace_detail/workspace_detail_page.dart';
import '../presentation/pages/settings/settings_page.dart';

class AppRouter {
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case Routes.home:
        return MaterialPageRoute(builder: (_) => const HomePage());
      case Routes.capture:
        return MaterialPageRoute(builder: (_) => const CapturePage());
      case Routes.workspaceDetail:
        final workspaceId = settings.arguments as String?;
        if (workspaceId == null) return null;
        return MaterialPageRoute(
          builder: (_) => WorkspaceDetailPage(workspaceId: workspaceId),
        );
      case Routes.settings:
        return MaterialPageRoute(builder: (_) => const SettingsPage());
      default:
        return MaterialPageRoute(builder: (_) => const HomePage());
    }
  }
}

import 'package:flutter/material.dart';
import '../../core/widgets/nav_shell.dart';

class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    // Since we now use RootShell (NavShell) which manages its own state via IndexedStack,
    // most primary navigation happens internally. Named routes here can still be used
    // for screens outside the primary shell (like Auth or Details).
    
    switch (settings.name) {
      default:
        return _build(
          const NavShell(),
          settings,
        );
    }
  }

  static MaterialPageRoute _build(Widget child, RouteSettings settings) {
    return MaterialPageRoute(
      builder: (_) => child,
      settings: settings,
    );
  }
}

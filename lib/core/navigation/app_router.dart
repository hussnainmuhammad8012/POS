import 'package:flutter/material.dart';
import '../../core/widgets/nav_shell.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/pos/presentation/pos_screen.dart';
import '../../features/inventory/presentation/inventory_screen.dart';
import '../../features/customers/presentation/customers_screen.dart';
import '../../features/analytics/presentation/analytics_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';

class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case DashboardScreen.routeName:
        return _build(
          const NavShell(
            selectedIndex: 0,
            child: DashboardScreen(),
          ),
          settings,
        );
      case PosScreen.routeName:
        return _build(
          const NavShell(
            selectedIndex: 1,
            child: PosScreen(),
          ),
          settings,
        );
      case InventoryScreen.routeName:
        return _build(
          const NavShell(
            selectedIndex: 2,
            child: InventoryScreen(),
          ),
          settings,
        );
      case CustomersScreen.routeName:
        return _build(
          const NavShell(
            selectedIndex: 3,
            child: CustomersScreen(),
          ),
          settings,
        );
      case AnalyticsScreen.routeName:
        return _build(
          const NavShell(
            selectedIndex: 4,
            child: AnalyticsScreen(),
          ),
          settings,
        );
      case SettingsScreen.routeName:
        return _build(
          const NavShell(
            selectedIndex: 5,
            child: SettingsScreen(),
          ),
          settings,
        );
      default:
        return _build(
          const NavShell(
            selectedIndex: 0,
            child: DashboardScreen(),
          ),
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


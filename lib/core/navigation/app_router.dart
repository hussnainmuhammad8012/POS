import 'package:flutter/material.dart';
import '../../core/widgets/nav_shell.dart';
import '../../features/customers/presentation/customers_screen.dart';
import '../../features/transactions/presentation/transactions_screen.dart';
import '../../features/analytics/presentation/analytics_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/pos/presentation/pos_screen.dart';
import '../../features/inventory/presentation/inventory_screen.dart';

class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case NavShell.routeName:
        return MaterialPageRoute(builder: (_) => const NavShell());
      case DashboardScreen.routeName:
        return MaterialPageRoute(builder: (_) => const DashboardScreen());
      case PosScreen.routeName:
        return MaterialPageRoute(builder: (_) => const PosScreen());
      case InventoryScreen.routeName:
        return MaterialPageRoute(builder: (_) => const InventoryScreen());
      case CustomersScreen.routeName:
        return MaterialPageRoute(builder: (_) => const CustomersScreen());
      case TransactionsScreen.routeName:
        return MaterialPageRoute(builder: (_) => const TransactionsScreen());
      case AnalyticsScreen.routeName:
        return MaterialPageRoute(builder: (_) => const AnalyticsScreen());
      case SettingsScreen.routeName:
        return MaterialPageRoute(builder: (_) => const SettingsScreen());
      default:
        // Fallback for unknown routes, or if NavShell is the default entry point
        return MaterialPageRoute(builder: (_) => const NavShell());
    }
  }
}

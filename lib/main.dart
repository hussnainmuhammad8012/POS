import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'core/database/app_database.dart';
import 'core/theme/app_theme.dart';
import 'core/navigation/app_router.dart';
import 'features/dashboard/presentation/dashboard_screen.dart';
import 'features/pos/presentation/pos_screen.dart';
import 'features/inventory/presentation/inventory_screen.dart';
import 'features/customers/presentation/customers_screen.dart';
import 'features/analytics/presentation/analytics_screen.dart';
import 'features/settings/presentation/settings_screen.dart';
import 'features/pos/application/pos_provider.dart';
import 'features/inventory/application/inventory_provider.dart';
import 'features/customers/application/customers_provider.dart';
import 'features/analytics/application/analytics_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppDatabase.instance.initialize();
  runApp(const UtilityStorePosApp());
}

class UtilityStorePosApp extends StatelessWidget {
  const UtilityStorePosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PosProvider()),
        ChangeNotifierProvider(create: (_) => InventoryProvider()),
        ChangeNotifierProvider(create: (_) => CustomersProvider()),
        ChangeNotifierProvider(create: (_) => AnalyticsProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Utility Store POS',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        onGenerateRoute: AppRouter.onGenerateRoute,
        initialRoute: DashboardScreen.routeName,
        builder: (context, child) {
          // Apply a consistent text scale & default font across the app.
          final textTheme = GoogleFonts.poppinsTextTheme(
            Theme.of(context).textTheme,
          );
          return Theme(
            data: Theme.of(context).copyWith(textTheme: textTheme),
            child: child ?? const SizedBox.shrink(),
          );
        },
      ),
    );
  }
}


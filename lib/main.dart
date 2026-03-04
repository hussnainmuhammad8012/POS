import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'core/database/app_database.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/nav_shell.dart';
import 'core/navigation/app_router.dart';
import 'core/application/theme_provider.dart';
import 'features/dashboard/presentation/dashboard_screen.dart';





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
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Utility Store POS',
            theme: themeProvider.themeMode == ThemeMode.light 
                ? AppTheme.lightTheme 
                : AppTheme.starAdminTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            home: NavShell(),
          );
        },
      ),
    );
  }
}


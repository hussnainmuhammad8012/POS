import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/database/app_database.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/nav_shell.dart';
import 'core/application/theme_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'features/settings/application/settings_provider.dart';

import 'features/pos/application/pos_provider.dart';
import 'features/inventory/application/inventory_provider.dart';
import 'features/inventory/application/stock_provider.dart';
import 'features/inventory/data/repositories/category_repository.dart';
import 'features/inventory/data/repositories/product_repository.dart';
import 'features/inventory/data/repositories/carton_repository.dart';
import 'features/inventory/data/repositories/stock_movement_repository.dart';
import 'core/repositories/customer_repository.dart';
import 'core/repositories/credit_ledger_repository.dart';
import 'features/customers/application/customers_provider.dart';
import 'features/customers/application/credit_ledger_provider.dart';
import 'features/analytics/application/analytics_provider.dart';
import 'features/transactions/application/transactions_provider.dart';
import 'core/repositories/transaction_repository.dart';
import 'core/repositories/notification_repository.dart';
import 'core/features/notifications/application/notification_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppDatabase.instance.initialize();
  final prefs = await SharedPreferences.getInstance();
  runApp(UtilityStorePosApp(prefs: prefs));
}

class UtilityStorePosApp extends StatelessWidget {
  final SharedPreferences prefs;
  const UtilityStorePosApp({super.key, required this.prefs});

  @override
  Widget build(BuildContext context) {
    final db = AppDatabase.instance;
    final categoryRepo = CategoryRepository(database: db);
    final productRepo = ProductRepository(database: db);
    final cartonRepo = CartonRepository(database: db);
    final movementRepo = StockMovementRepository(database: db);
    final customerRepo = CustomerRepository();
    final creditLedgerRepo = CreditLedgerRepository();
    final transactionRepo = TransactionRepository();
    final notificationRepo = NotificationRepository();

    return MultiProvider(
      providers: [
        // Repositories
        Provider<CategoryRepository>.value(value: categoryRepo),
        Provider<ProductRepository>.value(value: productRepo),
        Provider<CartonRepository>.value(value: cartonRepo),
        Provider<StockMovementRepository>.value(value: movementRepo),
        Provider<CustomerRepository>.value(value: customerRepo),
        Provider<CreditLedgerRepository>.value(value: creditLedgerRepo),
        Provider<TransactionRepository>.value(value: transactionRepo),
        Provider<NotificationRepository>.value(value: notificationRepo),
        
        // Providers
        ChangeNotifierProvider(create: (_) => PosProvider(transactionRepo)),
        ChangeNotifierProvider(
          create: (_) => InventoryProvider(
            categoryRepository: categoryRepo,
            productRepository: productRepo,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => StockProvider(
            cartonRepository: cartonRepo,
            movementRepository: movementRepo,
          ),
        ),
        ChangeNotifierProvider(create: (_) => CustomersProvider(repository: customerRepo)),
        ChangeNotifierProvider(create: (_) => CreditLedgerProvider(creditLedgerRepo)),
        ChangeNotifierProvider(create: (_) => AnalyticsProvider()),
        ChangeNotifierProvider(create: (_) => TransactionsProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider(prefs)),
        ChangeNotifierProvider(create: (_) {
          final p = NotificationProvider(notificationRepo);
          p.checkOverdueCredits(); // Trigger check on start
          return p;
        }),
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


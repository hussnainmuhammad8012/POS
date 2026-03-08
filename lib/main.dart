import 'package:flutter/material.dart';
import 'dart:async';
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
import 'features/analytics/data/analytics_repository.dart';
import 'core/application/navigation_provider.dart';
import 'core/application/global_search_provider.dart';
import 'core/network/local_api_server.dart';
import 'core/services/fcm_service.dart';
import 'package:tray_manager/tray_manager.dart';

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
// ... (omitting unchanged repositories for brevity)
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
        ChangeNotifierProvider(
          create: (_) => AnalyticsProvider(
            analyticsRepository: AnalyticsRepository(),
            transactionRepository: transactionRepo,
          ),
        ),
        ChangeNotifierProvider(create: (_) => TransactionsProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) {
          final s = SettingsProvider(prefs);
          s.checkAndPerformAutoBackup(); // Daily auto-backup check
          return s;
        }),
        ChangeNotifierProvider(create: (_) {
          final p = NotificationProvider(notificationRepo);
          p.checkOverdueCredits(); // Trigger check on start
          p.checkLowStock();       // Trigger low stock check on start
          return p;
        }),
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
        ChangeNotifierProvider(
          create: (_) => GlobalSearchProvider(
            productRepository: productRepo,
            customerRepository: customerRepo,
          ),
        ),
      ],
      child: _AppBootstrapper(
        productRepo: productRepo,
        categoryRepo: categoryRepo,
        transactionRepo: transactionRepo,
      ),
    );
  }
}

class _AppBootstrapper extends StatefulWidget {
  final ProductRepository productRepo;
  final CategoryRepository categoryRepo;
  final TransactionRepository transactionRepo;

  const _AppBootstrapper({
    required this.productRepo,
    required this.categoryRepo,
    required this.transactionRepo,
  });

  @override
  State<_AppBootstrapper> createState() => _AppBootstrapperState();
}

class _AppBootstrapperState extends State<_AppBootstrapper> with TrayListener {
  @override
  void initState() {
    super.initState();
    trayManager.addListener(this);
    _initTray();
    _initLocalServerAndFCM();
  }

  Future<void> _initLocalServerAndFCM() async {
    final settings = context.read<SettingsProvider>();
    
    final fcmService = FCMService(
      productRepository: widget.productRepo,
      transactionRepository: widget.transactionRepo,
      settingsProvider: settings,
    );

    final server = LocalApiServer();
    server.setServices(
      productRepository: widget.productRepo,
      categoryRepository: widget.categoryRepo,
      analyticsRepository: AnalyticsRepository(),
      transactionRepository: widget.transactionRepo,
      settingsProvider: settings,
      fcmService: fcmService,
    );

    if (settings.isServerEnabled) {
      await server.start();
    }

    // Schedule daily summary
    _scheduleDailySummary(fcmService);
  }

  void _scheduleDailySummary(FCMService fcm) {
    // Basic daily timer logic
    final now = DateTime.now();
    var scheduledTime = DateTime(now.year, now.month, now.day, 21, 0); // 9:00 PM
    if (now.isAfter(scheduledTime)) {
      scheduledTime = scheduledTime.add(const Duration(days: 1));
    }

    final delay = scheduledTime.difference(now);
    Timer(delay, () async {
      final settings = context.read<SettingsProvider>();
      if (settings.dailyReportEnabled) {
        await fcm.sendDailySummary();
      }
      // Re-schedule for next day
      _scheduleDailySummary(fcm);
    });
  }

  @override
  void dispose() {
    trayManager.removeListener(this);
    super.dispose();
  }

  Future<void> _initTray() async {
    await trayManager.setIcon('assets/icons/app_icon.png');
    _updateTrayTooltip();
  }

  void _updateTrayTooltip() {
    final storeName = context.read<SettingsProvider>().storeName;
    trayManager.setToolTip(storeName);
  }

  @override
  Widget build(BuildContext context) {
    // Listen to store name changes to update tooltip
    final storeName = context.select<SettingsProvider, String>((s) => s.storeName);
    _updateTrayTooltip();

    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: storeName.isEmpty ? 'Utility Store POS' : storeName,
          theme: themeProvider.themeMode == ThemeMode.light 
              ? AppTheme.lightTheme 
              : AppTheme.starAdminTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,
          home: NavShell(),
        );
      },
    );
  }
}


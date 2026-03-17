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
import 'core/services/data_sync_service.dart';
import 'package:tray_manager/tray_manager.dart';

import 'core/repositories/supplier_repository.dart';
import 'features/suppliers/application/suppliers_provider.dart';
import 'features/auth/application/auth_provider.dart';
import 'features/auth/application/auth_service.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/auth/presentation/screens/license_screen.dart';
import 'core/widgets/block_screen.dart';

// ... other imports ...

void main() async {
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
    final supplierRepo = SupplierRepository();

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
        Provider<SupplierRepository>.value(value: supplierRepo),
        
        // Providers
        ChangeNotifierProvider(create: (_) => DataSyncService()),
        ChangeNotifierProvider(create: (context) => PosProvider(transactionRepo, context.read<DataSyncService>())),
        ChangeNotifierProvider(
          create: (context) => InventoryProvider(
            categoryRepository: categoryRepo,
            productRepository: productRepo,
            syncService: context.read<DataSyncService>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => StockProvider(
            cartonRepository: cartonRepo,
            movementRepository: movementRepo,
            syncService: context.read<DataSyncService>(),
          ),
        ),
        ChangeNotifierProvider(create: (_) => CustomersProvider(repository: customerRepo)),
        ChangeNotifierProvider(
          create: (context) => SuppliersProvider(
            repository: supplierRepo,
            syncService: context.read<DataSyncService>(),
          ),
        ),
        ChangeNotifierProvider(create: (_) => CreditLedgerProvider(creditLedgerRepo)),
        ChangeNotifierProvider(
          create: (context) => AnalyticsProvider(
            analyticsRepository: AnalyticsRepository(),
            transactionRepository: transactionRepo,
            syncService: context.read<DataSyncService>(),
          ),
        ),
        ChangeNotifierProvider(create: (_) => TransactionsProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) {
          final s = SettingsProvider(prefs);
          s.checkAndPerformAutoBackup(); // Daily auto-backup check
          return s;
        }),
        ChangeNotifierProvider(        create: (context) {
          final p = NotificationProvider(context.read<NotificationRepository>());
          p.checkOverdueCredits(); // Trigger check on start
          p.checkSupplierOverdueDues(); // Trigger supplier due check on start
          p.checkLowStock(); // Trigger low stock check on start
          return p;
        }),
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
        ChangeNotifierProvider(
          create: (_) => GlobalSearchProvider(
            productRepository: productRepo,
            customerRepository: customerRepo,
          ),
        ),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
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
  Timer? _reportTimer;
  String? _lastScheduledTime;

  @override
  void initState() {
    super.initState();
    trayManager.addListener(this);
    _initTray();
    _initLocalServerAndFCM();
  }

  Future<void> _initLocalServerAndFCM() async {
    final settings = context.read<SettingsProvider>();
    final auth = context.read<AuthProvider>();
    
    // Check license/trial status from remote server (placeholder)
    auth.checkLicense();
    
    final fcmService = FCMService(
      productRepository: widget.productRepo,
      transactionRepository: widget.transactionRepo,
      analyticsRepository: AnalyticsRepository(),
      settingsProvider: settings,
    );

    final server = LocalApiServer();
    server.setServices(
      productRepository: widget.productRepo,
      categoryRepository: widget.categoryRepo,
      cartonRepository: context.read<CartonRepository>(),
      supplierRepository: context.read<SupplierRepository>(),
      analyticsRepository: AnalyticsRepository(),
      transactionRepository: widget.transactionRepo,
      settingsProvider: settings,
      fcmService: fcmService,
      dataSyncService: context.read<DataSyncService>(),
      authService: AuthService(),
    );

    if (settings.isServerEnabled) {
      await server.start();
    }

    // Schedule daily summary and listen for changes
    _scheduleDailySummary(fcmService);
    settings.addListener(() {
      if (_lastScheduledTime != settings.dailyReportTime) {
        print('FCM: Settings changed. Re-scheduling reports...');
        _scheduleDailySummary(fcmService);
      }
    });
  }

  void _scheduleDailySummary(FCMService fcm) {
    _reportTimer?.cancel();
    
    final settings = context.read<SettingsProvider>();
    _lastScheduledTime = settings.dailyReportTime;
    final now = DateTime.now();
    
    // Parse time from settings (default 20:00)
    final timeParts = settings.dailyReportTime.split(':');
    final hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);

    var scheduledTime = DateTime(now.year, now.month, now.day, hour, minute);
    if (now.isAfter(scheduledTime)) {
      scheduledTime = scheduledTime.add(const Duration(days: 1));
    }

    final delay = scheduledTime.difference(now);
    print('FCM: Next report scheduled for $scheduledTime (in ${delay.inMinutes} mins)');
    
    _reportTimer = Timer(delay, () async {
      print('FCM: Timer fired! Checking if reports are enabled...');
      if (settings.dailyReportEnabled) {
        await fcm.sendDailySummary();
      } else {
        print('FCM: Daily reports are disabled in settings. Skipping.');
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
          home: Consumer<AuthProvider>(
            builder: (context, auth, _) {
              if (auth.needsActivation) {
                return const LicenseActivationScreen();
              }
              
              if (auth.isBlocked) {
                return const BlockScreen(
                  title: 'Service Blocked',
                  message: 'This service is currently blocked. Please contact the owner for more information.',
                  contactInfo: '03258012402',
                );
              }
              
              if (auth.isTrialExpired) {
                return const BlockScreen(
                  title: 'Trial Period Expired',
                  message: 'Your trial period has ended. Please upgrade to a full account to continue.',
                  contactInfo: '03258012402',
                );
              }

              if (!auth.isAuthenticated) {
                return const LoginScreen();
              }
              
              return const NavShell();
            },
          ),
        );
      },
    );
  }
}


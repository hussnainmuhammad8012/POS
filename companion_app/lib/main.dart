import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/theme/app_theme.dart';
import 'core/services/fcm_service.dart';
import 'features/auth/application/auth_provider.dart';
import 'features/auth/presentation/screens/pairing_screen.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/inventory/application/inventory_provider.dart';
import 'features/inventory/presentation/screens/inventory_screen.dart';
import 'features/dashboard/application/dashboard_provider.dart';
import 'features/dashboard/presentation/screens/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Note: Requires google-services.json in android/app/
    await Firebase.initializeApp();
    await FCMService.initialize();
  } catch (e) {
    debugPrint('Firebase initialization skipped: $e');
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: const CompanionApp(),
    ),
  );
}

class CompanionApp extends StatelessWidget {
  const CompanionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'POS Companion',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.starAdminTheme,
      home: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          if (!auth.isPaired) return const PairingScreen();
          if (!auth.isLoggedIn) return const LoginScreen();
          
          return MultiProvider(
            providers: [
              ChangeNotifierProvider(
                create: (_) => InventoryProvider(
                  serverIp: auth.serverIp!,
                  accessToken: auth.accessToken!,
                ),
              ),
              ChangeNotifierProvider(
                create: (_) => DashboardProvider(
                  serverIp: auth.serverIp!,
                  accessToken: auth.accessToken!,
                ),
              ),
            ],
            child: const MainNavigationShell(),
          );
        },
      ),
    );
  }
}

class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const InventoryScreen(),
    const DashboardScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: AppColors.STAR_PRIMARY,
        unselectedItemColor: AppColors.STAR_TEXT_SECONDARY,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(LucideIcons.package), label: 'Inventory'),
          BottomNavigationBarItem(icon: Icon(LucideIcons.layoutDashboard), label: 'Dashboard'),
        ],
      ),
    );
  }
}

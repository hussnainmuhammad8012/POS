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
import 'features/auth/presentation/screens/selection_screen.dart';

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
          // 1. Initial Selection
          if (auth.currentMode == AppMode.selection) {
            return const SelectionScreen();
          }

          // 2. Path A: Inventory
          if (auth.currentMode == AppMode.inventory) {
            if (!auth.isPaired) return const PairingScreen();
            return ChangeNotifierProvider(
              create: (_) => InventoryProvider(
                serverIp: auth.serverIp!,
                accessToken: auth.accessToken!,
              ),
              child: const InventoryScreen(),
            );
          }

          // 3. Path B: Admin
          if (auth.currentMode == AppMode.admin) {
            // Admin path also needs pairing to talk to PC if local, 
            // but for "9PM Report" it might just be the login screen if already setup.
            // For now, let's require pairing or assume setup is done.
            if (!auth.isPaired) return const PairingScreen();
            if (!auth.isLoggedIn) return const LoginScreen();
            
            return ChangeNotifierProvider(
              create: (_) => DashboardProvider(
                serverIp: auth.serverIp!,
                accessToken: auth.accessToken!,
              ),
              child: const DashboardScreen(),
            );
          }

          return const SelectionScreen();
        },
      ),
    );
  }
}

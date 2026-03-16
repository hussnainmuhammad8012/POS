import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../application/auth_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/toast_notification.dart';

class PairingScreen extends StatefulWidget {
  const PairingScreen({super.key});

  @override
  State<PairingScreen> createState() => _PairingScreenState();
}

class _PairingScreenState extends State<PairingScreen> {
  bool _isScanning = true;

  void _onDetect(BarcodeCapture capture) async {
    if (!_isScanning) return;
    
    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      if (barcode.rawValue != null) {
        setState(() => _isScanning = false);

        final success = await context.read<AuthProvider>().pairWithServer(
          barcode.rawValue!,
          onProgress: (status) {
            if (mounted) {
              AppToast.show(
                context, 
                title: 'Pairing Status', 
                message: status,
                type: ToastType.info,
              );
            }
          },
        );
        
        if (mounted) {
          if (success) {
            AppToast.show(
              context, 
              title: 'Success!', 
              message: 'Devices paired successfully.',
              type: ToastType.success,
            );
            // No manual navigation here! 
            // The root MaterialApp in main.dart listens to AuthProvider
            // and will automatically switch from PairingScreen to Inventory/Admin.
          } else {
            setState(() => _isScanning = true);
            AppToast.show(
              context, 
              title: 'Pairing Failed', 
              message: 'Make sure your PC and Phone are on the same network or connected via USB.',
              type: ToastType.error,
            );
          }
        }
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          MobileScanner(
            onDetect: _onDetect,
          ),
          // Overlay UI
          Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  Text(
                    'Pair with Desktop',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Scan the QR code from POS Settings',
                    style: TextStyle(color: Colors.white70),
                  ),
                  const Spacer(),
                  // Scanner Frame
                  Center(
                    child: Container(
                      width: 250,
                      height: 250,
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.STAR_PRIMARY, width: 4),
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 20),
                    child: Column(
                      children: [
                        Icon(LucideIcons.scanLine, color: Colors.white.withOpacity(0.5), size: 40),
                        const SizedBox(height: 12),
                        const Text(
                          'Tip: If Wi-Fi is slow, connect via USB\nfor an instant connection.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

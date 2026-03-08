import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../application/auth_provider.dart';
import '../../../../core/theme/app_theme.dart';

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
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Analyzing QR Code...'), backgroundColor: AppColors.STAR_PRIMARY),
        );

        final success = await context.read<AuthProvider>().pairWithServer(barcode.rawValue!);
        
        if (mounted) {
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Devices Paired Successfully!'), backgroundColor: AppColors.SUCCESS),
            );
          } else {
            setState(() => _isScanning = true);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Pairing Failed. Check terminal logs or try USB.'), 
                backgroundColor: AppColors.DANGER,
                duration: Duration(seconds: 5),
              ),
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
                        Icon(LucideIcons.qrCode, color: Colors.white.withOpacity(0.5), size: 40),
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

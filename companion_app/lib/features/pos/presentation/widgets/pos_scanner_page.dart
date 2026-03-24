import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/app_theme.dart';

class PosScannerPage extends StatefulWidget {
  final Function(String) onScan;
  const PosScannerPage({super.key, required this.onScan});

  @override
  State<PosScannerPage> createState() => _PosScannerPageState();
}

class _PosScannerPageState extends State<PosScannerPage> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  bool _isSuccess = false;
  bool _isProcessed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0, end: 250).animate(_animationController);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleScan(String code) async {
    if (_isProcessed) return;
    setState(() {
      _isProcessed = true;
      _isSuccess = true;
    });

    // Show success ticket animation for a moment
    await Future.delayed(const Duration(milliseconds: 600));
    
    if (mounted) {
      widget.onScan(code);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          MobileScanner(
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (barcode.rawValue != null) {
                  _handleScan(barcode.rawValue!);
                  break;
                }
              }
            },
          ),
          
          // Dark Overlay with Cutout
          ColorFiltered(
            colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(0.6),
              BlendMode.srcOut,
            ),
            child: Stack(
              children: [
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.black,
                    backgroundBlendMode: BlendMode.dstOut,
                  ),
                ),
                Center(
                  child: Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      color: Colors.red, // This color doesn't matter, it's a hole
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Scanning Frame
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Stack(
                children: [
                  // Corner Borders
                  ..._buildCorners(),
                  
                  // Animated Scanning Line
                  if (!_isSuccess)
                    AnimatedBuilder(
                      animation: _animation,
                      builder: (context, child) {
                        return Positioned(
                          top: _animation.value,
                          left: 10,
                          right: 10,
                          child: Container(
                            height: 2,
                            decoration: BoxDecoration(
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.STAR_PRIMARY.withOpacity(0.5),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                ),
                              ],
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.STAR_PRIMARY.withOpacity(0.1),
                                  AppColors.STAR_PRIMARY,
                                  AppColors.STAR_PRIMARY.withOpacity(0.1),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),

          // Success Tick
          if (_isSuccess)
            Center(
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.SUCCESS.withOpacity(0.9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(LucideIcons.check, color: Colors.white, size: 80),
              ),
            ),

          // Close Button
          Positioned(
            top: 50,
            right: 20,
            child: IconButton(
              icon: const Icon(LucideIcons.x, color: Colors.white, size: 30),
              onPressed: () => Navigator.pop(context),
            ),
          ),

          const Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'SCANNING CODE...',
                style: TextStyle(
                  color: Colors.white,
                  letterSpacing: 2,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildCorners() {
    const double size = 30;
    const double width = 4;
    return [
      Positioned(top: 0, left: 0, child: _corner(top: true, left: true)),
      Positioned(top: 0, right: 0, child: _corner(top: true, left: false)),
      Positioned(bottom: 0, left: 0, child: _corner(top: false, left: true)),
      Positioned(bottom: 0, right: 0, child: _corner(top: false, left: false)),
    ];
  }

  Widget _corner({required bool top, required bool left}) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        border: Border(
          top: top ? const BorderSide(color: AppColors.STAR_PRIMARY, width: 4) : BorderSide.none,
          bottom: !top ? const BorderSide(color: AppColors.STAR_PRIMARY, width: 4) : BorderSide.none,
          left: left ? const BorderSide(color: AppColors.STAR_PRIMARY, width: 4) : BorderSide.none,
          right: !left ? const BorderSide(color: AppColors.STAR_PRIMARY, width: 4) : BorderSide.none,
        ),
      ),
    );
  }
}

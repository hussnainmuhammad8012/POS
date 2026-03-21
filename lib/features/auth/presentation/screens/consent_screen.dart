import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/modern_card.dart';
import '../../application/auth_provider.dart';

class ConsentScreen extends StatefulWidget {
  const ConsentScreen({super.key});

  @override
  State<ConsentScreen> createState() => _ConsentScreenState();
}

class _ConsentScreenState extends State<ConsentScreen> {
  bool _accepted = false;
  int _activeTab = 0; // 0: License, 1: Installation Guide

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.DARK_BACKGROUND : Colors.grey[50],
      body: Center(
        child: ModernCard(
          width: 800,
          height: 650,
          mainAxisSize: MainAxisSize.max,
          padding: EdgeInsets.zero,
          child: Row(
            children: [
              // Left side: Branding & Contact
              Container(
                width: 300,
                color: theme.primaryColor.withAlpha(20),
                padding: const EdgeInsets.all(40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: theme.primaryColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(LucideIcons.shieldCheck, color: Colors.white, size: 40),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'RaiRoyalsCode',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const Text(
                      'Software Licensing',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.DARK_TEXT_SECONDARY,
                      ),
                    ),
                    const Spacer(),
                    const Divider(),
                    const SizedBox(height: 16),
                    const Text(
                      'BUILT BY RAIROYALSCODE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                        color: AppColors.DARK_TEXT_TERTIARY,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Support: Hussnain Muhammad',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    const Text(
                      '03258012402',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.INFO),
                    ),
                  ],
                ),
              ),
              
              // Right side: Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tab Headers
                      Row(
                        children: [
                          _buildTabButton('License & Terms', 0),
                          const SizedBox(width: 16),
                          _buildTabButton('Installation Steps', 1),
                        ],
                      ),
                      const SizedBox(height: 24),
                      
                      // Tab Content
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.DARK_PANEL : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: theme.dividerColor),
                          ),
                          child: SingleChildScrollView(
                            child: _activeTab == 0 ? _buildLicenseContent() : _buildInstallationSteps(),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Accept Footer
                      Row(
                        children: [
                          Checkbox(
                            value: _accepted,
                            onChanged: (val) => setState(() => _accepted = val ?? false),
                            activeColor: theme.primaryColor,
                          ),
                          const Expanded(
                            child: Text(
                              'I have read and agree to the License of Usage and User Consent.',
                              style: TextStyle(fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 45,
                        child: ElevatedButton(
                          onPressed: _accepted ? () => context.read<AuthProvider>().acceptTerms() : null,
                          child: const Text('Continue to Activation'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabButton(String title, int index) {
    bool isActive = _activeTab == index;
    return InkWell(
      onTap: () => setState(() => _activeTab = index),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              color: isActive ? Theme.of(context).primaryColor : AppColors.DARK_TEXT_SECONDARY,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            height: 2,
            width: 40,
            color: isActive ? Theme.of(context).primaryColor : Colors.transparent,
          ),
        ],
      ),
    );
  }

  Widget _buildLicenseContent() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('License of Usage', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        SizedBox(height: 12),
        Text(
          '1. Grant of License: RaiRoyalsCode grants you a non-exclusive, non-transferable license to use this software on a single computer system.\n\n'
          '2. Registration: This software must be activated using a valid license key provided by RaiRoyalsCode. Attempting to bypass activation is a violation of this agreement.\n\n'
          '3. Restrictions: You may not modify, reverse engineer, or decompile the software. You may not distribute copies of this software to third parties.\n\n'
          '4. Support: Official support is provided only to registered users via the contact details listed on this screen.\n\n'
          '5. Updates: Remote updates and cloud features require an active internet connection.',
          style: TextStyle(fontSize: 13, height: 1.5),
        ),
      ],
    );
  }

  Widget _buildInstallationSteps() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Real-World Installation Guide', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        SizedBox(height: 12),
        Text(
          'Follow these steps to set up the system for your client:\n\n'
          'Step 1: Extract the provided Release folder to a stable location (e.g., C:\\POS_System).\n\n'
          'Step 2: Ensure the client has "Visual C++ Redistributable" installed on their Windows machine.\n\n'
          'Step 3: Run the executable file within the folder to start the application.\n\n'
          'Step 4: Contact Hussnain Muhammad for the unique Activation Key for this specific PC.\n\n'
          'Step 5: Ensure the PC has internet access during the first activation step to connect to the RaiRoyals Cloud.',
          style: TextStyle(fontSize: 13, height: 1.5, color: AppColors.INFO),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../application/settings_provider.dart';
import '../../../../core/network/local_api_server.dart';
import '../../../../core/widgets/app_dropdown.dart';
import 'package:lucide_icons/lucide_icons.dart';

class CompanionServerSettings extends StatefulWidget {
  const CompanionServerSettings({super.key});

  @override
  State<CompanionServerSettings> createState() => _CompanionServerSettingsState();
}

class _CompanionServerSettingsState extends State<CompanionServerSettings> {
  final _server = LocalApiServer();
  bool _isLoadingQr = false;

  void _showQrDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: const Text('Pair Inventory Manager'),
        content: SizedBox(
          width: 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Scan this QR code from the Android Companion app to pair this device.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: (_isLoadingQr || _server.getQrData().isEmpty)
                  ? const SizedBox(
                      width: 200, 
                      height: 200, 
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text('Initializing Server...', style: TextStyle(fontSize: 12)),
                          ],
                        ),
                      )
                    )
                  : QrImageView(
                      data: _server.getQrData(),
                      version: QrVersions.auto,
                      size: 200.0,
                    ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Server: ${_server.baseUrl}',
                  style: TextStyle(
                    fontSize: 12, 
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(
            context,
            'Companion App Settings',
            'Connect and manage your Android inventory devices.',
          ),
          const SizedBox(height: 24),
          
          _buildSection(
            context,
            'Inventory Manager (Local Sync)',
            [
              SwitchListTile(
                title: const Text('Enable Local Server'),
                subtitle: const Text('Allow Android devices to connect via Wi-Fi'),
                value: settings.isServerEnabled,
                activeColor: Theme.of(context).colorScheme.primary,
                onChanged: (value) async {
                  await settings.setServerEnabled(value);
                  if (value) {
                    setState(() => _isLoadingQr = true);
                    await _server.start();
                    setState(() => _isLoadingQr = false);
                    if (mounted) _showQrDialog();
                  } else {
                    _server.stop();
                  }
                },
              ),
              if (settings.isServerEnabled) ...[
                const Divider(),
                ListTile(
                  title: const Text('Pair New Device'),
                  subtitle: const Text('Display the pairing QR code'),
                  trailing: const Icon(Icons.qr_code),
                  onTap: _showQrDialog,
                ),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: AppDropdown<int>(
                    label: 'Session Persistence',
                    hint: 'How long paired devices stay connected',
                    prefixIcon: LucideIcons.clock,
                    value: settings.sessionDurationHours,
                    items: const [
                      AppDropdownItem(value: 8, label: '8 Hours', subtitle: 'Standard Working Day'),
                      AppDropdownItem(value: 24, label: '24 Hours', subtitle: 'Full Day Access'),
                      AppDropdownItem(value: 168, label: '1 Week', subtitle: 'Extended Access'),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        settings.setSessionDuration(value);
                        _server.updateSessionDuration(value);
                      }
                    },
                  ),
                ),
              ],
            ],
          ),
          
          const SizedBox(height: 24),
          _buildSection(
            context,
            'Admin Reports (Remote Push)',
            [
              SwitchListTile(
                title: const Text('Daily 9PM Summary'),
                subtitle: const Text('Send sales report automatically even when away'),
                value: settings.dailyReportEnabled,
                activeColor: Theme.of(context).colorScheme.primary,
                onChanged: settings.setDailyReportEnabled,
              ),
              if (settings.dailyReportEnabled) ...[
                const Divider(),
                ListTile(
                  title: const Text('Closing Time (Report)'),
                  subtitle: Text('Current: ${settings.dailyReportTime}'),
                  trailing: const Icon(LucideIcons.clock),
                  onTap: () async {
                    final parts = settings.dailyReportTime.split(':');
                    final initialTime = TimeOfDay(
                      hour: int.parse(parts[0]),
                      minute: int.parse(parts[1]),
                    );
                    
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: initialTime,
                    );
                    
                    if (picked != null) {
                      final formatted = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                      await settings.setDailyReportTime(formatted);
                    }
                  },
                ),
              ],
              const Divider(),
              ListTile(
                title: const Text('Push Status'),
                subtitle: Text(
                  settings.dailyReportEnabled ? 'Active (Firebase)' : 'Disabled',
                ),
                trailing: Icon(
                  Icons.circle,
                  size: 12,
                  color: settings.dailyReportEnabled ? Colors.green : Colors.grey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 14,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildSection(BuildContext context, String title, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}

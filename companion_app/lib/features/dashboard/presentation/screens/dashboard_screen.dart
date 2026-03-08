import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../application/dashboard_provider.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.STAR_BACKGROUND,
      appBar: AppBar(title: const Text('Admin Dashboard')),
      body: Consumer<DashboardProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.data == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null && provider.data == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: ${provider.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: provider.fetchDashboardData,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final data = provider.data;

          return RefreshIndicator(
            onRefresh: provider.fetchDashboardData,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Sales Summary',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildStatCard(
                    context,
                    'Today\'s Sales',
                    'Rs. ${data?.todaySales.toStringAsFixed(0) ?? "0"}',
                    LucideIcons.trendingUp,
                    AppColors.STAR_TEAL,
                  ),
                  const SizedBox(height: 12),
                  _buildStatCard(
                    context,
                    'Active Credits',
                    'Rs. ${data?.activeCredits.toStringAsFixed(0) ?? "0"}',
                    LucideIcons.creditCard,
                    AppColors.STAR_PRIMARY,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Recent Alerts',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  if (data?.yesterdayReport != null)
                    _buildReportCard(
                      'Daily Closing Report',
                      'Yesterday',
                      'Total: Rs. ${data!.yesterdayReport!['total_sales'].toStringAsFixed(0)} | Profit: Rs. ${data.yesterdayReport!['profit'].toStringAsFixed(0)}',
                    )
                  else
                    const Text('No recent reports available', style: TextStyle(color: AppColors.STAR_TEXT_SECONDARY)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.STAR_CARD,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.STAR_BORDER),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: AppColors.STAR_TEXT_SECONDARY, fontSize: 13)),
              Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard(String title, String time, String summary) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.STAR_CARD,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.STAR_BORDER),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(time, style: const TextStyle(fontSize: 12, color: AppColors.STAR_TEXT_SECONDARY)),
            ],
          ),
          const Divider(height: 20),
          Text(summary, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }
}

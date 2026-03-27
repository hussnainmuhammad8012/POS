import 'dart:convert';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/pos/presentation/pos_screen.dart';
import '../../features/inventory/presentation/inventory_screen.dart';
import '../../features/customers/presentation/customers_screen.dart';
import '../../features/suppliers/presentation/suppliers_screen.dart';
import '../../features/transactions/presentation/transactions_screen.dart';
import '../../features/analytics/presentation/analytics_screen.dart';
import '../../features/customers/presentation/credits_screen.dart';
import '../../features/suppliers/presentation/dues_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/feedback/presentation/screens/feedback_screen.dart';
import '../../features/settings/application/settings_provider.dart';
import '../features/notifications/application/notification_provider.dart';
import '../features/notifications/presentation/widgets/notification_modal.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../application/navigation_provider.dart';
import '../application/global_search_provider.dart';
import '../../features/auth/application/auth_provider.dart';
import '../../core/widgets/update_dialog.dart';

class NavShell extends StatelessWidget {
  static const routeName = '/';
  const NavShell({super.key});

  @override
  Widget build(BuildContext context) {
    final nav = context.watch<NavigationProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Fixed-width Sidebar
          SizedBox(
            width: 240,
            child: _Sidebar(
              selectedIndex: nav.selectedIndex,
              onDestinationSelected: (index) => nav.setSelectedIndex(index),
            ),
          ),
          
          // 2. Main Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _TopHeaderBar(),
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Offstage(offstage: nav.selectedIndex != 0, child: const DashboardScreen()),
                      Offstage(offstage: nav.selectedIndex != 1, child: PosScreen(isVisible: nav.selectedIndex == 1)),
                      Offstage(offstage: nav.selectedIndex != 2, child: const InventoryScreen()),
                      Offstage(offstage: nav.selectedIndex != 3, child: const CustomersScreen()),
                      Offstage(offstage: nav.selectedIndex != 4, child: const SuppliersScreen()),
                      Offstage(offstage: nav.selectedIndex != 5, child: const TransactionsScreen()),
                      Offstage(offstage: nav.selectedIndex != 6, child: const CreditsScreen()),
                      Offstage(offstage: nav.selectedIndex != 7, child: const DuesScreen()),
                      Offstage(offstage: nav.selectedIndex != 8, child: const AnalyticsScreen()),
                      Offstage(offstage: nav.selectedIndex != 9, child: const SettingsScreen()),
                      Offstage(offstage: nav.selectedIndex != 10, child: const FeedbackScreen()),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  const _Sidebar({
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final settings = context.watch<SettingsProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isStarAdmin = theme.primaryColor == AppColors.STAR_PRIMARY;

    final allNavItems = [
      {'icon': LucideIcons.layoutDashboard, 'label': 'Dashboard', 'index': 0, 'visible': true},
      {'icon': LucideIcons.monitorUp, 'label': 'Point of Sale', 'index': 1, 'visible': auth.hasPermission((p) => p.canAccessPos)},
      {'icon': LucideIcons.package2, 'label': 'Inventory', 'index': 2, 'visible': auth.hasPermission((p) => p.canAccessInventory)},
      {'icon': LucideIcons.users, 'label': 'Customers', 'index': 3, 'visible': auth.hasPermission((p) => p.canAccessCustomers)},
      {'icon': LucideIcons.truck, 'label': 'Suppliers', 'index': 4, 'visible': auth.hasPermission((p) => p.canAccessSuppliers)},
      {'icon': LucideIcons.receipt, 'label': 'Transactions', 'index': 5, 'visible': auth.hasPermission((p) => p.canAccessTransactions)},
      {'icon': LucideIcons.landmark, 'label': 'Credits', 'index': 6, 'visible': auth.hasPermission((p) => p.canAccessCredits)},
      {'icon': LucideIcons.wallet, 'label': 'Dues', 'index': 7, 'visible': auth.hasPermission((p) => p.canAccessDues)},
      {'icon': LucideIcons.lineChart, 'label': 'Analytics', 'index': 8, 'visible': auth.hasPermission((p) => p.canAccessAnalytics)},
      {'icon': LucideIcons.messageSquare, 'label': 'Feedback', 'index': 10, 'visible': true},
    ];

    final navItems = allNavItems.where((item) => item['visible'] == true).toList();

    final sidebarColor = isDark 
        ? AppColors.DARK_SIDEBAR 
        : (isStarAdmin ? AppColors.STAR_SIDEBAR : AppColors.LIGHT_SIDEBAR);

    return Material(
      color: sidebarColor,
      child: Column(
        children: [
          // Logo Area
          Padding(
            padding: const EdgeInsets.only(top: 12.0),
            child: _buildLogoWidget(settings, theme, isDark, isStarAdmin),
          ),
          const SizedBox(height: 8),
          const SizedBox(height: 16),
          
          // Navigation Items
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: navItems.length,
              itemBuilder: (context, index) {
                final item = navItems[index];
                return _NavItem(
                  icon: item['icon'] as IconData,
                  label: item['label'] as String,
                  isActive: selectedIndex == (item['index'] as int),
                  onTap: () => onDestinationSelected(item['index'] as int),
                );
              },
            ),
          ),
          
          // Settings
          if (auth.hasPermission((p) => p.canAccessSettings))
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: _NavItem(
                icon: LucideIcons.settings,
                label: 'Settings',
                isActive: selectedIndex == 9,
                onTap: () => onDestinationSelected(9),
              ),
            ),
          
          const Divider(height: 1, indent: 24, endIndent: 24),
          const SizedBox(height: 16),
          Text(
            'Developed by',
            style: TextStyle(
              fontSize: 10,
              color: (isDark || isStarAdmin) ? Colors.white38 : AppColors.LIGHT_TEXT_TERTIARY,
            ),
          ),
          Text(
            'RaiRoyalsCode',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: (isDark || isStarAdmin) ? Colors.white70 : AppColors.LIGHT_TEXT_SECONDARY,
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildLogoWidget(SettingsProvider settings, ThemeData theme, bool isDark, bool isStarAdmin) {
    final storeName = settings.storeName.isEmpty ? 'Hunain Mart' : settings.storeName;
    
    try {
      Widget? logoImage;
      
      // 1. Try file-based logo (Priority)
      if (settings.storeLogoPath != null) {
        final file = File(settings.storeLogoPath!);
        if (file.existsSync()) {
          final isSvg = settings.storeLogoPath!.toLowerCase().endsWith('.svg');
          logoImage = isSvg 
              ? SvgPicture.file(file, fit: BoxFit.contain)
              : Image.file(file, fit: BoxFit.contain);
        }
      }
      
      // 2. Fallback to base64
      if (logoImage == null && settings.storeLogo != null && settings.storeLogo!.isNotEmpty) {
        final base64 = settings.storeLogo!;
        final bytes = base64.contains(',') ? base64Decode(base64.split(',').last) : base64Decode(base64);
        final isSvg = base64.contains('/svg') || (base64.length > 20 && utf8.decode(bytes.take(20).toList(), allowMalformed: true).contains('<svg'));
        logoImage = isSvg ? SvgPicture.memory(bytes, fit: BoxFit.contain) : Image.memory(bytes, fit: BoxFit.contain);
      }

      // 3. Render Custom Logo Plate
      if (logoImage != null) {
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(4), // Minimal padding to maximize image size
          decoration: BoxDecoration(
            color: Colors.white, // High contrast
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 140), // Maximize height for readability
            child: logoImage,
          ),
        );
      }

      // 4. Fallback Branding (Themed Row)
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.primaryColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                LucideIcons.store, 
                color: isDark ? AppColors.PRIMARY_ACCENT_DARK : theme.primaryColor,
                size: 26,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    storeName,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Point of Sale',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.white54,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      return Container(
        height: 80,
        alignment: Alignment.center,
        child: const Icon(LucideIcons.store, color: Colors.white54),
      );
    }
  }
}

class _NavItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isStarAdmin = theme.primaryColor == AppColors.STAR_PRIMARY;
    final primaryColor = isDark ? AppColors.PRIMARY_ACCENT_DARK : theme.primaryColor;
    
    final color;
    if (widget.isActive) {
      color = (isDark || isStarAdmin) ? Colors.white : AppColors.LIGHT_ACTIVE;
    } else {
      color = (isDark || isStarAdmin) ? AppColors.STAR_TEXT_SECONDARY : AppColors.LIGHT_TEXT_SECONDARY;
    }
    
    final Color? bgColor;
    if (widget.isActive) {
      if (isStarAdmin) {
        bgColor = AppColors.STAR_PRIMARY;
      } else {
        bgColor = isDark ? AppColors.DARK_HOVER : AppColors.LIGHT_PRIMARY_SOFT;
      }
    } else {
      bgColor = Colors.transparent;
    }
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, left: 8, right: 8),
      child: Material(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: widget.onTap,
          hoverColor: (isDark || isStarAdmin) ? Colors.white.withAlpha(15) : AppColors.LIGHT_PRIMARY_SOFT.withAlpha(15),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            height: 44,
            decoration: BoxDecoration(
              border: (widget.isActive && !isStarAdmin)
                  ? Border(left: BorderSide(color: primaryColor, width: 3))
                  : const Border(left: BorderSide(color: Colors.transparent, width: 3)),
            ),
            child: Row(
              children: [
                Icon(
                  widget.icon, 
                  color: color, 
                  size: 20,
                ),
                const SizedBox(width: 16),
                Text(
                  widget.label,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: widget.isActive ? FontWeight.w600 : FontWeight.w500,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TopHeaderBar extends StatefulWidget {
  const _TopHeaderBar();

  @override
  State<_TopHeaderBar> createState() => _TopHeaderBarState();
}

class _TopHeaderBarState extends State<_TopHeaderBar> {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  final _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(() {
      if (!_searchFocusNode.hasFocus) {
        _hideOverlay();
      }
    });
  }

  void _showOverlay() {
    _hideOverlay();
    
    final overlay = Overlay.of(context);
    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: 400,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 45),
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(12),
            color: Theme.of(context).cardTheme.color,
            clipBehavior: Clip.antiAlias,
            child: Consumer<GlobalSearchProvider>(
              builder: (context, search, _) {
                if (search.isLoading) {
                  return const SizedBox(
                    height: 100,
                    child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  );
                }

                if (search.results.isEmpty) {
                  if (search.query.length < 2) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text('No results found for "${search.query}"', 
                      style: const TextStyle(color: Colors.grey, fontSize: 13)),
                  );
                }

                return ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 400),
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    itemCount: search.results.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final result = search.results[index];
                      return ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: (result.type == SearchResultType.product ? Colors.blue : Colors.green).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            result.type == SearchResultType.product ? LucideIcons.package : LucideIcons.user,
                            size: 16,
                            color: result.type == SearchResultType.product ? Colors.blue : Colors.green,
                          ),
                        ),
                        title: Text(result.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                        subtitle: Text(result.subtitle ?? '', style: const TextStyle(fontSize: 12)),
                        onTap: () {
                          _hideOverlay();
                          _searchController.clear();
                          context.read<GlobalSearchProvider>().clearSearch();
                          _searchFocusNode.unfocus();
                          
                          // Global Navigation
                          final nav = context.read<NavigationProvider>();
                          if (result.type == SearchResultType.product) {
                            nav.navigateToInventory();
                          } else {
                            nav.navigateToCustomers();
                          }
                        },
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );

    overlay.insert(_overlayEntry!);
  }

  void _hideOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _hideOverlay();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.DARK_SURFACE : AppColors.LIGHT_SURFACE;
    final borderColor = isDark ? AppColors.DARK_BORDER_PROMINENT : AppColors.LIGHT_BORDER_PROMINENT;
    final auth = context.watch<AuthProvider>();

    return Material(
      color: surfaceColor,
      elevation: 2,
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: borderColor,
              width: 1,
            ),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Search Field
            CompositedTransformTarget(
              link: _layerLink,
              child: Container(
                width: 400,
                height: 40,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.DARK_BACKGROUND : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: borderColor,
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Icon(LucideIcons.search, size: 18, color: isDark ? AppColors.DARK_TEXT_TERTIARY : AppColors.LIGHT_TEXT_TERTIARY),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        focusNode: _searchFocusNode,
                        onChanged: (value) {
                          context.read<GlobalSearchProvider>().search(value);
                          if (value.length >= 2) {
                            _showOverlay();
                          } else {
                            _hideOverlay();
                          }
                        },
                        onTap: () {
                          if (_searchController.text.length >= 2) {
                            _showOverlay();
                          }
                        },
                        decoration: InputDecoration(
                          hintText: 'Search products, customers...',
                          hintStyle: TextStyle(
                            color: isDark ? AppColors.DARK_TEXT_TERTIARY : AppColors.LIGHT_TEXT_TERTIARY,
                            fontSize: 14,
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          errorBorder: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                          isDense: true,
                          fillColor: Colors.transparent,
                        ),
                        style: TextStyle(
                          color: isDark ? AppColors.DARK_TEXT_PRIMARY : AppColors.LIGHT_TEXT_PRIMARY,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    if (_searchController.text.isNotEmpty)
                      IconButton(
                        icon: const Icon(LucideIcons.x, size: 16),
                        onPressed: () {
                          _searchController.clear();
                          context.read<GlobalSearchProvider>().clearSearch();
                          _hideOverlay();
                          setState(() {});
                        },
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                      ),
                  ],
                ),
              ),
            ),
            
            // User Profile & Actions
            Row(
              children: [
                Consumer<NotificationProvider>(
                  builder: (context, notifications, _) {
                    return Stack(
                      children: [
                        IconButton(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => const NotificationModal(),
                            );
                          },
                          icon: const Icon(LucideIcons.bell),
                          color: isDark ? AppColors.DARK_TEXT_SECONDARY : AppColors.LIGHT_TEXT_SECONDARY,
                          iconSize: 20,
                        ),
                        if (notifications.unreadCount > 0)
                          Positioned(
                            right: 8,
                            top: 8,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.error,
                                shape: BoxShape.circle,
                              ),
                              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                              child: Text(
                                '${notifications.unreadCount}',
                                style: const TextStyle(color: Colors.white, fontSize: 10),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
                const SizedBox(width: 16),
                Container(
                  height: 32,
                  width: 1,
                  color: borderColor,
                ),
                const SizedBox(width: 16),
                PopupMenuButton<String>(
                  offset: const Offset(0, 48),
                  onSelected: (value) async {
                    if (value == 'logout') {
                      context.read<AuthProvider>().logout();
                    } else if (value == 'update') {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Checking for updates...'), duration: Duration(seconds: 2))
                      );
                      final auth = context.read<AuthProvider>();
                      await auth.checkUpdate();
                      
                      if (auth.updateInfo != null && auth.updateInfo!['available'] == true) {
                        if (!context.mounted) return;
                        showDialog(
                          context: context,
                          barrierDismissible: !(auth.updateInfo!['isCritical'] ?? false),
                          builder: (context) => UpdateDialog(
                            version: auth.updateInfo!['version'],
                            url: auth.updateInfo!['url'],
                            releaseNotes: auth.updateInfo!['releaseNotes'],
                            isCritical: auth.updateInfo!['isCritical'] ?? false,
                          ),
                        );
                      } else {
                         if (!context.mounted) return;
                         ScaffoldMessenger.of(context).showSnackBar(
                           const SnackBar(content: Text('Your application is up to date!'))
                         );
                      }
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'update',
                      child: Row(
                        children: [
                          Icon(LucideIcons.refreshCw, size: 16, color: AppColors.STAR_PRIMARY),
                          SizedBox(width: 12),
                          Text('Check for Updates'),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(height: 1),
                    const PopupMenuItem(
                      value: 'logout',
                      child: Row(
                        children: [
                          const Icon(LucideIcons.logOut, size: 16, color: Colors.red),
                          const SizedBox(width: 12),
                          const Text('Logout', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: theme.primaryColor.withAlpha(40),
                        child: Text(
                          auth.currentUser?.username.substring(0, 1).toUpperCase() ?? '?',
                          style: TextStyle(
                            color: theme.primaryColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            auth.currentUser?.username ?? 'Guest',
                            style: TextStyle(
                              color: isDark ? AppColors.DARK_TEXT_PRIMARY : AppColors.LIGHT_TEXT_PRIMARY,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              height: 1.2,
                            ),
                          ),
                          Text(
                            auth.currentUser?.role.toString().split('.').last ?? '',
                            style: TextStyle(
                              color: isDark ? AppColors.DARK_TEXT_SECONDARY : AppColors.LIGHT_TEXT_SECONDARY,
                              fontSize: 12,
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        LucideIcons.chevronDown, 
                        size: 16, 
                        color: isDark ? AppColors.DARK_TEXT_TERTIARY : AppColors.LIGHT_TEXT_TERTIARY,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

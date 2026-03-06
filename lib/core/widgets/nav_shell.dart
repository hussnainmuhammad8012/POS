import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/pos/presentation/pos_screen.dart';
import '../../features/inventory/presentation/inventory_screen.dart';
import '../../features/customers/presentation/customers_screen.dart';
import '../../features/transactions/presentation/transactions_screen.dart';
import '../../features/analytics/presentation/analytics_screen.dart';
import '../../features/customers/presentation/credits_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../theme/app_theme.dart';

class NavShell extends StatefulWidget {
  const NavShell({super.key});

  @override
  State<NavShell> createState() => _NavShellState();
}

class _NavShellState extends State<NavShell> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    DashboardScreen(),
    PosScreen(),
    InventoryScreen(),
    CustomersScreen(),
    TransactionsScreen(),
    CreditsScreen(),
    AnalyticsScreen(),
    SettingsScreen(),
  ];

  void _onDestinationSelected(int index) {
    if (index == _selectedIndex) return;
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          _Sidebar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: _onDestinationSelected,
          ),
          Expanded(
            child: Column(
              children: [
                const _TopHeaderBar(),
                Expanded(
                  child: IndexedStack(
                    index: _selectedIndex,
                    children: _screens,
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
    final navItems = [
      {'icon': LucideIcons.layoutDashboard, 'label': 'Dashboard'},
      {'icon': LucideIcons.monitorUp, 'label': 'Point of Sale'},
      {'icon': LucideIcons.package2, 'label': 'Inventory'},
      {'icon': LucideIcons.users, 'label': 'Customers'},
      {'icon': LucideIcons.receipt, 'label': 'Transactions'},
      {'icon': LucideIcons.landmark, 'label': 'Credits'},
      {'icon': LucideIcons.lineChart, 'label': 'Analytics'},
    ];

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isStarAdmin = theme.primaryColor == AppColors.STAR_PRIMARY;

    final sidebarColor = isDark 
        ? AppColors.DARK_SIDEBAR 
        : (isStarAdmin ? AppColors.STAR_SIDEBAR : AppColors.LIGHT_SIDEBAR);

    return Container(
      width: 240,
      decoration: BoxDecoration(
        color: sidebarColor,
        border: Border(
          right: BorderSide(
            color: isDark ? Colors.transparent : (isStarAdmin ? Colors.transparent : AppColors.LIGHT_BORDER_PROMINENT),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Logo Area
          Container(
            height: 64, // Matches top header
            padding: const EdgeInsets.symmetric(horizontal: 24),
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (isDark ? AppColors.PRIMARY_ACCENT_DARK : theme.primaryColor).withAlpha(40),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    LucideIcons.store, 
                    color: isDark ? AppColors.PRIMARY_ACCENT_DARK : theme.primaryColor, 
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Gravity POS',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: (isDark || isStarAdmin) ? Colors.white : AppColors.LIGHT_TEXT_PRIMARY,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Navigation Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                for (int i = 0; i < navItems.length; i++)
                  _NavItem(
                    icon: navItems[i]['icon'] as IconData,
                    label: navItems[i]['label'] as String,
                    isActive: selectedIndex == i,
                    onTap: () => onDestinationSelected(i),
                  ),
              ],
            ),
          ),
          // Bottom Settings Item
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: _NavItem(
              icon: LucideIcons.settings,
              label: 'Settings',
              isActive: selectedIndex == 7,
              onTap: () => onDestinationSelected(7),
            ),
          ),
        ],
      ),
    );
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
    
    // Sidebar text/icon color
    // In StarAdmin, icons/text should be light/white because the sidebar is dark
    final color;
    if (widget.isActive) {
      color = (isDark || isStarAdmin) ? Colors.white : AppColors.LIGHT_ACTIVE;
    } else {
      color = (isDark || isStarAdmin) ? AppColors.STAR_TEXT_SECONDARY : AppColors.LIGHT_TEXT_SECONDARY;
    }
    
    // Consistent background color for hover and active
    final Color? bgColor;
    if (widget.isActive) {
      if (isStarAdmin) {
        bgColor = AppColors.STAR_PRIMARY;
      } else {
        bgColor = isDark ? AppColors.DARK_HOVER : AppColors.LIGHT_PRIMARY_SOFT;
      }
    } else if (_isHovered) {
      bgColor = (isDark || isStarAdmin) ? Colors.white.withAlpha(15) : AppColors.LIGHT_PRIMARY_SOFT.withAlpha(15);
    } else {
      bgColor = Colors.transparent;
    }
    
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.only(bottom: 6, left: 8, right: 8),
          height: 44,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(8),
            border: (widget.isActive && !isStarAdmin)
                ? Border(left: BorderSide(color: primaryColor, width: 3))
                : const Border(left: BorderSide(color: Colors.transparent, width: 3)),
          ),
          child: Row(
            children: [
              const SizedBox(width: 12),
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
    );
  }
}

class _TopHeaderBar extends StatelessWidget {
  const _TopHeaderBar();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.DARK_SURFACE : AppColors.LIGHT_SURFACE;
    final borderColor = isDark ? AppColors.DARK_BORDER_PROMINENT : AppColors.LIGHT_BORDER_PROMINENT;

    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: surfaceColor,
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
          Container(
            width: 300,
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
              ],
            ),
          ),
          
          // User Profile & Actions
          Row(
            children: [
              IconButton(
                onPressed: () {},
                icon: const Icon(LucideIcons.bell),
                color: isDark ? AppColors.DARK_TEXT_SECONDARY : AppColors.LIGHT_TEXT_SECONDARY,
                iconSize: 20,
              ),
              const SizedBox(width: 16),
              Container(
                height: 32,
                width: 1,
                color: borderColor,
              ),
              const SizedBox(width: 16),
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: theme.primaryColor.withAlpha(40),
                    child: Text(
                      'A',
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
                        'Admin User',
                        style: TextStyle(
                          color: isDark ? AppColors.DARK_TEXT_PRIMARY : AppColors.LIGHT_TEXT_PRIMARY,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          height: 1.2,
                        ),
                      ),
                      Text(
                        'Store Manager',
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
            ],
          ),
        ],
      ),
    );
  }
}

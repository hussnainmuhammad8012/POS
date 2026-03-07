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
import '../../features/settings/application/settings_provider.dart';
import '../features/notifications/application/notification_provider.dart';
import '../features/notifications/presentation/widgets/notification_modal.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../application/navigation_provider.dart';
import '../application/global_search_provider.dart';

class NavShell extends StatelessWidget {
  static const routeName = '/';
  const NavShell({super.key});

  @override
  Widget build(BuildContext context) {
    final nav = context.watch<NavigationProvider>();

    return Scaffold(
      body: Row(
        children: [
          _Sidebar(
            selectedIndex: nav.selectedIndex,
            onDestinationSelected: (index) => nav.setSelectedIndex(index),
          ),
          Expanded(
            child: Column(
              children: [
                const _TopHeaderBar(),
                Expanded(
                  child: IndexedStack(
                    index: nav.selectedIndex,
                    children: [
                      const DashboardScreen(),
                      PosScreen(isVisible: nav.selectedIndex == 1),
                      const InventoryScreen(),
                      const CustomersScreen(),
                      const TransactionsScreen(),
                      const CreditsScreen(),
                      const AnalyticsScreen(),
                      const SettingsScreen(),
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
                  context.watch<SettingsProvider>().storeName,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    overflow: TextOverflow.ellipsis,
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

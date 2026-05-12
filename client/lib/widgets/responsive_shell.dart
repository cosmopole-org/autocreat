import 'package:badges/badges.dart' as badges;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/constants.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/ticket_provider.dart';
import '../theme/app_colors.dart';
import 'common_widgets.dart';

class _NavItem {
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final String route;
  final bool hasBadge;

  const _NavItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.route,
    this.hasBadge = false,
  });
}

final _navItems = [
  _NavItem(
    label: 'Dashboard',
    icon: Icons.dashboard_outlined,
    selectedIcon: Icons.dashboard,
    route: AppRoutes.dashboard,
  ),
  _NavItem(
    label: 'Companies',
    icon: Icons.business_outlined,
    selectedIcon: Icons.business,
    route: AppRoutes.companies,
  ),
  _NavItem(
    label: 'Flows',
    icon: Icons.account_tree_outlined,
    selectedIcon: Icons.account_tree,
    route: AppRoutes.flows,
  ),
  _NavItem(
    label: 'Forms',
    icon: Icons.dynamic_form_outlined,
    selectedIcon: Icons.dynamic_form,
    route: AppRoutes.forms,
  ),
  _NavItem(
    label: 'Models',
    icon: Icons.data_object_outlined,
    selectedIcon: Icons.data_object,
    route: AppRoutes.models,
  ),
  _NavItem(
    label: 'Roles',
    icon: Icons.shield_outlined,
    selectedIcon: Icons.shield,
    route: AppRoutes.roles,
  ),
  _NavItem(
    label: 'Users',
    icon: Icons.people_outline,
    selectedIcon: Icons.people,
    route: AppRoutes.users,
  ),
  _NavItem(
    label: 'Letters',
    icon: Icons.mail_outline,
    selectedIcon: Icons.mail,
    route: AppRoutes.letters,
  ),
  _NavItem(
    label: 'Tickets',
    icon: Icons.support_agent_outlined,
    selectedIcon: Icons.support_agent,
    route: AppRoutes.tickets,
    hasBadge: true,
  ),
];

class ResponsiveShell extends ConsumerStatefulWidget {
  final Widget child;

  const ResponsiveShell({super.key, required this.child});

  @override
  ConsumerState<ResponsiveShell> createState() => _ResponsiveShellState();
}

class _ResponsiveShellState extends ConsumerState<ResponsiveShell> {
  int _selectedIndex = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateSelectedIndex();
  }

  void _updateSelectedIndex() {
    final location = GoRouterState.of(context).matchedLocation;
    for (int i = 0; i < _navItems.length; i++) {
      if (location.startsWith(_navItems[i].route)) {
        if (_selectedIndex != i) {
          setState(() => _selectedIndex = i);
        }
        return;
      }
    }
  }

  void _navigate(int index) {
    setState(() => _selectedIndex = index);
    context.go(_navItems[index].route);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 900;
    final isTablet = width >= 900 && width < 1200;

    if (isMobile) {
      return _MobileShell(
        child: widget.child,
        selectedIndex: _selectedIndex,
        onNavigate: _navigate,
      );
    }

    if (isTablet) {
      return _CollapsedSidebarShell(
        child: widget.child,
        selectedIndex: _selectedIndex,
        onNavigate: _navigate,
      );
    }

    return _FullSidebarShell(
      child: widget.child,
      selectedIndex: _selectedIndex,
      onNavigate: _navigate,
    );
  }
}

class _AppBar extends ConsumerWidget implements PreferredSizeWidget {
  final String title;
  final bool showDrawerButton;
  final VoidCallback? onMenuTap;

  const _AppBar({
    required this.title,
    this.showDrawerButton = false,
    this.onMenuTap,
  });

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = ref.watch(currentUserProvider);
    final unread = ref.watch(unreadTicketCountProvider);

    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            if (showDrawerButton)
              IconButton(
                icon: const Icon(Icons.menu),
                onPressed: onMenuTap,
              ),
            Text(
              'AutoCreat',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {},
              tooltip: 'Search',
            ),
            const SizedBox(width: 4),
            badges.Badge(
              showBadge: unread > 0,
              badgeContent: Text(
                unread.toString(),
                style: const TextStyle(color: Colors.white, fontSize: 10),
              ),
              child: IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () => context.go(AppRoutes.tickets),
                tooltip: 'Tickets',
              ),
            ),
            const SizedBox(width: 4),
            IconButton(
              icon: Icon(isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
              onPressed: () => ref.read(themeProvider.notifier).toggleTheme(),
              tooltip: 'Toggle theme',
            ),
            const SizedBox(width: 8),
            if (user != null)
              AvatarWidget(
                imageUrl: user.avatar,
                initials: '${user.firstName[0]}${user.lastName[0]}',
                size: 36,
              ),
          ],
        ),
      ),
    );
  }
}

class _MobileShell extends ConsumerWidget {
  final Widget child;
  final int selectedIndex;
  final ValueChanged<int> onNavigate;

  const _MobileShell({
    required this.child,
    required this.selectedIndex,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final unread = ref.watch(unreadTicketCountProvider);
    final scaffoldKey = GlobalKey<ScaffoldState>();

    return Scaffold(
      key: scaffoldKey,
      appBar: _AppBar(
        title: 'AutoCreat',
        showDrawerButton: true,
        onMenuTap: () => scaffoldKey.currentState?.openDrawer(),
      ),
      drawer: _SideDrawer(selectedIndex: selectedIndex, onNavigate: onNavigate),
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: selectedIndex.clamp(0, 4),
          onTap: onNavigate,
          items: _navItems
              .take(5)
              .map(
                (item) => BottomNavigationBarItem(
                  icon: item.hasBadge && unread > 0
                      ? badges.Badge(
                          badgeContent: Text(unread.toString(),
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 9)),
                          child: Icon(item.icon),
                        )
                      : Icon(item.icon),
                  activeIcon: Icon(item.selectedIcon),
                  label: item.label,
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

class _SideDrawer extends ConsumerWidget {
  final int selectedIndex;
  final ValueChanged<int> onNavigate;

  const _SideDrawer({
    required this.selectedIndex,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = ref.watch(currentUserProvider);
    final unread = ref.watch(unreadTicketCountProvider);

    return Drawer(
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      shape: const RoundedRectangleBorder(),
      child: Column(
        children: [
          _SidebarHeader(user: user),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _navItems.length,
              itemBuilder: (context, index) {
                final item = _navItems[index];
                final selected = selectedIndex == index;
                return _NavTile(
                  item: item,
                  selected: selected,
                  badgeCount: item.hasBadge ? unread : 0,
                  expanded: true,
                  onTap: () {
                    Navigator.pop(context);
                    onNavigate(index);
                  },
                );
              },
            ),
          ),
          _SidebarFooter(onLogout: () => ref.read(authProvider.notifier).logout()),
        ],
      ),
    );
  }
}

class _CollapsedSidebarShell extends ConsumerWidget {
  final Widget child;
  final int selectedIndex;
  final ValueChanged<int> onNavigate;

  const _CollapsedSidebarShell({
    required this.child,
    required this.selectedIndex,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final unread = ref.watch(unreadTicketCountProvider);
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: _AppBar(title: 'AutoCreat'),
      body: Row(
        children: [
          Container(
            width: 72,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              border: Border(
                right: BorderSide(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
            ),
            child: Column(
              children: [
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemCount: _navItems.length,
                    itemBuilder: (context, index) {
                      final item = _navItems[index];
                      final selected = selectedIndex == index;
                      return Tooltip(
                        message: item.label,
                        preferBelow: false,
                        child: _NavTile(
                          item: item,
                          selected: selected,
                          badgeCount: item.hasBadge ? unread : 0,
                          expanded: false,
                          onTap: () => onNavigate(index),
                        ),
                      );
                    },
                  ),
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: AvatarWidget(
                    imageUrl: user?.avatar,
                    initials: user != null
                        ? '${user.firstName[0]}${user.lastName[0]}'
                        : '?',
                    size: 36,
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _FullSidebarShell extends ConsumerWidget {
  final Widget child;
  final int selectedIndex;
  final ValueChanged<int> onNavigate;

  const _FullSidebarShell({
    required this.child,
    required this.selectedIndex,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final unread = ref.watch(unreadTicketCountProvider);
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: _AppBar(title: 'AutoCreat'),
      body: Row(
        children: [
          Container(
            width: 240,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              border: Border(
                right: BorderSide(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SidebarHeader(user: user),
                const Divider(height: 1),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _navItems.length,
                    itemBuilder: (context, index) {
                      final item = _navItems[index];
                      final selected = selectedIndex == index;
                      return _NavTile(
                        item: item,
                        selected: selected,
                        badgeCount: item.hasBadge ? unread : 0,
                        expanded: true,
                        onTap: () => onNavigate(index),
                      );
                    },
                  ),
                ),
                const Divider(height: 1),
                _SidebarFooter(
                    onLogout: () =>
                        ref.read(authProvider.notifier).logout()),
              ],
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _SidebarHeader extends StatelessWidget {
  final dynamic user;

  const _SidebarHeader({this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.auto_awesome, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AutoCreat',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                ),
                if (user != null)
                  Text(
                    user.email ?? '',
                    style: Theme.of(context).textTheme.labelSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarFooter extends StatelessWidget {
  final VoidCallback onLogout;

  const _SidebarFooter({required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: ListTile(
        leading: const Icon(Icons.logout, size: 20, color: AppColors.error),
        title: const Text('Logout', style: TextStyle(color: AppColors.error)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
        dense: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        onTap: onLogout,
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  final _NavItem item;
  final bool selected;
  final int badgeCount;
  final bool expanded;
  final VoidCallback onTap;

  const _NavTile({
    required this.item,
    required this.selected,
    required this.badgeCount,
    required this.expanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: expanded
          ? const EdgeInsets.symmetric(horizontal: 8, vertical: 2)
          : const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: expanded
                ? const EdgeInsets.symmetric(horizontal: 12, vertical: 10)
                : const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.primary.withOpacity(isDark ? 0.2 : 0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: expanded
                ? Row(
                    children: [
                      badges.Badge(
                        showBadge: badgeCount > 0,
                        badgeContent: Text(
                          badgeCount.toString(),
                          style: const TextStyle(
                              color: Colors.white, fontSize: 9),
                        ),
                        child: Icon(
                          selected ? item.selectedIcon : item.icon,
                          size: 20,
                          color: selected
                              ? AppColors.primary
                              : (isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          item.label,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: selected
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: selected
                                ? AppColors.primary
                                : (isDark
                                    ? AppColors.darkText
                                    : AppColors.lightText),
                          ),
                        ),
                      ),
                    ],
                  )
                : Center(
                    child: badges.Badge(
                      showBadge: badgeCount > 0,
                      badgeContent: Text(
                        badgeCount.toString(),
                        style: const TextStyle(color: Colors.white, fontSize: 9),
                      ),
                      child: Icon(
                        selected ? item.selectedIcon : item.icon,
                        size: 22,
                        color: selected
                            ? AppColors.primary
                            : (isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary),
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

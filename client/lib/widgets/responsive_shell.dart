import 'dart:ui';

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
  final String section;

  const _NavItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.route,
    this.hasBadge = false,
    this.section = '',
  });
}

final _navItems = [
  const _NavItem(
    label: 'Dashboard',
    icon: Icons.dashboard_outlined,
    selectedIcon: Icons.dashboard_rounded,
    route: AppRoutes.dashboard,
    section: 'Overview',
  ),
  const _NavItem(
    label: 'Companies',
    icon: Icons.business_outlined,
    selectedIcon: Icons.business_rounded,
    route: AppRoutes.companies,
    section: 'Organization',
  ),
  const _NavItem(
    label: 'Users',
    icon: Icons.people_outline_rounded,
    selectedIcon: Icons.people_rounded,
    route: AppRoutes.users,
    section: 'Organization',
  ),
  const _NavItem(
    label: 'Roles',
    icon: Icons.shield_outlined,
    selectedIcon: Icons.shield_rounded,
    route: AppRoutes.roles,
    section: 'Organization',
  ),
  const _NavItem(
    label: 'Flows',
    icon: Icons.account_tree_outlined,
    selectedIcon: Icons.account_tree_rounded,
    route: AppRoutes.flows,
    section: 'Automation',
  ),
  const _NavItem(
    label: 'Forms',
    icon: Icons.dynamic_form_outlined,
    selectedIcon: Icons.dynamic_form_rounded,
    route: AppRoutes.forms,
    section: 'Automation',
  ),
  const _NavItem(
    label: 'Models',
    icon: Icons.data_object_rounded,
    selectedIcon: Icons.data_object_rounded,
    route: AppRoutes.models,
    section: 'Automation',
  ),
  const _NavItem(
    label: 'Letters',
    icon: Icons.mail_outline_rounded,
    selectedIcon: Icons.mail_rounded,
    route: AppRoutes.letters,
    section: 'Communication',
  ),
  const _NavItem(
    label: 'Tickets',
    icon: Icons.support_agent_outlined,
    selectedIcon: Icons.support_agent_rounded,
    route: AppRoutes.tickets,
    hasBadge: true,
    section: 'Communication',
  ),
];

class ResponsiveShell extends ConsumerStatefulWidget {
  final Widget child;

  const ResponsiveShell({super.key, required this.child});

  @override
  ConsumerState<ResponsiveShell> createState() => _ResponsiveShellState();
}

class _ResponsiveShellState extends ConsumerState<ResponsiveShell> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
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
    final isMobile = width < 768;
    final isTablet = width >= 768 && width < 1100;

    if (isMobile) {
      return _buildMobileLayout();
    }
    if (isTablet) {
      return _buildTabletLayout();
    }
    return _buildDesktopLayout();
  }

  Widget _buildMobileLayout() {
    final topPadding = MediaQuery.of(context).padding.top;
    const barHeight = 58.0;
    const barMarginTop = 10.0;
    const barMarginH = 12.0;
    final floatingTopOffset = topPadding + barMarginTop;
    final contentTopPadding = floatingTopOffset + barHeight + barMarginTop;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      drawer: _SidebarDrawer(
        selectedIndex: _selectedIndex,
        onNavigate: (i) {
          _scaffoldKey.currentState?.closeDrawer();
          _navigate(i);
        },
      ),
      body: Stack(
        children: [
          // Page content – padded below the floating bar
          Positioned.fill(
            top: contentTopPadding,
            child: widget.child,
          ),
          // Floating top bar
          Positioned(
            top: floatingTopOffset,
            left: barMarginH,
            right: barMarginH,
            height: barHeight,
            child: _FloatingMobileBar(
              onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabletLayout() {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Row(
        children: [
          _CollapsedSidebar(
            selectedIndex: _selectedIndex,
            onNavigate: _navigate,
          ),
          Expanded(
            child: Column(
              children: [
                const _TopBar(showMenuButton: false),
                Expanded(child: widget.child),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Row(
        children: [
          _FullSidebar(
            selectedIndex: _selectedIndex,
            onNavigate: _navigate,
          ),
          Expanded(
            child: Column(
              children: [
                const _TopBar(showMenuButton: false),
                Expanded(child: widget.child),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────
// FLOATING MOBILE BAR (new)
// ────────────────────────────────────────────────────────────────

class _FloatingMobileBar extends ConsumerWidget {
  final VoidCallback onMenuTap;

  const _FloatingMobileBar({required this.onMenuTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final unread = ref.watch(unreadTicketCountProvider);
    final user = ref.watch(currentUserProvider);

    final bgColor = isDark
        ? AppColors.darkCard.withValues(alpha: 0.94)
        : AppColors.lightCard.withValues(alpha: 0.94);

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.06),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.10),
                blurRadius: 24,
                spreadRadius: 0,
                offset: const Offset(0, 6),
              ),
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              // Hamburger menu
              _BarIconButton(
                icon: Icons.menu_rounded,
                onTap: onMenuTap,
                tooltip: 'Menu',
              ),
              const SizedBox(width: 8),
              // Logo
              const _LogoMark(compact: true),
              const Spacer(),
              // Search (compact icon)
              _BarIconButton(
                icon: Icons.search_rounded,
                onTap: () {},
                tooltip: 'Search',
              ),
              const SizedBox(width: 2),
              // Notification bell with badge
              badges.Badge(
                showBadge: unread > 0,
                badgeStyle: const badges.BadgeStyle(
                  badgeColor: AppColors.error,
                  padding: EdgeInsets.all(4),
                ),
                badgeContent: Text(
                  unread > 9 ? '9+' : unread.toString(),
                  style: const TextStyle(color: Colors.white, fontSize: 9),
                ),
                child: _BarIconButton(
                  icon: Icons.notifications_outlined,
                  onTap: () => GoRouter.of(context).go(AppRoutes.tickets),
                  tooltip: 'Notifications',
                ),
              ),
              const SizedBox(width: 2),
              // Theme toggle
              _BarIconButton(
                icon: isDark
                    ? Icons.light_mode_outlined
                    : Icons.dark_mode_outlined,
                onTap: () => ref.read(themeProvider.notifier).toggleTheme(),
                tooltip: 'Toggle theme',
              ),
              const SizedBox(width: 6),
              // Avatar
              if (user != null)
                AvatarWidget(
                  imageUrl: user.avatar,
                  initials: '${user.firstName[0]}${user.lastName[0]}',
                  size: 32,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BarIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;

  const _BarIconButton({
    required this.icon,
    required this.onTap,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(7),
          child: Icon(icon, size: 20, color: cs.onSurface.withValues(alpha: 0.75)),
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────
// TOP BAR (tablet / desktop)
// ────────────────────────────────────────────────────────────────

class _TopBar extends ConsumerWidget implements PreferredSizeWidget {
  final bool showMenuButton;

  const _TopBar({this.showMenuButton = false});

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final user = ref.watch(currentUserProvider);
    final unread = ref.watch(unreadTicketCountProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final topBarBg =
        isDark ? AppColors.darkSurface : AppColors.lightSurface;

    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: topBarBg,
        border: Border(
          bottom: BorderSide(
              color: cs.outline.withValues(alpha: 0.45), width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.28 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            if (showMenuButton) ...[
              IconButton(
                icon: const Icon(Icons.menu_rounded, size: 22),
                onPressed: null,
                style: IconButton.styleFrom(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(width: 4),
              const _LogoMark(compact: true),
            ],
            const Spacer(),
            // Search field (only on tablet/desktop)
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 220, minWidth: 140),
              child: Container(
                height: 36,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: cs.outline.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 10),
                    Icon(Icons.search_rounded,
                        size: 16,
                        color: cs.onSurface.withValues(alpha: 0.4)),
                    const SizedBox(width: 6),
                    Text(
                      'Search...',
                      style: TextStyle(
                          fontSize: 13,
                          color: cs.onSurface.withValues(alpha: 0.4)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Notifications
            badges.Badge(
              showBadge: unread > 0,
              badgeStyle: const badges.BadgeStyle(
                  badgeColor: AppColors.error, padding: EdgeInsets.all(4)),
              badgeContent: Text(
                unread > 9 ? '9+' : unread.toString(),
                style: const TextStyle(color: Colors.white, fontSize: 9),
              ),
              child: IconButton(
                icon: const Icon(Icons.notifications_outlined, size: 20),
                onPressed: () => GoRouter.of(context).go(AppRoutes.tickets),
                tooltip: 'Tickets',
                style: IconButton.styleFrom(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
            // Theme toggle
            IconButton(
              icon: Icon(
                isDark
                    ? Icons.light_mode_outlined
                    : Icons.dark_mode_outlined,
                size: 20,
              ),
              onPressed: () =>
                  ref.read(themeProvider.notifier).toggleTheme(),
              tooltip: 'Toggle theme',
              style: IconButton.styleFrom(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(width: 4),
            if (user != null)
              AvatarWidget(
                imageUrl: user.avatar,
                initials: '${user.firstName[0]}${user.lastName[0]}',
                size: 34,
              ),
          ],
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────
// LOGO
// ────────────────────────────────────────────────────────────────

class _LogoMark extends StatelessWidget {
  final bool compact;

  const _LogoMark({this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: compact ? 28 : 34,
          height: compact ? 28 : 34,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.primaryLight],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(compact ? 8 : 10),
          ),
          child: Icon(
            Icons.auto_awesome_rounded,
            color: Colors.white,
            size: compact ? 16 : 20,
          ),
        ),
        if (!compact) ...[
          const SizedBox(width: 10),
          const Text(
            'AutoCreat',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ],
    );
  }
}

// ────────────────────────────────────────────────────────────────
// FULL SIDEBAR (desktop)
// ────────────────────────────────────────────────────────────────

class _FullSidebar extends ConsumerWidget {
  final int selectedIndex;
  final ValueChanged<int> onNavigate;

  const _FullSidebar({required this.selectedIndex, required this.onNavigate});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final user = ref.watch(currentUserProvider);
    final unread = ref.watch(unreadTicketCountProvider);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sidebarBg =
        isDark ? AppColors.darkSurface : AppColors.lightSurface;

    return Container(
      width: 248,
      decoration: BoxDecoration(
        color: sidebarBg,
        border: Border(
          right: BorderSide(color: cs.outline.withValues(alpha: 0.4)),
        ),
      ),
      child: Column(
        children: [
          // Logo header
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              border: Border(
                bottom:
                    BorderSide(color: cs.outline.withValues(alpha: 0.4)),
              ),
            ),
            child: const Align(
              alignment: Alignment.centerLeft,
              child: _LogoMark(),
            ),
          ),

          // User card
          _SidebarUserCard(user: user),

          // Nav items grouped by section
          Expanded(
            child: _SidebarNavList(
              selectedIndex: selectedIndex,
              unread: unread,
              onNavigate: onNavigate,
              expanded: true,
            ),
          ),

          // Logout
          _LogoutTile(
              onLogout: () => ref.read(authProvider.notifier).logout()),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────
// COLLAPSED SIDEBAR (tablet)
// ────────────────────────────────────────────────────────────────

class _CollapsedSidebar extends ConsumerWidget {
  final int selectedIndex;
  final ValueChanged<int> onNavigate;

  const _CollapsedSidebar(
      {required this.selectedIndex, required this.onNavigate});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final unread = ref.watch(unreadTicketCountProvider);
    final user = ref.watch(currentUserProvider);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sidebarBg =
        isDark ? AppColors.darkSurface : AppColors.lightSurface;

    return Container(
      width: 68,
      decoration: BoxDecoration(
        color: sidebarBg,
        border: Border(
          right: BorderSide(color: cs.outline.withValues(alpha: 0.4)),
        ),
      ),
      child: Column(
        children: [
          Container(
            height: 60,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border:
                  Border(bottom: BorderSide(color: cs.outline.withValues(alpha: 0.4))),
            ),
            child: const _LogoMark(compact: true),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 4),
              itemCount: _navItems.length,
              itemBuilder: (context, i) => Tooltip(
                message: _navItems[i].label,
                preferBelow: false,
                child: _NavIcon(
                  item: _navItems[i],
                  selected: selectedIndex == i,
                  badgeCount: _navItems[i].hasBadge ? unread : 0,
                  onTap: () => onNavigate(i),
                ),
              ),
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: user != null
                ? AvatarWidget(
                    imageUrl: user.avatar,
                    initials:
                        '${user.firstName[0]}${user.lastName[0]}',
                    size: 34,
                  )
                : const SizedBox.shrink(),
          ),
          Tooltip(
            message: 'Logout',
            child: IconButton(
              icon: const Icon(Icons.logout_rounded,
                  size: 20, color: AppColors.error),
              onPressed: () => ref.read(authProvider.notifier).logout(),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────
// DRAWER (mobile)
// ────────────────────────────────────────────────────────────────

class _SidebarDrawer extends ConsumerWidget {
  final int selectedIndex;
  final ValueChanged<int> onNavigate;

  const _SidebarDrawer(
      {required this.selectedIndex, required this.onNavigate});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final unread = ref.watch(unreadTicketCountProvider);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final drawerBg =
        isDark ? AppColors.darkSurface : AppColors.lightSurface;

    return Drawer(
      backgroundColor: drawerBg,
      width: 280,
      shape: const RoundedRectangleBorder(),
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  const _LogoMark(),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                    style: IconButton.styleFrom(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
            ),
            _SidebarUserCard(user: user),
            Expanded(
              child: _SidebarNavList(
                selectedIndex: selectedIndex,
                unread: unread,
                onNavigate: onNavigate,
                expanded: true,
              ),
            ),
            _LogoutTile(
                onLogout: () => ref.read(authProvider.notifier).logout()),
          ],
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────
// SHARED SIDEBAR COMPONENTS
// ────────────────────────────────────────────────────────────────

class _SidebarUserCard extends StatelessWidget {
  final dynamic user;

  const _SidebarUserCard({this.user});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (user == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          AvatarWidget(
            imageUrl: user.avatar,
            initials: '${user.firstName[0]}${user.lastName[0]}',
            size: 36,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${user.firstName} ${user.lastName}',
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  user.email ?? '',
                  style: TextStyle(
                      fontSize: 11,
                      color: cs.onSurface.withValues(alpha: 0.5)),
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

class _SidebarNavList extends StatelessWidget {
  final int selectedIndex;
  final int unread;
  final ValueChanged<int> onNavigate;
  final bool expanded;

  const _SidebarNavList({
    required this.selectedIndex,
    required this.unread,
    required this.onNavigate,
    required this.expanded,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    String? lastSection;
    final widgets = <Widget>[];

    for (int i = 0; i < _navItems.length; i++) {
      final item = _navItems[i];
      if (item.section != lastSection) {
        lastSection = item.section;
        if (expanded && item.section.isNotEmpty) {
          widgets.add(Padding(
            padding:
                const EdgeInsets.fromLTRB(20, 16, 20, 6),
            child: Text(
              item.section.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: cs.onSurface.withValues(alpha: 0.35),
                letterSpacing: 1.0,
              ),
            ),
          ));
        }
      }
      widgets.add(_NavTile(
        item: item,
        selected: selectedIndex == i,
        badgeCount: item.hasBadge ? unread : 0,
        onTap: () => onNavigate(i),
      ));
    }

    return ListView(
      padding: const EdgeInsets.only(top: 4, bottom: 8),
      children: widgets,
    );
  }
}

class _NavTile extends StatelessWidget {
  final _NavItem item;
  final bool selected;
  final int badgeCount;
  final VoidCallback onTap;

  const _NavTile({
    required this.item,
    required this.selected,
    required this.badgeCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 1),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.primary.withValues(alpha: 0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                badges.Badge(
                  showBadge: badgeCount > 0,
                  badgeStyle: const badges.BadgeStyle(
                    badgeColor: AppColors.error,
                    padding: EdgeInsets.all(3),
                  ),
                  badgeContent: Text(
                    badgeCount > 9 ? '9+' : badgeCount.toString(),
                    style: const TextStyle(color: Colors.white, fontSize: 8),
                  ),
                  child: Icon(
                    selected ? item.selectedIcon : item.icon,
                    size: 19,
                    color: selected
                        ? AppColors.primary
                        : cs.onSurface.withValues(alpha: 0.55),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item.label,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight:
                          selected ? FontWeight.w600 : FontWeight.w400,
                      color: selected
                          ? AppColors.primary
                          : cs.onSurface.withValues(alpha: 0.8),
                    ),
                  ),
                ),
                if (selected)
                  Container(
                    width: 4,
                    height: 4,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
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

class _NavIcon extends StatelessWidget {
  final _NavItem item;
  final bool selected;
  final int badgeCount;
  final VoidCallback onTap;

  const _NavIcon({
    required this.item,
    required this.selected,
    required this.badgeCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.primary.withValues(alpha: 0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: badges.Badge(
                showBadge: badgeCount > 0,
                badgeStyle: const badges.BadgeStyle(
                  badgeColor: AppColors.error,
                  padding: EdgeInsets.all(3),
                ),
                badgeContent: Text(
                  badgeCount.toString(),
                  style: const TextStyle(color: Colors.white, fontSize: 8),
                ),
                child: Icon(
                  selected ? item.selectedIcon : item.icon,
                  size: 22,
                  color: selected
                      ? AppColors.primary
                      : cs.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LogoutTile extends StatelessWidget {
  final VoidCallback onLogout;

  const _LogoutTile({required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 4, 10, 12),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onLogout,
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(Icons.logout_rounded,
                    size: 19, color: AppColors.error.withValues(alpha: 0.8)),
                const SizedBox(width: 12),
                Text(
                  'Sign Out',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                    color: AppColors.error.withValues(alpha: 0.85),
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

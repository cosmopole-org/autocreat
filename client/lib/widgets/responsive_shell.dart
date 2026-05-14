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
    final mediaQuery = MediaQuery.of(context);
    final topPadding = mediaQuery.padding.top;
    const barHeight = 46.0;
    const barMarginTop = 14.0;
    const barMarginH = 28.0;
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
          // Page content fills the shell; the floating bar overlays it.
          // The injected top padding lets inner page content start below the
          // overlay while scrollable content can still move underneath it.
          Positioned.fill(
            child: MediaQuery(
              data: mediaQuery.copyWith(
                padding: mediaQuery.padding.copyWith(top: contentTopPadding),
              ),
              child: widget.child,
            ),
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
    final glassMode = ref.watch(glassModeProvider);

    final bgColor = glassMode
        ? Colors.white.withValues(alpha: isDark ? 0.11 : 0.58)
        : isDark
            ? AppColors.darkCard.withValues(alpha: 0.94)
            : AppColors.lightCard.withValues(alpha: 0.94);

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: glassMode ? 24 : 16,
          sigmaY: glassMode ? 24 : 16,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.06),
              width: 1,
            ),
            gradient: glassMode
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withValues(alpha: isDark ? 0.16 : 0.74),
                      Colors.white.withValues(alpha: isDark ? 0.05 : 0.34),
                    ],
                  )
                : null,
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
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            children: [
              // Hamburger menu
              _BarIconButton(
                icon: Icons.menu_rounded,
                onTap: onMenuTap,
                tooltip: 'Menu',
              ),
              const SizedBox(width: 6),
              // Logo
              const _LogoMark(compact: true, tiny: true),
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
              const SizedBox(width: 2),
              const _GlassModeButton(compact: true),
              const SizedBox(width: 4),
              // Avatar
              if (user != null)
                AvatarWidget(
                  imageUrl: user.avatar,
                  initials: '${user.firstName[0]}${user.lastName[0]}',
                  size: 28,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BarIconButton extends ConsumerWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;

  const _BarIconButton({
    required this.icon,
    required this.onTap,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final glassMode = ref.watch(glassModeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Tooltip(
      message: tooltip,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(glassMode ? 11 : 9),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: glassMode ? 10 : 0,
            sigmaY: glassMode ? 10 : 0,
          ),
          child: Material(
            color: glassMode
                ? Colors.white.withValues(alpha: isDark ? 0.06 : 0.28)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(glassMode ? 11 : 9),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(glassMode ? 11 : 9),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(glassMode ? 11 : 9),
                  border: glassMode
                      ? Border.all(
                          color: Colors.white.withValues(
                            alpha: isDark ? 0.10 : 0.42,
                          ),
                        )
                      : null,
                ),
                child: Icon(
                  icon,
                  size: 18,
                  color: cs.onSurface.withValues(alpha: 0.75),
                ),
              ),
            ),
          ),
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
    final glassMode = ref.watch(glassModeProvider);

    final topBarBg = glassMode
        ? Colors.white.withValues(alpha: isDark ? 0.08 : 0.48)
        : isDark
            ? AppColors.darkSurface
            : AppColors.lightSurface;

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: glassMode ? 18 : 0, sigmaY: glassMode ? 18 : 0),
        child: Container(
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
        padding: const EdgeInsets.symmetric(horizontal: 20),
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
                  color: glassMode ? Colors.white.withValues(alpha: isDark ? 0.08 : 0.42) : (isDark ? AppColors.darkSurface : AppColors.lightSurface),
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
            const SizedBox(width: 2),
            const _GlassModeButton(),
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
        ),
      ),
    );
  }
}


class _GlassModeButton extends ConsumerWidget {
  final bool compact;

  const _GlassModeButton({this.compact = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final glassMode = ref.watch(glassModeProvider);
    final cs = Theme.of(context).colorScheme;
    final icon = glassMode ? Icons.blur_on_rounded : Icons.blur_off_rounded;

    if (compact) {
      return _BarIconButton(
        icon: icon,
        onTap: () => ref.read(glassModeProvider.notifier).toggleGlassMode(),
        tooltip: glassMode ? 'Disable glass mode' : 'Enable glass mode',
      );
    }

    return Tooltip(
      message: glassMode ? 'Disable glass mode' : 'Enable glass mode',
      child: IconButton(
        icon: Icon(
          icon,
          size: 20,
          color: glassMode ? AppColors.primary : cs.onSurface.withValues(alpha: 0.82),
        ),
        onPressed: () => ref.read(glassModeProvider.notifier).toggleGlassMode(),
        style: IconButton.styleFrom(
          backgroundColor: glassMode ? AppColors.primary.withValues(alpha: 0.12) : null,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
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
  final bool tiny;

  const _LogoMark({this.compact = false, this.tiny = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: tiny ? 26 : (compact ? 28 : 34),
          height: tiny ? 26 : (compact ? 28 : 34),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.primaryLight],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(tiny ? 7 : (compact ? 8 : 10)),
          ),
          child: Icon(
            Icons.auto_awesome_rounded,
            color: Colors.white,
            size: tiny ? 15 : (compact ? 16 : 20),
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
    final glassMode = ref.watch(glassModeProvider);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sidebarBg = glassMode
        ? Colors.white.withValues(alpha: isDark ? 0.07 : 0.46)
        : isDark
            ? AppColors.darkSurface
            : AppColors.lightSurface;

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
    final glassMode = ref.watch(glassModeProvider);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sidebarBg = glassMode
        ? Colors.white.withValues(alpha: isDark ? 0.07 : 0.46)
        : isDark
            ? AppColors.darkSurface
            : AppColors.lightSurface;

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
    final glassMode = ref.watch(glassModeProvider);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final drawerBg = glassMode
        ? Colors.white.withValues(alpha: isDark ? 0.08 : 0.58)
        : isDark
            ? AppColors.darkSurface
            : AppColors.lightSurface;
    final drawerRadius = BorderRadius.horizontal(
      right: Radius.circular(glassMode ? 28 : 24),
    );
    final drawerGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: glassMode
          ? [
              Color.alphaBlend(
                AppColors.primary.withValues(alpha: isDark ? 0.16 : 0.12),
                Colors.white.withValues(alpha: isDark ? 0.09 : 0.62),
              ),
              Color.alphaBlend(
                AppColors.accent.withValues(alpha: isDark ? 0.12 : 0.10),
                Colors.white.withValues(alpha: isDark ? 0.045 : 0.34),
              ),
            ]
          : [
              Color.alphaBlend(
                AppColors.primary.withValues(alpha: isDark ? 0.13 : 0.08),
                drawerBg,
              ),
              Color.alphaBlend(
                AppColors.accent.withValues(alpha: isDark ? 0.09 : 0.055),
                drawerBg,
              ),
            ],
    );
    final drawerBorder = Border(
      right: BorderSide(
        color: glassMode
            ? Colors.white.withValues(alpha: isDark ? 0.13 : 0.56)
            : (isDark ? AppColors.darkBorder : AppColors.lightBorder)
                .withValues(alpha: 0.75),
      ),
    );

    final content = SafeArea(
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                const _LogoMark(),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                  style: IconButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(glassMode ? 14 : 8),
                    ),
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
            onLogout: () => ref.read(authProvider.notifier).logout(),
          ),
        ],
      ),
    );

    if (!glassMode) {
      return Drawer(
        backgroundColor: Colors.transparent,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        width: 280,
        shape: RoundedRectangleBorder(borderRadius: drawerRadius),
        child: ClipRRect(
          borderRadius: drawerRadius,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: drawerBg,
              gradient: drawerGradient,
              border: drawerBorder,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.24 : 0.08),
                  blurRadius: 20,
                  offset: const Offset(8, 0),
                ),
              ],
            ),
            child: content,
          ),
        ),
      );
    }

    return Drawer(
      backgroundColor: Colors.transparent,
      elevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      width: 292,
      shape: RoundedRectangleBorder(borderRadius: drawerRadius),
      child: ClipRRect(
        borderRadius: drawerRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 26, sigmaY: 26),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: drawerBg,
              gradient: drawerGradient,
              border: drawerBorder,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.34 : 0.12),
                  blurRadius: 28,
                  offset: const Offset(10, 0),
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned(
                  top: -80,
                  left: -70,
                  child: _DrawerGlow(
                    color: AppColors.primary
                        .withValues(alpha: isDark ? 0.18 : 0.16),
                    size: 190,
                  ),
                ),
                Positioned(
                  right: -90,
                  bottom: 110,
                  child: _DrawerGlow(
                    color: AppColors.accent
                        .withValues(alpha: isDark ? 0.14 : 0.12),
                    size: 210,
                  ),
                ),
                content,
              ],
            ),
          ),
        ),
      ),
    );
  }
}


class _DrawerGlow extends StatelessWidget {
  final Color color;
  final double size;

  const _DrawerGlow({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, color.withValues(alpha: 0)],
          ),
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────
// SHARED SIDEBAR COMPONENTS
// ────────────────────────────────────────────────────────────────

class _SidebarUserCard extends ConsumerWidget {
  final dynamic user;

  const _SidebarUserCard({this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final glassMode = ref.watch(glassModeProvider);
    if (user == null) return const SizedBox.shrink();

    final cardContent = Row(
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
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                user.email ?? '',
                style: TextStyle(
                  fontSize: 11,
                  color: cs.onSurface.withValues(alpha: 0.5),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );

    if (glassMode) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
        child: GlassSurface(
          enabled: true,
          borderRadius: BorderRadius.circular(18),
          blur: 18,
          padding: const EdgeInsets.all(12),
          color: AppColors.primary.withValues(alpha: 0.10),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.18),
          ),
          child: cardContent,
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
      ),
      child: cardContent,
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

class _NavTile extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final glassMode = ref.watch(glassModeProvider);

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
                  ? AppColors.primary.withValues(alpha: glassMode ? 0.16 : 0.1)
                  : glassMode
                      ? Colors.white.withValues(alpha: 0.02)
                      : Colors.transparent,
              border: glassMode && selected
                  ? Border.all(color: Colors.white.withValues(alpha: 0.18))
                  : null,
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

class _NavIcon extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final glassMode = ref.watch(glassModeProvider);

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
                  ? AppColors.primary.withValues(alpha: glassMode ? 0.16 : 0.1)
                  : glassMode
                      ? Colors.white.withValues(alpha: 0.02)
                      : Colors.transparent,
              border: glassMode && selected
                  ? Border.all(color: Colors.white.withValues(alpha: 0.18))
                  : null,
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

class _LogoutTile extends ConsumerWidget {
  final VoidCallback onLogout;

  const _LogoutTile({required this.onLogout});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final glassMode = ref.watch(glassModeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 4, 10, 12),
      child: Material(
        color: glassMode
            ? AppColors.error.withValues(alpha: isDark ? 0.10 : 0.08)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(glassMode ? 14 : 10),
        child: InkWell(
          borderRadius: BorderRadius.circular(glassMode ? 14 : 10),
          onTap: onLogout,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(glassMode ? 14 : 10),
              border: glassMode
                  ? Border.all(
                      color: Colors.white.withValues(alpha: isDark ? 0.10 : 0.34),
                    )
                  : null,
            ),
            child: Row(
              children: [
                Icon(Icons.logout_rounded,
                    size: 19, color: AppColors.error.withValues(alpha: 0.8)),
                const SizedBox(width: 12),
                Text(
                  'Sign Out',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
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

import 'dart:ui';

import 'package:badges/badges.dart' as badges;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/constants.dart';
import '../providers/auth_provider.dart';
import '../providers/company_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/ticket_provider.dart';
import '../theme/app_colors.dart';
import 'common_widgets.dart';
import '../data/ui_text.dart';

class _NavItem {
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final String route;
  final bool hasBadge;
  final String section;

  _NavItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.route,
    this.hasBadge = false,
    this.section = '',
  });
}

List<_NavItem> get _navItems => [
  _NavItem(
    label: UiText.dashboard,
    icon: Icons.dashboard_outlined,
    selectedIcon: Icons.dashboard_rounded,
    route: AppRoutes.dashboard,
    section: UiText.overview,
  ),
  _NavItem(
    label: UiText.users,
    icon: Icons.people_outline_rounded,
    selectedIcon: Icons.people_rounded,
    route: AppRoutes.users,
    section: UiText.organization,
  ),
  _NavItem(
    label: UiText.roles,
    icon: Icons.shield_outlined,
    selectedIcon: Icons.shield_rounded,
    route: AppRoutes.roles,
    section: UiText.organization,
  ),
  _NavItem(
    label: UiText.flows,
    icon: Icons.account_tree_outlined,
    selectedIcon: Icons.account_tree_rounded,
    route: AppRoutes.flows,
    section: UiText.automation,
  ),
  _NavItem(
    label: UiText.forms,
    icon: Icons.dynamic_form_outlined,
    selectedIcon: Icons.dynamic_form_rounded,
    route: AppRoutes.forms,
    section: UiText.automation,
  ),
  _NavItem(
    label: UiText.models,
    icon: Icons.data_object_rounded,
    selectedIcon: Icons.data_object_rounded,
    route: AppRoutes.models,
    section: UiText.automation,
  ),
  _NavItem(
    label: UiText.letters,
    icon: Icons.mail_outline_rounded,
    selectedIcon: Icons.mail_rounded,
    route: AppRoutes.letters,
    section: UiText.communication,
  ),
  _NavItem(
    label: UiText.tickets,
    icon: Icons.support_agent_outlined,
    selectedIcon: Icons.support_agent_rounded,
    route: AppRoutes.tickets,
    hasBadge: true,
    section: UiText.communication,
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
                tooltip: UiText.menu,
              ),
              const SizedBox(width: 6),
              // Logo
              const _LogoMark(compact: true, tiny: true),
              const Spacer(),
              // Search (compact icon)
              _BarIconButton(
                icon: Icons.search_rounded,
                onTap: () {},
                tooltip: UiText.search,
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
                  tooltip: UiText.notifications,
                ),
              ),
              const SizedBox(width: 4),
              // Avatar
              if (user != null)
                AvatarWidget(
                  imageUrl: user.avatar,
                  initials: UiText.userInitials(user.firstName, user.lastName),
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
                      UiText.search3,
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
                tooltip: UiText.tickets,
                style: IconButton.styleFrom(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
            // Settings button
            IconButton(
              icon: const Icon(Icons.settings_outlined, size: 20),
              onPressed: () => GoRouter.of(context).go(AppRoutes.settings),
              tooltip: UiText.settingsButton,
              style: IconButton.styleFrom(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(width: 4),
            if (user != null)
              AvatarWidget(
                imageUrl: user.avatar,
                initials: UiText.userInitials(user.firstName, user.lastName),
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
          Text(
            UiText.autocreat,
            style: const TextStyle(
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
        border: BorderDirectional(
          end: BorderSide(color: cs.outline.withValues(alpha: 0.4)),
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
              alignment: AlignmentDirectional.centerStart,
              child: _LogoMark(),
            ),
          ),

          // User card
          _SidebarUserCard(user: user),

          // Company selector
          const _CompanySelector(),

          // Nav items grouped by section
          Expanded(
            child: _SidebarNavList(
              selectedIndex: selectedIndex,
              unread: unread,
              onNavigate: onNavigate,
              expanded: true,
            ),
          ),

          // Settings
          _SettingsTile(),

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
        border: BorderDirectional(
          end: BorderSide(color: cs.outline.withValues(alpha: 0.4)),
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
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: user != null
                ? AvatarWidget(
                    imageUrl: user.avatar,
                    initials:
                        UiText.userInitials(user.firstName, user.lastName),
                    size: 34,
                  )
                : const SizedBox.shrink(),
          ),
          Tooltip(
            message: UiText.settingsButton,
            child: IconButton(
              icon: const Icon(Icons.settings_outlined, size: 20),
              onPressed: () => GoRouter.of(context).go(AppRoutes.settings),
            ),
          ),
          Tooltip(
            message: UiText.logout,
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
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final drawerRadius = isRtl
        ? BorderRadius.horizontal(
            left: Radius.circular(glassMode ? 28 : 24),
          )
        : BorderRadius.horizontal(
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
          const _CompanySelector(),
          Expanded(
            child: _SidebarNavList(
              selectedIndex: selectedIndex,
              unread: unread,
              onNavigate: onNavigate,
              expanded: true,
            ),
          ),
          _SettingsTile(),
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
                PositionedDirectional(
                  top: -80,
                  start: -70,
                  child: _DrawerGlow(
                    color: AppColors.primary
                        .withValues(alpha: isDark ? 0.18 : 0.16),
                    size: 190,
                  ),
                ),
                PositionedDirectional(
                  end: -90,
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
          initials: UiText.userInitials(user.firstName, user.lastName),
          size: 36,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                UiText.userFullName(user.firstName, user.lastName),
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

// ────────────────────────────────────────────────────────────────
// COMPANY SELECTOR (sidebar dropdown)
// ────────────────────────────────────────────────────────────────

class _CompanySelector extends ConsumerWidget {
  const _CompanySelector();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final glassMode = ref.watch(glassModeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    final selectedId = ref.watch(selectedCompanyIdProvider);
    final companiesAsync = ref.watch(companiesProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
      child: companiesAsync.when(
        loading: () => _buildSelectorShell(
          context,
          glassMode: glassMode,
          isDark: isDark,
          cs: cs,
          child: Row(children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Container(
                height: 12,
                decoration: BoxDecoration(
                  color: cs.onSurface.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ]),
          onTap: null,
        ),
        error: (_, __) => const SizedBox.shrink(),
        data: (companies) {
          final selected = companies.where((c) => c.id == selectedId).firstOrNull;
          return _buildSelectorShell(
            context,
            glassMode: glassMode,
            isDark: isDark,
            cs: cs,
            child: Row(children: [
              // Company avatar
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.accent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(
                  selected != null ? selected.name[0].toUpperCase() : '?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      selected?.name ?? UiText.noCompanySelected,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: selected != null
                            ? cs.onSurface
                            : cs.onSurface.withValues(alpha: 0.5),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (selected?.industry != null)
                      Text(
                        selected!.industry!,
                        style: TextStyle(
                          fontSize: 10.5,
                          color: cs.onSurface.withValues(alpha: 0.45),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      )
                    else
                      Text(
                        UiText.workspace,
                        style: TextStyle(
                          fontSize: 10.5,
                          color: AppColors.primary.withValues(alpha: 0.7),
                        ),
                      ),
                  ],
                ),
              ),
              Icon(
                Icons.unfold_more_rounded,
                size: 18,
                color: cs.onSurface.withValues(alpha: 0.4),
              ),
            ]),
            onTap: companies.isEmpty
                ? null
                : () => _showCompanyPicker(context, ref, companies, selectedId),
          );
        },
      ),
    );
  }

  Widget _buildSelectorShell(
    BuildContext context, {
    required bool glassMode,
    required bool isDark,
    required ColorScheme cs,
    required Widget child,
    required VoidCallback? onTap,
  }) {
    final decoration = BoxDecoration(
      color: glassMode
          ? Colors.white.withValues(alpha: isDark ? 0.07 : 0.38)
          : AppColors.primary.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: glassMode
            ? Colors.white.withValues(alpha: isDark ? 0.12 : 0.45)
            : AppColors.primary.withValues(alpha: 0.18),
      ),
    );

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: decoration,
          child: child,
        ),
      ),
    );
  }

  void _showCompanyPicker(
    BuildContext context,
    WidgetRef ref,
    List<dynamic> companies,
    String? selectedId,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    final glassMode = ref.read(glassModeProvider);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        final bgColor = glassMode
            ? (isDark
                ? Colors.white.withValues(alpha: 0.10)
                : Colors.white.withValues(alpha: 0.68))
            : (isDark ? AppColors.darkCard : AppColors.lightCard);

        final column = Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: cs.onSurface.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Title
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.accent],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.business_rounded,
                      size: 18, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Text(
                  UiText.selectCompanyTitle,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
              ]),
            ),
            const Divider(height: 1),
            // Company list
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 320),
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                shrinkWrap: true,
                itemCount: companies.length,
                itemBuilder: (ctx, i) {
                  final c = companies[i];
                  final isSelected = c.id == selectedId;
                  return ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary.withValues(
                                alpha: isSelected ? 1.0 : 0.7),
                            AppColors.accent.withValues(
                                alpha: isSelected ? 1.0 : 0.7),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        c.name[0].toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    title: Text(
                      c.name,
                      style: TextStyle(
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: isSelected
                            ? AppColors.primary
                            : cs.onSurface,
                      ),
                    ),
                    subtitle: c.industry != null
                        ? Text(
                            c.industry!,
                            style: TextStyle(
                              fontSize: 12,
                              color: cs.onSurface.withValues(alpha: 0.5),
                            ),
                          )
                        : null,
                    trailing: isSelected
                        ? Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(Icons.check_rounded,
                                size: 14, color: Colors.white),
                          )
                        : null,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    onTap: () {
                      ref.read(selectedCompanyIdProvider.notifier).state = c.id;
                      ref
                          .read(sharedPreferencesProvider)
                          .setString(AppConstants.lastCompanyKey, c.id);
                      Navigator.of(ctx).pop();
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
          ],
        );

        final innerContent = glassMode
            ? ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                  child: column,
                ),
              )
            : column;

        return Container(
          margin: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: bgColor,
            gradient: glassMode
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withValues(alpha: isDark ? 0.16 : 0.84),
                      Colors.white.withValues(alpha: isDark ? 0.05 : 0.42),
                    ],
                  )
                : null,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: glassMode
                  ? Colors.white.withValues(alpha: isDark ? 0.14 : 0.55)
                  : cs.outline.withValues(alpha: 0.15),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.12),
                blurRadius: 32,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: innerContent,
        );
      },
    );
  }
}

// ────────────────────────────────────────────────────────────────
// SETTINGS TILE (sidebar)
// ────────────────────────────────────────────────────────────────

class _SettingsTile extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final glassMode = ref.watch(glassModeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    final currentLocation = GoRouterState.of(context).matchedLocation;
    final isSelected = currentLocation == AppRoutes.settings;

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 2, 10, 2),
      child: Material(
        color: glassMode
            ? AppColors.primary.withValues(alpha: isDark ? 0.08 : 0.06)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(glassMode ? 14 : 10),
        child: InkWell(
          borderRadius: BorderRadius.circular(glassMode ? 14 : 10),
          onTap: () => GoRouter.of(context).go(AppRoutes.settings),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary.withValues(alpha: glassMode ? 0.16 : 0.1)
                  : null,
              borderRadius: BorderRadius.circular(glassMode ? 14 : 10),
              border: glassMode
                  ? Border.all(
                      color: Colors.white.withValues(
                          alpha: isDark ? 0.10 : 0.34),
                    )
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  isSelected
                      ? Icons.settings_rounded
                      : Icons.settings_outlined,
                  size: 19,
                  color: isSelected
                      ? AppColors.primary
                      : cs.onSurface.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 12),
                Text(
                  UiText.settingsButton,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected
                        ? AppColors.primary
                        : cs.onSurface.withValues(alpha: 0.8),
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
                  UiText.signOut,
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

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/theme_provider.dart';

/// A modern iOS-style horizontal tab bar with pill-shaped selected indicator.
///
/// Supports horizontal scrolling for many tabs, glass-morphism overlay mode,
/// and smooth animated segment transitions.
class IosTabBar extends ConsumerStatefulWidget {
  final List<String> tabs;
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;

  /// When true, the bar wraps itself in a frosted-glass container suitable
  /// for use as a sticky overlay that floats above scroll content.
  final bool isOverlay;

  const IosTabBar({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onTabSelected,
    this.isOverlay = false,
  });

  static const double barHeight = 52.0;

  @override
  ConsumerState<IosTabBar> createState() => _IosTabBarState();
}

class _IosTabBarState extends ConsumerState<IosTabBar> {
  final ScrollController _scrollController = ScrollController();

  // Approximate per-tab width used for auto-scrolling the selected tab into view.
  static const double _tabApproxWidth = 110.0;

  @override
  void didUpdateWidget(IosTabBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndex != widget.selectedIndex) {
      _scrollToSelected();
    }
  }

  void _scrollToSelected() {
    if (!_scrollController.hasClients) return;
    final target = (widget.selectedIndex * _tabApproxWidth - 40.0)
        .clamp(0.0, _scrollController.position.maxScrollExtent);
    _scrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final glassMode = ref.watch(glassModeProvider);

    Widget bar = SizedBox(
      height: IosTabBar.barHeight,
      child: SingleChildScrollView(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        child: _Segments(
          tabs: widget.tabs,
          selectedIndex: widget.selectedIndex,
          onTabSelected: widget.onTabSelected,
          isDark: isDark,
        ),
      ),
    );

    if (!widget.isOverlay) return bar;

    // Overlay mode: wrap in a frosted-glass container.
    final bgColor = glassMode
        ? (isDark
            ? Colors.white.withValues(alpha: 0.07)
            : Colors.white.withValues(alpha: 0.72))
        : Theme.of(context).colorScheme.surface;

    final decorated = DecoratedBox(
      decoration: BoxDecoration(
        color: bgColor,
        gradient: glassMode
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: isDark ? 0.12 : 0.80),
                  Colors.white.withValues(alpha: isDark ? 0.04 : 0.46),
                ],
              )
            : null,
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.07)
                : Colors.black.withValues(alpha: 0.06),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.05),
            blurRadius: glassMode ? 20 : 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: bar,
    );

    if (!glassMode) return decorated;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: decorated,
      ),
    );
  }
}

// ── Segments row ──────────────────────────────────────────────────

class _Segments extends StatelessWidget {
  final List<String> tabs;
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;
  final bool isDark;

  const _Segments({
    required this.tabs,
    required this.selectedIndex,
    required this.onTabSelected,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final segBg = isDark
        ? Colors.white.withValues(alpha: 0.10)
        : Colors.black.withValues(alpha: 0.06);

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: segBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(
          tabs.length,
          (i) => _Pill(
            label: tabs[i],
            isSelected: i == selectedIndex,
            onTap: () => onTabSelected(i),
            isDark: isDark,
          ),
        ),
      ),
    );
  }
}

// ── Individual pill segment ───────────────────────────────────────

class _Pill extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDark;

  const _Pill({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final selectedBg = isDark
        ? cs.primary.withValues(alpha: 0.85)
        : cs.primary;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? selectedBg : Colors.transparent,
          borderRadius: BorderRadius.circular(13),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: cs.primary.withValues(alpha: 0.30),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected
                ? Colors.white
                : cs.onSurface.withValues(alpha: isDark ? 0.55 : 0.50),
          ),
          child: Text(label),
        ),
      ),
    );
  }
}

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';

/// Wraps secondary pages with responsive presentation:
/// - Mobile: full-screen opaque page
/// - Tablet/Desktop: centered floating modal window over the primary screen,
///   with a soft frosted backdrop, refined corner radius and luminous border.
class SecondaryPageWrapper extends StatelessWidget {
  final Widget child;

  const SecondaryPageWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 768;

    if (isMobile) {
      return Material(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: child,
      );
    }

    final isTablet = size.width < 1100;
    final maxWidth = isTablet ? size.width * 0.90 : 1040.0;
    final maxHeight = size.height * 0.90;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        // Subtle radial vignette behind the modal that further focuses
        // attention on the active panel without competing with content.
        Positioned.fill(
          child: GestureDetector(
            onTap: () => context.pop(),
            behavior: HitTestBehavior.opaque,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 0.9,
                  colors: [
                    Colors.black.withValues(alpha: isDark ? 0.30 : 0.10),
                    Colors.black.withValues(alpha: isDark ? 0.58 : 0.32),
                  ],
                ),
              ),
            ),
          ),
        ),
        Center(
          child: GestureDetector(
            // Absorb taps so they don't close the modal.
            onTap: () {},
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: maxWidth,
                maxHeight: maxHeight,
              ),
              child: _ModalChrome(isDark: isDark, child: child),
            ),
          ),
        ),
      ],
    );
  }
}

class _ModalChrome extends StatelessWidget {
  final bool isDark;
  final Widget child;

  const _ModalChrome({required this.isDark, required this.child});

  @override
  Widget build(BuildContext context) {
    final scaffoldBg = Theme.of(context).scaffoldBackgroundColor;
    const radius = 24.0;
    final borderRadius = BorderRadius.circular(radius);

    return DecoratedBox(
      // Outer halo: a soft primary‑tinted glow that elevates the modal
      // off of the page without feeling heavy.
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.55 : 0.22),
            blurRadius: 48,
            spreadRadius: 0,
            offset: const Offset(0, 24),
          ),
          BoxShadow(
            color: AppColors.primary.withValues(alpha: isDark ? 0.18 : 0.10),
            blurRadius: 60,
            spreadRadius: -8,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: BackdropFilter(
          // No blur on the inner content – the child is opaque – but the
          // hairline border below uses subtle transparency to feel modern.
          filter: ImageFilter.blur(sigmaX: 0, sigmaY: 0),
          child: Container(
            decoration: BoxDecoration(
              color: scaffoldBg,
              borderRadius: borderRadius,
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.07)
                    : Colors.black.withValues(alpha: 0.06),
                width: 1,
              ),
            ),
            // Material clipped so the inner page's AppBar etc. respects
            // the rounded corners of the modal.
            child: Material(
              color: Colors.transparent,
              borderRadius: borderRadius,
              clipBehavior: Clip.antiAlias,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

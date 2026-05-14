import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Wraps secondary pages with responsive presentation:
/// - Mobile: full-screen opaque page
/// - Tablet/Desktop: centered floating modal window over the primary screen
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
    final maxWidth = isTablet ? size.width * 0.88 : 920.0;
    final maxHeight = size.height * 0.88;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => context.pop(),
      behavior: HitTestBehavior.opaque,
      child: Center(
        child: GestureDetector(
          onTap: () {}, // absorb taps so they don't close the modal
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: maxWidth,
              maxHeight: maxHeight,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 0, sigmaY: 0),
                child: Material(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  elevation: 24,
                  shadowColor: Colors.black.withValues(alpha: isDark ? 0.6 : 0.3),
                  borderRadius: BorderRadius.circular(20),
                  child: child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

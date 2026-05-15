import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shimmer/shimmer.dart';
import '../providers/theme_provider.dart';
import '../theme/app_colors.dart';
import '../data/ui_text.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PAGE LAYOUT METRICS
// ─────────────────────────────────────────────────────────────────────────────

class AppPageLayout {
  static const double horizontalPadding = 20;
  static const double topGap = 20;

  const AppPageLayout._();

  static EdgeInsets contentPadding(
    BuildContext context, {
    double horizontal = horizontalPadding,
    double bottom = 0,
  }) {
    return EdgeInsets.fromLTRB(
      horizontal,
      MediaQuery.of(context).padding.top + topGap,
      horizontal,
      bottom,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PAGE HEADER  –  full-width hero card with title, description, and action
// ─────────────────────────────────────────────────────────────────────────────

class AppPageHeader extends ConsumerWidget {
  final String title;
  final String description;
  final String? actionLabel;
  final String? compactActionLabel;
  final IconData? actionIcon;
  final VoidCallback? onAction;
  final Widget? trailing;

  const AppPageHeader({
    super.key,
    required this.title,
    required this.description,
    this.actionLabel,
    this.compactActionLabel,
    this.actionIcon,
    this.onAction,
    this.trailing,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final glassMode = ref.watch(glassModeProvider);

    final titleStyle = theme.textTheme.titleLarge?.copyWith(
      fontWeight: FontWeight.w800,
      height: 1.1,
      letterSpacing: -0.5,
      color: theme.colorScheme.onSurface,
    );
    final descriptionStyle = theme.textTheme.bodySmall?.copyWith(
      height: 1.5,
      color:
          theme.colorScheme.onSurface.withValues(alpha: isDark ? 0.58 : 0.54),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 520;
        final action = trailing ??
            (actionLabel != null && onAction != null
                ? AppButton(
                    label: isCompact
                        ? (compactActionLabel ?? actionLabel!)
                        : actionLabel!,
                    icon: actionIcon,
                    onPressed: onAction,
                  )
                : null);

        final descriptionText = Text(description, style: descriptionStyle);

        Widget content;
        if (action == null) {
          content = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: titleStyle),
              const SizedBox(height: 8),
              descriptionText,
            ],
          );
        } else if (isCompact) {
          content = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: Text(title, style: titleStyle)),
                  const SizedBox(width: 12),
                  action,
                ],
              ),
              const SizedBox(height: 10),
              descriptionText,
            ],
          );
        } else {
          content = Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(title, style: titleStyle),
                    const SizedBox(height: 8),
                    descriptionText,
                  ],
                ),
              ),
              const SizedBox(width: 20),
              action,
            ],
          );
        }

        // Card decoration
        final cardRadius = BorderRadius.circular(20);
        const primaryTint = AppColors.primary;

        if (glassMode) {
          return ClipRRect(
            borderRadius: cardRadius,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: cardRadius,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      primaryTint.withValues(alpha: isDark ? 0.18 : 0.10),
                      (isDark ? Colors.white : Colors.white)
                          .withValues(alpha: isDark ? 0.06 : 0.55),
                    ],
                  ),
                  border: Border.all(
                    color: primaryTint.withValues(alpha: isDark ? 0.28 : 0.18),
                  ),
                ),
                child: _cardContent(content, isDark, primaryTint),
              ),
            ),
          );
        }

        return Container(
          decoration: BoxDecoration(
            borderRadius: cardRadius,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      primaryTint.withValues(alpha: 0.16),
                      AppColors.darkCard,
                    ]
                  : [
                      primaryTint.withValues(alpha: 0.06),
                      Colors.white,
                    ],
            ),
            border: Border.all(
              color: primaryTint.withValues(alpha: isDark ? 0.22 : 0.13),
            ),
            boxShadow: [
              BoxShadow(
                color: primaryTint.withValues(alpha: isDark ? 0.10 : 0.07),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: cardRadius,
            child: _cardContent(content, isDark, primaryTint),
          ),
        );
      },
    );
  }

  Widget _cardContent(Widget content, bool isDark, Color primaryTint) {
    return Stack(
      children: [
        PositionedDirectional(
          top: -28,
          end: -28,
          child: Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: primaryTint.withValues(alpha: isDark ? 0.13 : 0.08),
            ),
          ),
        ),
        PositionedDirectional(
          bottom: -18,
          end: 60,
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryLight
                  .withValues(alpha: isDark ? 0.08 : 0.05),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(20),
          child: content,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GLASS SURFACE
// ─────────────────────────────────────────────────────────────────────────────

class GlassSurface extends StatelessWidget {
  final Widget child;
  final bool enabled;
  final EdgeInsetsGeometry? padding;
  final BorderRadiusGeometry borderRadius;
  final Color? color;
  final double blur;
  final Border? border;
  final List<BoxShadow>? boxShadow;

  const GlassSurface({
    super.key,
    required this.child,
    required this.enabled,
    this.padding,
    this.borderRadius = const BorderRadius.all(Radius.circular(20)),
    this.color,
    this.blur = 18,
    this.border,
    this.boxShadow,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final radius = borderRadius;
    final glassTint = color;
    final container = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: enabled
            ? (glassTint ?? Colors.white).withValues(
                alpha: glassTint == null
                    ? (isDark ? 0.10 : 0.56)
                    : (isDark ? 0.16 : 0.22),
              )
            : color,
        borderRadius: radius,
        border: border ??
            (enabled
                ? Border.all(
                    color: (glassTint ?? Colors.white).withValues(
                      alpha: glassTint == null
                          ? (isDark ? 0.15 : 0.58)
                          : (isDark ? 0.30 : 0.42),
                    ),
                  )
                : null),
        gradient: enabled
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: glassTint == null
                    ? [
                        Colors.white.withValues(alpha: isDark ? 0.14 : 0.70),
                        Colors.white.withValues(alpha: isDark ? 0.045 : 0.32),
                      ]
                    : [
                        Color.alphaBlend(
                          Colors.white.withValues(alpha: isDark ? 0.08 : 0.28),
                          glassTint.withValues(alpha: isDark ? 0.18 : 0.24),
                        ),
                        glassTint.withValues(alpha: isDark ? 0.08 : 0.13),
                      ],
              )
            : null,
        boxShadow: boxShadow ??
            (enabled
                ? [
                    BoxShadow(
                      color:
                          Colors.black.withValues(alpha: isDark ? 0.30 : 0.09),
                      blurRadius: 26,
                      offset: const Offset(0, 14),
                    ),
                  ]
                : null),
      ),
      child: child,
    );

    if (!enabled) return container;

    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: container,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GLASS DIALOG
// ─────────────────────────────────────────────────────────────────────────────

class GlassAlertDialog extends ConsumerWidget {
  final Widget? title;
  final Widget? content;
  final List<Widget>? actions;
  final EdgeInsetsGeometry titlePadding;
  final EdgeInsetsGeometry contentPadding;
  final EdgeInsetsGeometry actionsPadding;

  const GlassAlertDialog({
    super.key,
    this.title,
    this.content,
    this.actions,
    this.titlePadding = const EdgeInsets.fromLTRB(24, 22, 24, 0),
    this.contentPadding = const EdgeInsets.fromLTRB(24, 18, 24, 0),
    this.actionsPadding = const EdgeInsets.fromLTRB(24, 16, 24, 18),
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final glassMode = ref.watch(glassModeProvider);

    if (!glassMode) {
      return AlertDialog(
        title: title,
        content: content,
        actions: actions,
        titlePadding: titlePadding,
        contentPadding: contentPadding,
        actionsPadding: actionsPadding,
      );
    }

    final theme = Theme.of(context);
    final titleWidget = title == null
        ? null
        : Padding(
            padding: titlePadding,
            child: DefaultTextStyle(
              style: theme.dialogTheme.titleTextStyle ??
                  theme.textTheme.titleLarge ??
                  const TextStyle(),
              child: title!,
            ),
          );
    final contentWidget = content == null
        ? null
        : Flexible(
            child: Padding(
              padding: contentPadding,
              child: DefaultTextStyle(
                style: theme.textTheme.bodyMedium ?? const TextStyle(),
                child: content!,
              ),
            ),
          );
    final actionsWidget = actions == null || actions!.isEmpty
        ? null
        : Padding(
            padding: actionsPadding,
            child: OverflowBar(
              alignment: MainAxisAlignment.end,
              spacing: 8,
              overflowSpacing: 8,
              children: actions!,
            ),
          );

    return Dialog(
      elevation: 0,
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 560,
          maxHeight: MediaQuery.of(context).size.height * 0.86,
        ),
        child: GlassSurface(
          enabled: true,
          borderRadius: BorderRadius.circular(24),
          padding: EdgeInsets.zero,
          child: Material(
            type: MaterialType.transparency,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (titleWidget != null) titleWidget,
                if (contentWidget != null) contentWidget,
                if (actionsWidget != null) actionsWidget,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GLASS CONTEXT MENU
// ─────────────────────────────────────────────────────────────────────────────

abstract class GlassContextMenuEntry<T> {
  const GlassContextMenuEntry();
}

class GlassContextMenuItem<T> extends GlassContextMenuEntry<T> {
  final T value;
  final Widget child;
  final bool enabled;

  const GlassContextMenuItem({
    required this.value,
    required this.child,
    this.enabled = true,
  });
}

class GlassContextMenuDivider<T> extends GlassContextMenuEntry<T> {
  const GlassContextMenuDivider();
}

class GlassContextMenuButton<T> extends ConsumerWidget {
  final Widget icon;
  final List<GlassContextMenuEntry<T>> Function(BuildContext context) itemBuilder;
  final ValueChanged<T>? onSelected;
  final String? tooltip;

  const GlassContextMenuButton({
    super.key,
    required this.icon,
    required this.itemBuilder,
    this.onSelected,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      icon: icon,
      tooltip: tooltip,
      onPressed: () async {
        final box = context.findRenderObject() as RenderBox?;
        final overlay = Overlay.of(context).context.findRenderObject() as RenderBox?;
        if (box == null || overlay == null) return;

        final offset = box.localToGlobal(Offset.zero, ancestor: overlay);
        final position = RelativeRect.fromRect(
          Rect.fromLTWH(offset.dx, offset.dy + box.size.height, 0, 0),
          Offset.zero & overlay.size,
        );
        final value = await showGlassContextMenu<T>(
          context: context,
          position: position,
          items: itemBuilder(context),
        );
        if (value != null) onSelected?.call(value);
      },
    );
  }
}

Future<T?> showGlassContextMenu<T>({
  required BuildContext context,
  required RelativeRect position,
  required List<GlassContextMenuEntry<T>> items,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 120),
    pageBuilder: (dialogContext, animation, secondaryAnimation) {
      return _GlassContextMenuOverlay<T>(
        position: position,
        items: items,
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
      final isRtl = Directionality.of(context) == TextDirection.rtl;
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.96, end: 1).animate(curved),
          alignment: isRtl ? Alignment.topRight : Alignment.topLeft,
          child: child,
        ),
      );
    },
  );
}

class _GlassContextMenuOverlay<T> extends ConsumerWidget {
  final RelativeRect position;
  final List<GlassContextMenuEntry<T>> items;

  const _GlassContextMenuOverlay({
    required this.position,
    required this.items,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final glassMode = ref.watch(glassModeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const menuWidth = 220.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final left = position.left.clamp(
          8.0,
          (constraints.maxWidth - menuWidth - 8).clamp(8.0, constraints.maxWidth),
        ).toDouble();
        final top = position.top.clamp(8.0, constraints.maxHeight - 8).toDouble();

        return Stack(
          children: [
            Positioned(
              left: left,
              top: top,
              width: menuWidth,
              child: Material(
                color: Colors.transparent,
                child: GlassSurface(
                  enabled: glassMode,
                  color: glassMode
                      ? null
                      : (isDark ? AppColors.darkCard : AppColors.lightSurface),
                  borderRadius: BorderRadius.circular(glassMode ? 18 : 12),
                  blur: 18,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: glassMode
                            ? (isDark ? 0.36 : 0.14)
                            : (isDark ? 0.22 : 0.12),
                      ),
                      blurRadius: glassMode ? 26 : 14,
                      offset: const Offset(0, 12),
                    ),
                  ],
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: items.map((entry) {
                      if (entry is GlassContextMenuDivider<T>) {
                        return const Divider(height: 9, indent: 8, endIndent: 8);
                      }
                      final item = entry as GlassContextMenuItem<T>;
                      return InkWell(
                        onTap: item.enabled
                            ? () => Navigator.of(context).pop(item.value)
                            : null,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          child: IconTheme.merge(
                            data: IconThemeData(
                              size: 18,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                            child: DefaultTextStyle(
                              style: Theme.of(context).popupMenuTheme.textStyle ??
                                  Theme.of(context).textTheme.bodyMedium!,
                              child: item.child,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// APP CARD
// ─────────────────────────────────────────────────────────────────────────────

class AppCard extends ConsumerWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final Color? color;
  final bool selected;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.color,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final glassMode = ref.watch(glassModeProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor =
        color ?? (isDark ? AppColors.darkCard : AppColors.lightCard);
    final glassTint = color;
    final borderColor = selected
        ? AppColors.primary
        : glassMode
            ? (glassTint ?? Colors.white).withValues(
                alpha: glassTint == null
                    ? (isDark ? 0.16 : 0.62)
                    : (isDark ? 0.30 : 0.42),
              )
            : (isDark ? AppColors.darkBorder : AppColors.lightBorder);
    final effectiveColor = glassMode
        ? (glassTint ?? Colors.white).withValues(
            alpha: glassTint == null
                ? (isDark ? 0.10 : 0.56)
                : (isDark ? 0.16 : 0.22),
          )
        : bgColor;
    final content = AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      decoration: BoxDecoration(
        color: effectiveColor,
        borderRadius: BorderRadius.circular(glassMode ? 22 : 16),
        border: Border.all(
          color: borderColor,
          width: selected ? 2 : 1,
        ),
        gradient: glassMode
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: glassTint == null
                    ? [
                        Colors.white.withValues(alpha: isDark ? 0.13 : 0.68),
                        Colors.white.withValues(alpha: isDark ? 0.05 : 0.34),
                      ]
                    : [
                        Color.alphaBlend(
                          Colors.white.withValues(alpha: isDark ? 0.08 : 0.28),
                          glassTint.withValues(alpha: isDark ? 0.18 : 0.24),
                        ),
                        glassTint.withValues(alpha: isDark ? 0.08 : 0.13),
                      ],
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: selected
                ? AppColors.primary.withValues(alpha: glassMode ? 0.22 : 0.14)
                : Colors.black.withValues(alpha: isDark ? 0.22 : 0.06),
            blurRadius: selected ? 18 : (glassMode ? 24 : 8),
            offset: Offset(0, glassMode ? 10 : 3),
          ),
          if (glassMode)
            BoxShadow(
              color: Colors.white.withValues(alpha: isDark ? 0.02 : 0.45),
              blurRadius: 1,
              offset: const Offset(0, 1),
            ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(glassMode ? 22 : 16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(glassMode ? 22 : 16),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(16),
            child: child,
          ),
        ),
      ),
    );

    if (!glassMode) return content;

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: content,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// APP STAT CARD
// ─────────────────────────────────────────────────────────────────────────────

class AppStatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const AppStatCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final tintedSurface = color.withValues(alpha: isDark ? 0.13 : 0.10);

    return AppCard(
      color: tintedSurface,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: isDark ? 0.18 : 0.14),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: color.withValues(alpha: isDark ? 0.24 : 0.18),
              ),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: color,
                      height: 1,
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.68),
                    fontWeight: FontWeight.w600,
                    height: 1.1,
                  ),
                  maxLines: 2,
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

// ─────────────────────────────────────────────────────────────────────────────
// APP BAR BACK BUTTON  –  consistent bordered nav button for all AppBars
// ─────────────────────────────────────────────────────────────────────────────

class AppBarBackButton extends ConsumerWidget {
  final VoidCallback? onPressed;

  const AppBarBackButton({super.key, this.onPressed});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final glassMode = ref.watch(glassModeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onTap = onPressed ?? () => Navigator.of(context).maybePop();

    final Color bgColor;
    final Color borderColor;
    if (glassMode) {
      bgColor = isDark
          ? Colors.white.withValues(alpha: 0.08)
          : Colors.white.withValues(alpha: 0.42);
      borderColor = isDark
          ? Colors.white.withValues(alpha: 0.18)
          : Colors.white.withValues(alpha: 0.65);
    } else {
      bgColor = isDark
          ? AppColors.darkSurface.withValues(alpha: 0.90)
          : AppColors.lightSurface;
      borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    }

    return Padding(
      padding: const EdgeInsets.all(8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor, width: 1),
            ),
            child: Icon(
              Icons.arrow_back,
              color: isDark ? AppColors.darkText : AppColors.lightText,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// APP BUTTON  –  icon + label always centred, gradient in all modes
// ─────────────────────────────────────────────────────────────────────────────

class AppButton extends ConsumerWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;
  final bool outlined;
  final Color? color;
  final double? width;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.loading = false,
    this.outlined = false,
    this.color,
    this.width,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final glassMode = ref.watch(glassModeProvider);

    return _StyledButton(
      label: label,
      onPressed: loading ? null : onPressed,
      icon: icon,
      loading: loading,
      outlined: outlined,
      color: color,
      width: width,
      glassEffect: glassMode,
    );
  }
}

class _StyledButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;
  final bool outlined;
  final Color? color;
  final double? width;
  final bool glassEffect;

  const _StyledButton({
    required this.label,
    required this.onPressed,
    required this.icon,
    required this.loading,
    required this.outlined,
    required this.color,
    required this.width,
    required this.glassEffect,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final enabled = onPressed != null;
    final accent = color ?? (isDark ? AppColors.primaryLight : AppColors.primary);
    final foreground = outlined ? accent : Colors.white;
    final hasLeading = loading || icon != null;
    final radius = glassEffect ? 16.0 : 12.0;

    BoxDecoration decoration;
    if (glassEffect) {
      decoration = BoxDecoration(
        color: outlined
            ? Colors.white.withValues(alpha: isDark ? 0.075 : 0.38)
            : accent.withValues(alpha: isDark ? 0.55 : 0.72),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: outlined
              ? Colors.white.withValues(alpha: isDark ? 0.18 : 0.70)
              : Colors.white.withValues(alpha: isDark ? 0.22 : 0.45),
          width: 1.2,
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: outlined
              ? [
                  Colors.white.withValues(alpha: isDark ? 0.15 : 0.62),
                  Colors.white.withValues(alpha: isDark ? 0.04 : 0.22),
                ]
              : [
                  accent.withValues(alpha: isDark ? 0.70 : 0.86),
                  AppColors.accent.withValues(alpha: isDark ? 0.45 : 0.62),
                ],
        ),
        boxShadow: [
          BoxShadow(
            color: (outlined ? Colors.black : accent)
                .withValues(alpha: isDark ? 0.28 : 0.20),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: isDark ? 0.025 : 0.45),
            blurRadius: 1,
            offset: const Offset(0, 1),
          ),
        ],
      );
    } else {
      // Non-glass: solid gradient for filled, clean bordered for outlined
      decoration = BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: outlined
            ? null
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  accent,
                  AppColors.accent.withValues(alpha: isDark ? 0.82 : 0.88),
                ],
              ),
        color: outlined
            ? (isDark
                ? AppColors.darkSurface.withValues(alpha: 0.5)
                : Colors.transparent)
            : null,
        border: Border.all(
          color: outlined
              ? accent.withValues(alpha: 0.90)
              : Colors.white.withValues(alpha: isDark ? 0.16 : 0.30),
          width: outlined ? 1.5 : 1,
        ),
        boxShadow: outlined
            ? null
            : [
                BoxShadow(
                  color: accent.withValues(alpha: isDark ? 0.38 : 0.28),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
      );
    }

    final innerContent = ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: DecoratedBox(
        decoration: decoration,
        child: Stack(
          children: [
            if (glassEffect)
              Positioned(
                top: -24,
                left: -36,
                child: Transform.rotate(
                  angle: -0.55,
                  child: Container(
                    width: 92,
                    height: 18,
                    color: Colors.white.withValues(alpha: isDark ? 0.10 : 0.26),
                  ),
                ),
              ),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: enabled ? onPressed : null,
                borderRadius: BorderRadius.circular(radius),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 46),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 13),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (loading)
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: foreground,
                            ),
                          )
                        else if (icon != null)
                          Icon(icon, size: 18, color: foreground),
                        if (hasLeading) const SizedBox(width: 8),
                        Text(
                          label,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: foreground,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.05,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    final button = AnimatedOpacity(
      duration: const Duration(milliseconds: 160),
      opacity: enabled ? 1 : 0.58,
      child: glassEffect
          ? BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: innerContent,
            )
          : innerContent,
    );

    return SizedBox(width: width, child: button);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// EMPTY STATE
// ─────────────────────────────────────────────────────────────────────────────

class EmptyState extends ConsumerWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.title,
    this.subtitle,
    this.icon = Icons.inbox_outlined,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final glassMode = ref.watch(glassModeProvider);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GlassSurface(
              enabled: glassMode,
              borderRadius: BorderRadius.circular(28),
              blur: 20,
              color:
                  AppColors.primary.withValues(alpha: glassMode ? 0.12 : 0.0),
              child: Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary
                          .withValues(alpha: glassMode ? 0.18 : 0.12),
                      AppColors.primaryLight
                          .withValues(alpha: glassMode ? 0.10 : 0.06),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                      color: AppColors.primary
                          .withValues(alpha: glassMode ? 0.26 : 0.18),
                      width: 1.5),
                ),
                child: Icon(icon,
                    size: 40, color: AppColors.primary.withValues(alpha: 0.68)),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.5),
                    ),
                textAlign: TextAlign.center,
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 28),
              AppButton(
                  label: actionLabel!, onPressed: onAction, icon: Icons.add),
            ],
          ],
        ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.08),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// LOADING SKELETONS
// ─────────────────────────────────────────────────────────────────────────────

class LoadingGrid extends StatelessWidget {
  final int count;
  final double height;

  const LoadingGrid({super.key, this.count = 6, this.height = 120});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDark ? AppColors.darkCard : AppColors.lightBorder,
      highlightColor: isDark ? AppColors.darkBorder : AppColors.lightSurface,
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 320,
          mainAxisExtent: 140,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: count,
        itemBuilder: (context, index) => Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}

class LoadingList extends StatelessWidget {
  final int count;

  const LoadingList({super.key, this.count = 5});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDark ? AppColors.darkCard : AppColors.lightBorder,
      highlightColor: isDark ? AppColors.darkBorder : AppColors.lightSurface,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: count,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) => Container(
          height: 72,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STATUS CHIP
// ─────────────────────────────────────────────────────────────────────────────

class StatusChip extends ConsumerWidget {
  final String status;
  final Color? color;

  const StatusChip({super.key, required this.status, this.color});

  Color _statusColor() {
    switch (status.toLowerCase()) {
      case 'active':
      case 'approved':
      case 'completed':
      case 'done':
      case 'resolved':
        return AppColors.success;
      case 'pending':
      case 'waiting':
      case 'in_progress':
      case 'inprogress':
        return AppColors.warning;
      case 'rejected':
      case 'failed':
      case 'error':
      case 'closed':
        return AppColors.error;
      case 'draft':
      case 'inactive':
        return AppColors.lightTextSecondary;
      default:
        return AppColors.info;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = color ?? _statusColor();
    final glassMode = ref.watch(glassModeProvider);

    return GlassSurface(
      enabled: glassMode,
      borderRadius: BorderRadius.circular(999),
      blur: 12,
      color: c.withValues(alpha: glassMode ? 0.10 : 0.11),
      border: Border.all(
        color: c.withValues(alpha: glassMode ? 0.34 : 0.28),
        width: 1,
      ),
      boxShadow: glassMode
          ? [
              BoxShadow(
                color: c.withValues(alpha: 0.14),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ]
          : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Text(
          UiText.statusLabel(status),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: c,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SECTION HEADER
// ─────────────────────────────────────────────────────────────────────────────

class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;

  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleLarge),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// INFO ROW
// ─────────────────────────────────────────────────────────────────────────────

class InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;

  const InfoRow({
    super.key,
    required this.label,
    required this.value,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon,
                size: 16,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary),
            const SizedBox(width: 8),
          ],
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// APP DIVIDER
// ─────────────────────────────────────────────────────────────────────────────

class AppDivider extends ConsumerWidget {
  const AppDivider({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final glassMode = ref.watch(glassModeProvider);
    return Divider(
      height: 1,
      color: glassMode
          ? Colors.white.withValues(alpha: isDark ? 0.13 : 0.50)
          : isDark
              ? AppColors.darkBorder
              : AppColors.lightBorder,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CONFIRM DIALOG
// ─────────────────────────────────────────────────────────────────────────────

class ConfirmDialog extends ConsumerWidget {
  final String title;
  final String message;
  final String? confirmLabel;
  final Color? confirmColor;

  const ConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmLabel,
    this.confirmColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final glassMode = ref.watch(glassModeProvider);

    if (!glassMode) {
      return AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(UiText.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: confirmColor ?? AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: Text(confirmLabel ?? UiText.delete),
          ),
        ],
      );
    }

    return Dialog(
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: GlassSurface(
        enabled: true,
        borderRadius: BorderRadius.circular(24),
        padding: const EdgeInsets.fromLTRB(24, 22, 24, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Text(message, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 22),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(UiText.cancel),
                ),
                const SizedBox(width: 10),
                AppButton(
                  label: confirmLabel ?? UiText.delete,
                  onPressed: () => Navigator.pop(context, true),
                  color: confirmColor ?? AppColors.error,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AVATAR WIDGET
// ─────────────────────────────────────────────────────────────────────────────

class AvatarWidget extends StatelessWidget {
  final String? imageUrl;
  final String initials;
  final double size;
  final Color? color;

  const AvatarWidget({
    super.key,
    this.imageUrl,
    required this.initials,
    this.size = 40,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = color?.withValues(alpha: 0.15) ??
        AppColors.primary.withValues(alpha: 0.14);
    final borderColor = color?.withValues(alpha: 0.3) ??
        AppColors.primary.withValues(alpha: 0.22);

    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: imageUrl!,
        imageBuilder: (context, imageProvider) => Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: borderColor),
            image: DecorationImage(image: imageProvider, fit: BoxFit.cover),
          ),
        ),
        placeholder: (context, url) => _InitialsAvatar(
          initials: initials,
          size: size,
          bgColor: bgColor,
          borderColor: borderColor,
          textColor: color ?? AppColors.primary,
        ),
        errorWidget: (context, url, error) => _InitialsAvatar(
          initials: initials,
          size: size,
          bgColor: bgColor,
          borderColor: borderColor,
          textColor: color ?? AppColors.primary,
        ),
      );
    }

    return _InitialsAvatar(
      initials: initials,
      size: size,
      bgColor: bgColor,
      borderColor: borderColor,
      textColor: color ?? AppColors.primary,
    );
  }
}

class _InitialsAvatar extends StatelessWidget {
  final String initials;
  final double size;
  final Color bgColor;
  final Color borderColor;
  final Color textColor;

  const _InitialsAvatar({
    required this.initials,
    required this.size,
    required this.bgColor,
    required this.borderColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: bgColor,
        border: Border.all(color: borderColor),
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            fontSize: size * 0.36,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SEARCH FIELD
// ─────────────────────────────────────────────────────────────────────────────

class SearchField extends StatefulWidget {
  final TextEditingController controller;
  final String? hintText;
  final ValueChanged<String>? onChanged;

  const SearchField({
    super.key,
    required this.controller,
    this.hintText,
    this.onChanged,
  });

  @override
  State<SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<SearchField> {
  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      onChanged: (v) {
        setState(() {}); // update clear button visibility
        widget.onChanged?.call(v);
      },
      decoration: InputDecoration(
        hintText: widget.hintText ?? UiText.searchEllipsis,
        prefixIcon: const Icon(Icons.search_rounded, size: 20),
        suffixIcon: widget.controller.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear_rounded, size: 18),
                onPressed: () {
                  widget.controller.clear();
                  setState(() {});
                  widget.onChanged?.call('');
                },
              )
            : null,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ERROR WIDGET
// ─────────────────────────────────────────────────────────────────────────────

class AppErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const AppErrorWidget({
    super.key,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline_rounded,
                  size: 40, color: AppColors.error),
            ),
            const SizedBox(height: 16),
            Text(
              UiText.somethingWentWrong,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 20),
              AppButton(
                  label: UiText.retry,
                  onPressed: onRetry,
                  icon: Icons.refresh),
            ],
          ],
        ),
      ),
    );
  }
}

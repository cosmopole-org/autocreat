import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shimmer/shimmer.dart';
import '../theme/app_colors.dart';

class AppCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = color ?? (isDark ? AppColors.darkCard : AppColors.lightCard);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: selected
              ? AppColors.primary
              : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          width: selected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: selected
                ? AppColors.primary.withValues(alpha: 0.12)
                : Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: selected ? 10 : 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(16),
            child: child,
          ),
        ),
      ),
    );
  }
}

class AppButton extends StatelessWidget {
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
  Widget build(BuildContext context) {
    if (outlined) {
      return SizedBox(
        width: width,
        child: OutlinedButton.icon(
          onPressed: loading ? null : onPressed,
          icon: loading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : (icon != null ? Icon(icon, size: 18) : const SizedBox.shrink()),
          label: Text(label),
        ),
      );
    }
    return SizedBox(
      width: width,
      child: ElevatedButton.icon(
        onPressed: loading ? null : onPressed,
        style: color != null
            ? ElevatedButton.styleFrom(backgroundColor: color)
            : null,
        icon: loading
            ? const SizedBox(
                width: 16,
                height: 16,
                child:
                    CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : (icon != null ? Icon(icon, size: 18) : const SizedBox.shrink()),
        label: Text(label),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.12),
                    AppColors.primaryLight.withValues(alpha: 0.06),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.15), width: 1.5),
              ),
              child: Icon(icon, size: 40, color: AppColors.primary.withValues(alpha: 0.65)),
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
              AppButton(label: actionLabel!, onPressed: onAction, icon: Icons.add),
            ],
          ],
        ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.08),
      ),
    );
  }
}

class LoadingGrid extends StatelessWidget {
  final int count;
  final double height;

  const LoadingGrid({super.key, this.count = 6, this.height = 120});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDark ? AppColors.darkCard : AppColors.lightBorder,
      highlightColor:
          isDark ? AppColors.darkBorder : AppColors.lightBg,
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
      highlightColor: isDark ? AppColors.darkBorder : AppColors.lightBg,
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

class StatusChip extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final c = color ?? _statusColor();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: c.withValues(alpha: 0.3), width: 1),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: c,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: AppColors.lightTextSecondary),
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

class AppDivider extends StatelessWidget {
  const AppDivider({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Divider(
      height: 1,
      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
    );
  }
}

class ConfirmDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final Color? confirmColor;

  const ConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmLabel = 'Delete',
    this.confirmColor,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: confirmColor ?? AppColors.error,
          ),
          child: Text(confirmLabel),
        ),
      ],
    );
  }
}

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
    final bgColor = color ?? AppColors.primary.withValues(alpha: 0.15);
    final borderColor = color?.withValues(alpha: 0.3) ?? AppColors.primary.withValues(alpha: 0.2);

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
            fontSize: size * 0.35,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
      ),
    );
  }
}

class SearchField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String>? onChanged;

  const SearchField({
    super.key,
    required this.controller,
    this.hintText = 'Search...',
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: const Icon(Icons.search, size: 20),
        suffixIcon: controller.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear, size: 18),
                onPressed: () {
                  controller.clear();
                  onChanged?.call('');
                },
              )
            : null,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      ),
    );
  }
}

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
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
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
              AppButton(label: 'Retry', onPressed: onRetry, icon: Icons.refresh),
            ],
          ],
        ),
      ),
    );
  }
}

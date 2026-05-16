import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import 'models.dart';

class DesignerToolbar extends StatefulWidget {
  final ValueChanged<ElementKind> onPick;
  final bool isDark;
  final bool collapsed;
  final VoidCallback? onToggleCollapse;

  const DesignerToolbar({
    super.key,
    required this.onPick,
    required this.isDark,
    this.collapsed = false,
    this.onToggleCollapse,
  });

  @override
  State<DesignerToolbar> createState() => _DesignerToolbarState();
}

class _DesignerToolbarState extends State<DesignerToolbar> {
  String _category = 'Text';

  static const _categories = ['Text', 'Visuals', 'Data', 'Misc'];

  IconData _categoryIcon(String c) {
    switch (c) {
      case 'Text':
        return Icons.text_fields_rounded;
      case 'Visuals':
        return Icons.image_outlined;
      case 'Data':
        return Icons.bar_chart_rounded;
      case 'Misc':
      default:
        return Icons.widgets_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final bg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final width = widget.collapsed ? 56.0 : 240.0;
    final items = ElementKind.values
        .where((k) => k.category == _category)
        .toList();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      width: width,
      decoration: BoxDecoration(
        color: bg,
        border: Border(right: BorderSide(color: border)),
      ),
      child: Column(
        children: [
          // ─── header: category tabs (vertical icon strip) ───
          Container(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: border)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (!widget.collapsed)
                  Padding(
                    padding: const EdgeInsets.only(left: 10),
                    child: Text(
                      'Insert',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                if (widget.onToggleCollapse != null)
                  IconButton(
                    icon: Icon(
                      widget.collapsed
                          ? Icons.chevron_right_rounded
                          : Icons.chevron_left_rounded,
                      size: 18,
                    ),
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 32, minHeight: 32),
                    onPressed: widget.onToggleCollapse,
                  ),
              ],
            ),
          ),
          if (!widget.collapsed)
            Container(
              height: 42,
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: border)),
              ),
              child: Row(
                children: [
                  for (final c in _categories)
                    Expanded(
                      child: _CategoryTab(
                        label: c,
                        icon: _categoryIcon(c),
                        active: _category == c,
                        isDark: isDark,
                        onTap: () => setState(() => _category = c),
                      ),
                    ),
                ],
              ),
            ),
          Expanded(
            child: widget.collapsed
                ? _CollapsedRail(
                    isDark: isDark,
                    onPick: widget.onPick,
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                        vertical: 8, horizontal: 8),
                    itemCount: items.length,
                    itemBuilder: (_, i) {
                      final k = items[i];
                      return _ElementTile(
                        kind: k,
                        isDark: isDark,
                        onTap: () => widget.onPick(k),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _CategoryTab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final bool isDark;
  final VoidCallback onTap;

  const _CategoryTab({
    required this.label,
    required this.icon,
    required this.active,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = isDark ? AppColors.primaryLight : AppColors.primary;
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: active ? accent : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 14,
                color: active
                    ? accent
                    : (isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: active
                        ? accent
                        : (isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ElementTile extends StatefulWidget {
  final ElementKind kind;
  final bool isDark;
  final VoidCallback onTap;

  const _ElementTile({
    required this.kind,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_ElementTile> createState() => _ElementTileState();
}

class _ElementTileState extends State<_ElementTile> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final accent = isDark ? AppColors.primaryLight : AppColors.primary;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            decoration: BoxDecoration(
              color: _hover
                  ? accent.withValues(alpha: isDark ? 0.14 : 0.10)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _hover
                    ? accent.withValues(alpha: 0.40)
                    : Colors.transparent,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: isDark ? 0.18 : 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(widget.kind.icon, size: 18, color: accent),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.kind.label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? AppColors.darkText
                          : AppColors.lightText,
                    ),
                  ),
                ),
                Icon(
                  Icons.add_rounded,
                  size: 16,
                  color: _hover
                      ? accent
                      : (isDark
                          ? AppColors.darkTextHint
                          : AppColors.lightTextHint),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CollapsedRail extends StatelessWidget {
  final bool isDark;
  final ValueChanged<ElementKind> onPick;

  const _CollapsedRail({required this.isDark, required this.onPick});

  @override
  Widget build(BuildContext context) {
    const featured = [
      ElementKind.text,
      ElementKind.heading1,
      ElementKind.image,
      ElementKind.table,
      ElementKind.barChart,
      ElementKind.pieChart,
      ElementKind.columns,
      ElementKind.shapeRect,
      ElementKind.divider,
      ElementKind.signature,
    ];
    final accent = isDark ? AppColors.primaryLight : AppColors.primary;
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      children: [
        for (final k in featured)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Tooltip(
              message: k.label,
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => onPick(k),
                child: Container(
                  height: 38,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: isDark ? 0.14 : 0.10),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Icon(k.icon, size: 18, color: accent),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

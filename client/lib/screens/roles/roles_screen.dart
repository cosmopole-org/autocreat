import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/role.dart';
import '../../providers/role_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common_widgets.dart';

class RolesScreen extends ConsumerStatefulWidget {
  const RolesScreen({super.key});

  @override
  ConsumerState<RolesScreen> createState() => _RolesScreenState();
}

class _RolesScreenState extends ConsumerState<RolesScreen> {
  final _searchController = TextEditingController();
  String _search = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rolesAsync = ref.watch(roleNotifierProvider);

    return Scaffold(
      body: rolesAsync.when(
        loading: () => const LoadingList(),
        error: (e, _) => AppErrorWidget(
          message: e.toString(),
          onRetry: () => ref.read(roleNotifierProvider.notifier).refresh(),
        ),
        data: (roles) => _buildContent(context, roles),
      ),
    );
  }

  Widget _buildContent(BuildContext context, List<Role> roles) {
    final filtered = _search.isEmpty
        ? roles
        : roles
            .where(
                (r) => r.name.toLowerCase().contains(_search.toLowerCase()))
            .toList();

    final active = roles.where((r) => r.isActive).length;
    final totalMembers =
        roles.fold<int>(0, (s, r) => s + r.memberCount);
    final totalPerms =
        roles.fold<int>(0, (s, r) => s + r.permissions.length);

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              MediaQuery.of(context).padding.top + 20,
              20,
              0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Roles & Permissions',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          Text(
                            'Define access control roles for your organization',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    AppButton(
                      label: 'New Role',
                      icon: Icons.add,
                      onPressed: () => context.go('/roles/new/edit'),
                    ),
                  ],
                ).animate().fadeIn(duration: 300.ms),
                const SizedBox(height: 20),

                // Stats
                _RoleStatsRow(
                  total: roles.length,
                  active: active,
                  totalMembers: totalMembers,
                  totalPerms: totalPerms,
                ).animate().fadeIn(delay: 100.ms),
                const SizedBox(height: 20),

                // Members per role chart
                if (roles.isNotEmpty)
                  _MembersBarChart(roles: roles).animate().fadeIn(delay: 200.ms),
                if (roles.isNotEmpty) const SizedBox(height: 20),

                // Search
                SearchField(
                  controller: _searchController,
                  hintText: 'Search roles...',
                  onChanged: (v) => setState(() => _search = v),
                ).animate().fadeIn(delay: 250.ms),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),

        if (filtered.isEmpty)
          SliverFillRemaining(
            child: EmptyState(
              title: 'No roles yet',
              subtitle: 'Create roles to manage access control',
              icon: Icons.shield_outlined,
              actionLabel: 'Create Role',
              onAction: () => context.go('/roles/new/edit'),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _RoleCard(
                    role: filtered[i],
                    onEdit: () => context.go('/roles/${filtered[i].id}/edit'),
                    onDelete: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (_) => const ConfirmDialog(
                          title: 'Delete Role',
                          message: 'Delete this role permanently?',
                        ),
                      );
                      if (confirmed == true) {
                        await ref
                            .read(roleNotifierProvider.notifier)
                            .delete(filtered[i].id);
                      }
                    },
                  ).animate().fadeIn(delay: Duration(milliseconds: 60 + i * 50)),
                ),
                childCount: filtered.length,
              ),
            ),
          ),
      ],
    );
  }
}

// ── Stats Row ──────────────────────────────────────────────────

class _RoleStatsRow extends StatelessWidget {
  final int total;
  final int active;
  final int totalMembers;
  final int totalPerms;

  const _RoleStatsRow({
    required this.total,
    required this.active,
    required this.totalMembers,
    required this.totalPerms,
  });

  @override
  Widget build(BuildContext context) {
    final stats = [
      (Icons.shield_rounded, 'Total Roles', total.toString(), AppColors.success),
      (Icons.check_circle_rounded, 'Active', active.toString(), AppColors.primary),
      (Icons.people_rounded, 'Total Members', totalMembers.toString(), AppColors.accent),
      (Icons.lock_rounded, 'Permission Sets', totalPerms.toString(), AppColors.warning),
    ];

    return LayoutBuilder(builder: (context, constraints) {
      final cols = constraints.maxWidth > 700 ? 4 : 2;
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: cols,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: constraints.maxWidth > 700 ? 2.2 : 1.8,
        ),
        itemCount: stats.length,
        itemBuilder: (context, i) {
          final (icon, label, value, color) = stats[i];
          return AppStatCard(icon: icon, label: label, value: value, color: color);
        },
      );
    });
  }
}

// ── Members Bar Chart ──────────────────────────────────────────

class _MembersBarChart extends StatelessWidget {
  final List<Role> roles;

  const _MembersBarChart({required this.roles});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final top = roles.take(6).toList();
    final maxVal = top
            .map((r) => r.memberCount)
            .fold<int>(0, (a, b) => a > b ? a : b)
            .toDouble() +
        1;

    final colors = [
      AppColors.success,
      AppColors.primary,
      AppColors.accent,
      AppColors.warning,
      AppColors.info,
      AppColors.error,
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outline.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Members per Role',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700)),
          Text('How many users are assigned to each role',
              style: TextStyle(
                  fontSize: 11, color: cs.onSurface.withValues(alpha: 0.45))),
          const SizedBox(height: 16),
          SizedBox(
            height: 160,
            child: BarChart(
              BarChartData(
                maxY: maxVal.clamp(2.0, 20.0),
                borderData: FlBorderData(show: false),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: cs.outline.withValues(alpha: 0.2),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) {
                        final idx = v.toInt();
                        if (idx >= top.length) return const SizedBox();
                        final name = top[idx].name;
                        final short = name.length > 8
                            ? '${name.substring(0, 7)}…'
                            : name;
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            short,
                            style: TextStyle(
                                fontSize: 10,
                                color: cs.onSurface.withValues(alpha: 0.5)),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: top.asMap().entries.map((e) {
                  final color = colors[e.key % colors.length];
                  return BarChartGroupData(
                    x: e.key,
                    barRods: [
                      BarChartRodData(
                        toY: e.value.memberCount.toDouble(),
                        color: color,
                        width: 28,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(6)),
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: maxVal.clamp(2.0, 20.0),
                          color: color.withValues(alpha: 0.06),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Role Card ──────────────────────────────────────────────────

class _RoleCard extends StatelessWidget {
  final Role role;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _RoleCard({
    required this.role,
    required this.onEdit,
    required this.onDelete,
  });

  Color _levelColor(String level) {
    switch (level) {
      case 'admin':
        return AppColors.error;
      case 'manager':
        return AppColors.warning;
      case 'viewer':
        return AppColors.lightTextSecondary;
      default:
        return AppColors.accent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lvlColor = _levelColor(role.level);

    // Permission summary
    final canCreate =
        role.permissions.where((p) => p.canCreate).length;

    return GestureDetector(
      onTap: onEdit,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.outline.withValues(alpha: 0.4)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.shield_rounded,
                      color: AppColors.success, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              role.name,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: lvlColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              role.level.toUpperCase(),
                              style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: lvlColor,
                                  letterSpacing: 0.5),
                            ),
                          ),
                        ],
                      ),
                      if (role.description != null)
                        Text(
                          role.description!,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                color: cs.onSurface.withValues(alpha: 0.55),
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert,
                      size: 18, color: cs.onSurface.withValues(alpha: 0.5)),
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'edit', child: Text('Edit')),
                    const PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete',
                            style: TextStyle(color: AppColors.error))),
                  ],
                  onSelected: (v) {
                    if (v == 'edit') onEdit();
                    if (v == 'delete') onDelete();
                  },
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Permission summary row
            Row(
              children: [
                _PermBadge(
                  icon: Icons.people_rounded,
                  label: '${role.memberCount} members',
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                _PermBadge(
                  icon: Icons.lock_open_rounded,
                  label: '${role.permissions.length} resources',
                  color: AppColors.accent,
                ),
                const SizedBox(width: 8),
                _PermBadge(
                  icon: Icons.add_circle_outline,
                  label: '$canCreate create',
                  color: AppColors.success,
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Resource chips
            Wrap(
              spacing: 5,
              runSpacing: 5,
              children: role.permissions
                  .take(4)
                  .map((p) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              p.canCreate && p.canDelete
                                  ? Icons.edit_rounded
                                  : Icons.visibility_rounded,
                              size: 9,
                              color: p.canCreate
                                  ? AppColors.success
                                  : AppColors.lightTextSecondary,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              p.resource,
                              style: TextStyle(
                                  fontSize: 10,
                                  color: cs.onSurface.withValues(alpha: 0.65)),
                            ),
                          ],
                        ),
                      ))
                  .toList()
                ..addAll(role.permissions.length > 4
                    ? [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primarySurface,
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            '+${role.permissions.length - 4} more',
                            style: const TextStyle(
                                fontSize: 10, color: AppColors.primary),
                          ),
                        )
                      ]
                    : []),
            ),

            const SizedBox(height: 10),

            // Status
            Row(
              children: [
                StatusChip(
                    status: role.isActive ? 'active' : 'inactive'),
                const Spacer(),
                Icon(Icons.edit_outlined,
                    size: 14, color: cs.onSurface.withValues(alpha: 0.3)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PermBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _PermBadge({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 3),
          Text(label,
              style: TextStyle(
                  fontSize: 10, color: color, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

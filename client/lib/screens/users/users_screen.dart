import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/user.dart';
import '../../providers/realtime_provider.dart';
import '../../providers/user_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common_widgets.dart';
import '../../data/mock_ui_text.dart';

class UsersScreen extends ConsumerStatefulWidget {
  const UsersScreen({super.key});

  @override
  ConsumerState<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends ConsumerState<UsersScreen> {
  final _searchController = TextEditingController();
  String _search = '';
  String _roleFilter = MockUiText.all;
  int _touchedIndex = -1;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(userNotifierProvider);

    ref.listen(realtimeStreamProvider, (_, next) {
      next.whenData((msg) {
        final type = msg['type'] as String? ?? '';
        if (type == 'user.created' ||
            type == 'user.updated' ||
            type == 'user.deleted') {
          ref.invalidate(userNotifierProvider);
        }
      });
    });

    return Scaffold(
      body: usersAsync.when(
        loading: () => const LoadingList(),
        error: (e, _) => AppErrorWidget(
          message: e.toString(),
          onRetry: () => ref.read(userNotifierProvider.notifier).refresh(),
        ),
        data: (users) {
          final roles = <String>{MockUiText.all, ...users.map((u) => u.role)};
          final filtered = users.where((u) {
            final matchesSearch = _search.isEmpty ||
                u.fullName.toLowerCase().contains(_search.toLowerCase()) ||
                u.email.toLowerCase().contains(_search.toLowerCase());
            final matchesRole =
                _roleFilter == MockUiText.all || u.role == _roleFilter;
            return matchesSearch && matchesRole;
          }).toList();

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: AppPageLayout.contentPadding(
                    context,
                    horizontal: 20,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      AppPageHeader(
                        title: MockUiText.teamMembers,
                        description: MockUiText
                            .inviteTeammatesUnderstandAccountActivityAndBalanceRolesSoCol,
                        actionLabel: MockUiText.addUser,
                        compactActionLabel: MockUiText.add,
                        actionIcon: Icons.person_add_outlined,
                        onAction: () => context.push('/users/new/edit'),
                      ).animate().fadeIn(duration: 300.ms),
                      const SizedBox(height: 14),

                      // Stats row
                      _UserStatsRow(users: users),
                      const SizedBox(height: 16),

                      // Chart + filter column
                      LayoutBuilder(builder: (context, constraints) {
                        final isWide = constraints.maxWidth > 600;
                        if (isWide) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                  flex: 5,
                                  child: _RoleDonut(
                                    users: users,
                                    touchedIndex: _touchedIndex,
                                    onTouch: (i) =>
                                        setState(() => _touchedIndex = i),
                                  )),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 3,
                                child: Column(
                                  children: [
                                    _ActivityCard(users: users),
                                  ],
                                ),
                              ),
                            ],
                          );
                        }
                        return Column(
                          children: [
                            _RoleDonut(
                              users: users,
                              touchedIndex: _touchedIndex,
                              onTouch: (i) => setState(() => _touchedIndex = i),
                            ),
                            const SizedBox(height: 12),
                            _ActivityCard(users: users),
                          ],
                        );
                      }),
                      const SizedBox(height: 16),

                      // Search + filter
                      Row(
                        children: [
                          Expanded(
                            child: SearchField(
                              controller: _searchController,
                              hintText: MockUiText.searchMembers,
                              onChanged: (v) => setState(() => _search = v),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _RoleDropdown(
                            roles: roles.toList(),
                            selected: _roleFilter,
                            onChanged: (v) => setState(() => _roleFilter = v!),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
              if (filtered.isEmpty)
                SliverFillRemaining(
                  child: EmptyState(
                    title: MockUiText.noMembersFound,
                    subtitle: MockUiText.tryAdjustingYourSearchOrFilters,
                    icon: Icons.people_outline,
                    actionLabel: MockUiText.addUser,
                    onAction: () => context.push('/users/new/edit'),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) => Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                      child: _UserCard(
                        user: filtered[i],
                        index: i,
                        onEdit: () =>
                            context.push('/users/${filtered[i].id}/edit'),
                        onDelete: () => _confirmDelete(context, filtered[i]),
                      ),
                    ),
                    childCount: filtered.length,
                  ),
                ),
              const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
            ],
          );
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, User user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => ConfirmDialog(
        title: MockUiText.removeUser,
        message: MockUiText.removeThisUserFromTheSystem,
      ),
    );
    if (confirmed == true) {
      await ref.read(userNotifierProvider.notifier).delete(user.id);
    }
  }
}

// ── Stats Row ──────────────────────────────────────────────────────

class _UserStatsRow extends StatelessWidget {
  final List<User> users;

  const _UserStatsRow({required this.users});

  @override
  Widget build(BuildContext context) {
    final total = users.length;
    final active = users.where((u) => u.isActive).length;
    final admins =
        users.where((u) => u.role == 'admin' || u.role == 'owner').length;
    final members = total - admins;

    return LayoutBuilder(builder: (context, constraints) {
      final cols = constraints.maxWidth > 500 ? 4 : 2;
      return GridView.count(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: cols,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.6,
        children: [
          AppStatCard(
            icon: Icons.people_rounded,
            value: '$total',
            label: MockUiText.totalMembers,
            color: AppColors.primary,
          ),
          AppStatCard(
            icon: Icons.check_circle_rounded,
            value: '$active',
            label: MockUiText.active,
            color: AppColors.success,
          ),
          AppStatCard(
            icon: Icons.admin_panel_settings_rounded,
            value: '$admins',
            label: MockUiText.admins,
            color: AppColors.warning,
          ),
          AppStatCard(
            icon: Icons.person_rounded,
            value: '$members',
            label: MockUiText.members,
            color: AppColors.info,
          ),
        ],
      );
    });
  }
}

// ── Role Donut Chart ───────────────────────────────────────────────

class _RoleDonut extends StatelessWidget {
  final List<User> users;
  final int touchedIndex;
  final ValueChanged<int> onTouch;

  const _RoleDonut({
    required this.users,
    required this.touchedIndex,
    required this.onTouch,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // Group users by role
    final roleCounts = <String, int>{};
    for (final u in users) {
      roleCounts[u.role] = (roleCounts[u.role] ?? 0) + 1;
    }
    final entries = roleCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    const palette = AppColors.chartColors;

    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(MockUiText.roleDistribution,
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700)),
          Text(MockUiText.membersByAssignedRole,
              style: TextStyle(
                  fontSize: 11, color: cs.onSurface.withValues(alpha: 0.45))),
          const SizedBox(height: 16),
          Row(
            children: [
              SizedBox(
                width: 140,
                height: 140,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 3,
                    centerSpaceRadius: 38,
                    pieTouchData: PieTouchData(
                      touchCallback: (event, response) {
                        onTouch(
                          response?.touchedSection?.touchedSectionIndex ?? -1,
                        );
                      },
                    ),
                    sections: entries.asMap().entries.map((e) {
                      final isTouched = touchedIndex == e.key;
                      final color = palette[e.key % palette.length];
                      return PieChartSectionData(
                        value: e.value.value.toDouble(),
                        color: color,
                        radius: isTouched ? 46 : 38,
                        showTitle: false,
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: entries.asMap().entries.map((e) {
                    final color = palette[e.key % palette.length];
                    final pct = (e.value.value / users.length * 100).round();
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              e.value.key,
                              style: const TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w500),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            MockUiText.distributionLegend(e.value.value, pct),
                            style: TextStyle(
                                fontSize: 11,
                                color: cs.onSurface.withValues(alpha: 0.55)),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Activity Card ──────────────────────────────────────────────────

class _ActivityCard extends StatelessWidget {
  final List<User> users;

  const _ActivityCard({required this.users});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final active = users.where((u) => u.isActive).length;
    final inactive = users.length - active;

    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(MockUiText.statusOverview,
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700)),
          Text(MockUiText.accountActivity,
              style: TextStyle(
                  fontSize: 11, color: cs.onSurface.withValues(alpha: 0.45))),
          const SizedBox(height: 16),
          _StatusBar(
            label: MockUiText.active,
            count: active,
            total: users.length,
            color: AppColors.success,
          ),
          const SizedBox(height: 10),
          _StatusBar(
            label: MockUiText.inactive,
            count: inactive,
            total: users.length,
            color: AppColors.lightTextSecondary,
          ),
        ],
      ),
    );
  }
}

class _StatusBar extends StatelessWidget {
  final String label;
  final int count;
  final int total;
  final Color color;

  const _StatusBar({
    required this.label,
    required this.count,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final pct = total == 0 ? 0.0 : count / total;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 12)),
            Text(
              count.toString(),
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w700, color: color),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct,
            backgroundColor: color.withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation(color),
            minHeight: 7,
          ),
        ),
      ],
    );
  }
}

// ── Role Dropdown ──────────────────────────────────────────────────

class _RoleDropdown extends StatelessWidget {
  final List<String> roles;
  final String selected;
  final ValueChanged<String?> onChanged;

  const _RoleDropdown({
    required this.roles,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: cs.outline.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(12),
        color: cs.surface,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selected,
          isDense: true,
          items: roles
              .map((r) => DropdownMenuItem(
                  value: r,
                  child: Text(r, style: const TextStyle(fontSize: 13))))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

// ── User Card ──────────────────────────────────────────────────────

class _UserCard extends StatelessWidget {
  final User user;
  final int index;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _UserCard({
    required this.user,
    required this.index,
    required this.onEdit,
    required this.onDelete,
  });

  Color _roleColor() {
    switch (user.role) {
      case 'admin':
      case 'owner':
        return AppColors.error;
      case 'manager':
        return AppColors.warning;
      case 'member':
        return AppColors.primary;
      default:
        return AppColors.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final roleColor = _roleColor();
    final joined = user.createdAt != null
        ? '${user.createdAt!.day}/${user.createdAt!.month}/${user.createdAt!.year}'
        : null;

    return AppCard(
      onTap: onEdit,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Avatar
          Stack(
            children: [
              AvatarWidget(
                imageUrl: user.avatar,
                initials: user.initials,
                size: 48,
              ),
              if (user.isActive)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 13,
                    height: 13,
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                      border: Border.all(color: cs.surface, width: 2),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        user.fullName,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // Role badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: roleColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        user.role,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: roleColor,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Icon(Icons.email_outlined,
                        size: 12, color: cs.onSurface.withValues(alpha: 0.45)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        user.email,
                        style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurface.withValues(alpha: 0.55),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    if (user.phone != null && user.phone!.isNotEmpty) ...[
                      _InfoChip(
                        icon: Icons.phone_outlined,
                        label: user.phone!,
                      ),
                      const SizedBox(width: 6),
                    ],
                    if (joined != null)
                      _InfoChip(
                        icon: Icons.calendar_today_outlined,
                        label: MockUiText.joined(joined),
                      ),
                    const Spacer(),
                    StatusChip(status: user.isActive ? 'active' : 'inactive'),
                  ],
                ),
              ],
            ),
          ),

          // Actions
          GlassContextMenuButton<String>(
            icon: Icon(Icons.more_vert,
                size: 18, color: cs.onSurface.withValues(alpha: 0.45)),
            itemBuilder: (_) => [
              GlassContextMenuItem(
                  value: 'edit', child: Text(MockUiText.edit)),
              GlassContextMenuItem(
                value: 'delete',
                child: Text(MockUiText.remove,
                    style: const TextStyle(color: AppColors.error)),
              ),
            ],
            onSelected: (v) {
              if (v == 'edit') onEdit();
              if (v == 'delete') onDelete();
            },
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: index * 50))
        .slideY(begin: 0.04, curve: Curves.easeOut);
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: cs.onSurface.withValues(alpha: 0.4)),
        const SizedBox(width: 3),
        Text(
          label,
          style: TextStyle(
              fontSize: 11, color: cs.onSurface.withValues(alpha: 0.45)),
        ),
      ],
    );
  }
}

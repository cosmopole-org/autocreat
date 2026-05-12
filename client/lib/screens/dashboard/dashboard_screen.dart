import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants.dart';
import '../../providers/auth_provider.dart';
import '../../providers/company_provider.dart';
import '../../providers/flow_provider.dart';
import '../../providers/ticket_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common_widgets.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final companiesAsync = ref.watch(companiesProvider);
    final ticketsAsync = ref.watch(ticketsProvider(null));
    final flowsAsync = ref.watch(flowsProvider(null));

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            _DashboardHeader(user: user),
            const SizedBox(height: 24),

            // Stats row
            LayoutBuilder(builder: (context, constraints) {
              final crossCount = constraints.maxWidth > 800 ? 4 : 2;
              return GridView.count(
                crossAxisCount: crossCount,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: constraints.maxWidth > 800 ? 1.8 : 1.5,
                children: [
                  _StatCard(
                    label: 'Companies',
                    value: companiesAsync.maybeWhen(
                        data: (l) => l.length.toString(), orElse: () => '-'),
                    icon: Icons.business,
                    color: AppColors.primary,
                    onTap: () => context.go(AppRoutes.companies),
                  ),
                  _StatCard(
                    label: 'Flows',
                    value: flowsAsync.maybeWhen(
                        data: (l) => l.length.toString(), orElse: () => '-'),
                    icon: Icons.account_tree,
                    color: AppColors.accent,
                    onTap: () => context.go(AppRoutes.flows),
                  ),
                  _StatCard(
                    label: 'Open Tickets',
                    value: ticketsAsync.maybeWhen(
                        data: (l) => l
                            .where((t) => t.status.name == 'open')
                            .length
                            .toString(),
                        orElse: () => '-'),
                    icon: Icons.support_agent,
                    color: AppColors.warning,
                    onTap: () => context.go(AppRoutes.tickets),
                  ),
                  _StatCard(
                    label: 'Resolved',
                    value: ticketsAsync.maybeWhen(
                        data: (l) => l
                            .where((t) => t.status.name == 'resolved')
                            .length
                            .toString(),
                        orElse: () => '-'),
                    icon: Icons.check_circle_outline,
                    color: AppColors.success,
                    onTap: () => context.go(AppRoutes.tickets),
                  ),
                ],
              );
            }),
            const SizedBox(height: 24),

            // Row: Chart + Recent
            LayoutBuilder(builder: (context, constraints) {
              final isWide = constraints.maxWidth > 800;
              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                        flex: 3, child: _ActivityChart().animate().fadeIn()),
                    const SizedBox(width: 16),
                    Expanded(
                        flex: 2,
                        child: _RecentTickets(ticketsAsync: ticketsAsync)),
                  ],
                );
              }
              return Column(
                children: [
                  _ActivityChart().animate().fadeIn(),
                  const SizedBox(height: 16),
                  _RecentTickets(ticketsAsync: ticketsAsync),
                ],
              );
            }),
            const SizedBox(height: 24),

            // Quick actions
            _QuickActions(),
          ],
        ),
      ),
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  final dynamic user;

  const _DashboardHeader({this.user});

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 17
            ? 'Good afternoon'
            : 'Good evening';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$greeting, ${user?.firstName ?? 'there'}!',
          style: Theme.of(context).textTheme.headlineMedium,
        ).animate().fadeIn().slideX(begin: -0.05),
        const SizedBox(height: 4),
        Text(
          'Here\'s what\'s happening in your organization',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.lightTextSecondary,
              ),
        ).animate().fadeIn(delay: 100.ms),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
              ),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn().scale(begin: const Offset(0.95, 0.95));
  }
}

class _ActivityChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Activity Overview',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text('Last 7 days',
              style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 20),
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 20,
                borderData: FlBorderData(show: false),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: isDark
                        ? AppColors.darkBorder
                        : AppColors.lightBorder,
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const days = [
                          'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'
                        ];
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            days[value.toInt() % 7],
                            style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.lightTextSecondary),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: List.generate(
                  7,
                  (i) => BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: [8.0, 12.0, 5.0, 15.0, 10.0, 3.0, 7.0][i],
                        color: AppColors.primary,
                        width: 20,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(6)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentTickets extends StatelessWidget {
  final AsyncValue<dynamic> ticketsAsync;

  const _RecentTickets({required this.ticketsAsync});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Recent Tickets',
                  style: Theme.of(context).textTheme.titleMedium),
              TextButton(
                onPressed: () => context.go(AppRoutes.tickets),
                child: const Text('View all'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ticketsAsync.when(
            loading: () => const LoadingList(count: 3),
            error: (e, _) => Text('Error loading tickets',
                style: TextStyle(color: AppColors.error)),
            data: (tickets) {
              if (tickets.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Text('No tickets yet',
                        style:
                            TextStyle(color: AppColors.lightTextSecondary)),
                  ),
                );
              }
              return Column(
                children: tickets
                    .take(5)
                    .map<Widget>((t) => ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.warning.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.confirmation_number_outlined,
                                size: 16, color: AppColors.warning),
                          ),
                          title: Text(t.title,
                              maxLines: 1, overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 13)),
                          subtitle: Text(t.status.displayName,
                              style: const TextStyle(fontSize: 11)),
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                        ))
                    .toList(),
              );
            },
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms);
  }
}

class _QuickActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final actions = [
      ('New Flow', Icons.account_tree_outlined, AppColors.primary, AppRoutes.flows),
      ('New Form', Icons.dynamic_form_outlined, AppColors.accent, AppRoutes.forms),
      ('New Role', Icons.shield_outlined, AppColors.success, AppRoutes.roles),
      ('New Ticket', Icons.support_agent_outlined, AppColors.warning, AppRoutes.tickets),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Quick Actions',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: actions
              .map((a) => SizedBox(
                    width: 160,
                    child: OutlinedButton.icon(
                      onPressed: () => context.go(a.$4),
                      icon: Icon(a.$2, size: 18, color: a.$3),
                      label: Text(a.$1,
                          style: TextStyle(color: a.$3)),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: a.$3.withOpacity(0.3)),
                        padding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 16),
                      ),
                    ),
                  ))
              .toList(),
        ).animate().fadeIn(delay: 400.ms),
      ],
    );
  }
}

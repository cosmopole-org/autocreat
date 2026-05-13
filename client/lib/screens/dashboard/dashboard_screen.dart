import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:percent_indicator/percent_indicator.dart';
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _WelcomeBanner(user: user)
                .animate()
                .fadeIn(duration: 400.ms)
                .slideY(begin: -0.05),
            const SizedBox(height: 24),

            // KPI stat cards
            _KpiRow(
              companiesAsync: companiesAsync,
              flowsAsync: flowsAsync,
              ticketsAsync: ticketsAsync,
            ),
            const SizedBox(height: 24),

            // Charts row
            LayoutBuilder(builder: (context, constraints) {
              final isWide = constraints.maxWidth > 780;
              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 5, child: _ActivityLineChart()),
                    const SizedBox(width: 16),
                    Expanded(flex: 3, child: _TicketStatusDonut(ticketsAsync: ticketsAsync)),
                  ],
                );
              }
              return Column(children: [
                _ActivityLineChart(),
                const SizedBox(height: 16),
                _TicketStatusDonut(ticketsAsync: ticketsAsync),
              ]);
            }),
            const SizedBox(height: 16),

            // Second charts row
            LayoutBuilder(builder: (context, constraints) {
              final isWide = constraints.maxWidth > 780;
              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: _PriorityBarChart(ticketsAsync: ticketsAsync)),
                    const SizedBox(width: 16),
                    Expanded(flex: 4, child: _RecentTicketsList(ticketsAsync: ticketsAsync)),
                  ],
                );
              }
              return Column(children: [
                _PriorityBarChart(ticketsAsync: ticketsAsync),
                const SizedBox(height: 16),
                _RecentTicketsList(ticketsAsync: ticketsAsync),
              ]);
            }),
            const SizedBox(height: 16),

            // Performance metrics
            _PerformanceSection(ticketsAsync: ticketsAsync),
            const SizedBox(height: 16),

            // Quick actions
            _QuickActionsSection(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────
// WELCOME BANNER
// ────────────────────────────────────────────────────────────────

class _WelcomeBanner extends StatelessWidget {
  final dynamic user;

  const _WelcomeBanner({this.user});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final hour = DateTime.now().hour;
    final greeting =
        hour < 12 ? 'Good morning' : hour < 17 ? 'Good afternoon' : 'Good evening';
    final now = DateTime.now();
    final dayName = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][now.weekday - 1];
    final monthName = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ][now.month - 1];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primaryLight,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$greeting, ${user?.firstName ?? 'there'}! 👋',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Here\'s what\'s happening in your organization today.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _BannerPill(
                      icon: Icons.calendar_today_rounded,
                      label: '$dayName, ${now.day} $monthName ${now.year}',
                    ),
                    const SizedBox(width: 8),
                    _BannerPill(
                      icon: Icons.access_time_rounded,
                      label: '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
        ],
      ),
    );
  }
}

class _BannerPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _BannerPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 13),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
                color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────
// KPI STAT CARDS
// ────────────────────────────────────────────────────────────────

class _KpiRow extends StatelessWidget {
  final AsyncValue<dynamic> companiesAsync;
  final AsyncValue<dynamic> flowsAsync;
  final AsyncValue<dynamic> ticketsAsync;

  const _KpiRow({
    required this.companiesAsync,
    required this.flowsAsync,
    required this.ticketsAsync,
  });

  @override
  Widget build(BuildContext context) {
    final companies =
        companiesAsync.maybeWhen(data: (l) => l.length, orElse: () => null);
    final flows =
        flowsAsync.maybeWhen(data: (l) => l.length, orElse: () => null);
    final openTickets = ticketsAsync.maybeWhen(
        data: (l) => l.where((t) => t.status.name == 'open').length,
        orElse: () => null);
    final resolvedTickets = ticketsAsync.maybeWhen(
        data: (l) => l.where((t) => t.status.name == 'resolved').length,
        orElse: () => null);

    final cards = [
      _KpiData(
        label: 'Companies',
        value: companies?.toString() ?? '—',
        subtitle: 'Active organizations',
        icon: Icons.business_rounded,
        color: AppColors.primary,
        route: AppRoutes.companies,
        trend: '+2 this month',
        trendUp: true,
      ),
      _KpiData(
        label: 'Active Flows',
        value: flows?.toString() ?? '—',
        subtitle: 'Automation pipelines',
        icon: Icons.account_tree_rounded,
        color: AppColors.accent,
        route: AppRoutes.flows,
        trend: 'Running now',
        trendUp: true,
      ),
      _KpiData(
        label: 'Open Tickets',
        value: openTickets?.toString() ?? '—',
        subtitle: 'Needs attention',
        icon: Icons.support_agent_rounded,
        color: AppColors.warning,
        route: AppRoutes.tickets,
        trend: 'Pending review',
        trendUp: false,
      ),
      _KpiData(
        label: 'Resolved',
        value: resolvedTickets?.toString() ?? '—',
        subtitle: 'Closed tickets',
        icon: Icons.check_circle_rounded,
        color: AppColors.success,
        route: AppRoutes.tickets,
        trend: 'All time',
        trendUp: true,
      ),
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
          childAspectRatio: constraints.maxWidth > 700 ? 1.7 : 1.45,
        ),
        itemCount: cards.length,
        itemBuilder: (context, i) => _KpiCard(data: cards[i])
            .animate(delay: (i * 80).ms)
            .fadeIn()
            .scale(begin: const Offset(0.94, 0.94)),
      );
    });
  }
}

class _KpiData {
  final String label;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String route;
  final String trend;
  final bool trendUp;

  const _KpiData({
    required this.label,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.route,
    required this.trend,
    required this.trendUp,
  });
}

class _KpiCard extends StatelessWidget {
  final _KpiData data;

  const _KpiCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => context.go(data.route),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.outline.withOpacity(0.5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: data.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(data.icon, color: data.color, size: 20),
                ),
                Icon(
                  data.trendUp
                      ? Icons.trending_up_rounded
                      : Icons.trending_flat_rounded,
                  size: 16,
                  color: data.trendUp ? AppColors.success : AppColors.warning,
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.value,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: data.color,
                    letterSpacing: -1,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  data.label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                ),
                Text(
                  data.subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: cs.onSurface.withOpacity(0.45),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────
// ACTIVITY LINE CHART
// ────────────────────────────────────────────────────────────────

class _ActivityLineChart extends StatelessWidget {
  static const _ticketData = [3.0, 7.0, 4.0, 10.0, 6.0, 8.0, 5.0];
  static const _flowData = [1.0, 4.0, 2.0, 6.0, 4.0, 5.0, 3.0];
  static const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return _ChartCard(
      title: 'Activity Overview',
      subtitle: 'Tickets & flows – last 7 days',
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Legend(color: AppColors.primary, label: 'Tickets'),
          const SizedBox(width: 12),
          _Legend(color: AppColors.accent, label: 'Flows'),
        ],
      ),
      child: SizedBox(
        height: 200,
        child: LineChart(
          LineChartData(
            minY: 0,
            maxY: 14,
            clipData: const FlClipData.all(),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: 2,
              getDrawingHorizontalLine: (_) => FlLine(
                color: cs.outline.withOpacity(0.2),
                strokeWidth: 1,
              ),
            ),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: 1,
                  getTitlesWidget: (v, _) => Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      _days[v.toInt() % 7],
                      style: TextStyle(
                          fontSize: 11, color: cs.onSurface.withOpacity(0.45)),
                    ),
                  ),
                ),
              ),
            ),
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (_) => isDark ? AppColors.darkCard : Colors.white,
                tooltipRoundedRadius: 10,
                getTooltipItems: (spots) => spots.map((s) {
                  final label = s.barIndex == 0 ? 'Tickets' : 'Flows';
                  final color =
                      s.barIndex == 0 ? AppColors.primary : AppColors.accent;
                  return LineTooltipItem(
                    '$label: ${s.y.toInt()}',
                    TextStyle(
                        color: color,
                        fontWeight: FontWeight.w600,
                        fontSize: 12),
                  );
                }).toList(),
              ),
            ),
            lineBarsData: [
              // Tickets
              LineChartBarData(
                spots: List.generate(
                    7, (i) => FlSpot(i.toDouble(), _ticketData[i])),
                isCurved: true,
                curveSmoothness: 0.3,
                color: AppColors.primary,
                barWidth: 2.5,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withOpacity(0.18),
                      AppColors.primary.withOpacity(0.0),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
              // Flows
              LineChartBarData(
                spots: List.generate(
                    7, (i) => FlSpot(i.toDouble(), _flowData[i])),
                isCurved: true,
                curveSmoothness: 0.3,
                color: AppColors.accent,
                barWidth: 2.5,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    colors: [
                      AppColors.accent.withOpacity(0.12),
                      AppColors.accent.withOpacity(0.0),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: 200.ms);
  }
}

// ────────────────────────────────────────────────────────────────
// TICKET STATUS DONUT
// ────────────────────────────────────────────────────────────────

class _TicketStatusDonut extends StatefulWidget {
  final AsyncValue<dynamic> ticketsAsync;

  const _TicketStatusDonut({required this.ticketsAsync});

  @override
  State<_TicketStatusDonut> createState() => _TicketStatusDonutState();
}

class _TicketStatusDonutState extends State<_TicketStatusDonut> {
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final data = widget.ticketsAsync.maybeWhen(
      data: (tickets) {
        final list = tickets as List<dynamic>;
        final open = list.where((t) => t.status.name == 'open').length;
        final inProgress =
            list.where((t) => t.status.name == 'inProgress').length;
        final resolved =
            list.where((t) => t.status.name == 'resolved').length;
        final closed = list.where((t) => t.status.name == 'closed').length;
        return <int>[open, inProgress, resolved, closed];
      },
      orElse: () => <int>[4, 3, 8, 2],
    );

    final labels = ['Open', 'In Progress', 'Resolved', 'Closed'];
    final colors = [
      AppColors.warning,
      AppColors.info,
      AppColors.success,
      AppColors.lightTextSecondary,
    ];
    final total = data.fold<int>(0, (int a, int b) => a + b);

    return _ChartCard(
      title: 'Ticket Status',
      subtitle: 'Distribution overview',
      child: Column(
        children: [
          SizedBox(
            height: 160,
            child: total == 0
                ? Center(
                    child: Text('No tickets',
                        style: TextStyle(color: cs.onSurface.withOpacity(0.4))))
                : PieChart(
                    PieChartData(
                      sectionsSpace: 3,
                      centerSpaceRadius: 44,
                      pieTouchData: PieTouchData(
                        touchCallback: (event, response) {
                          setState(() {
                            _touchedIndex =
                                response?.touchedSection?.touchedSectionIndex ??
                                    -1;
                          });
                        },
                      ),
                      sections: List.generate(4, (i) {
                        final isTouched = _touchedIndex == i;
                        return PieChartSectionData(
                          value: data[i].toDouble(),
                          color: colors[i],
                          radius: isTouched ? 52 : 44,
                          showTitle: false,
                        );
                      }),
                    ),
                  ),
          ),
          const SizedBox(height: 16),
          ...List.generate(4, (i) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                          color: colors[i], shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text(labels[i],
                            style: const TextStyle(fontSize: 12))),
                    Text(
                      data[i].toString(),
                      style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              )),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms);
  }
}

// ────────────────────────────────────────────────────────────────
// PRIORITY BAR CHART
// ────────────────────────────────────────────────────────────────

class _PriorityBarChart extends StatelessWidget {
  final AsyncValue<dynamic> ticketsAsync;

  const _PriorityBarChart({required this.ticketsAsync});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final data = ticketsAsync.maybeWhen(
      data: (tickets) {
        final list = tickets as List<dynamic>;
        return <double>[
          list.where((t) => t.priority.name == 'low').length.toDouble(),
          list.where((t) => t.priority.name == 'medium').length.toDouble(),
          list.where((t) => t.priority.name == 'high').length.toDouble(),
          list.where((t) => t.priority.name == 'urgent').length.toDouble(),
        ];
      },
      orElse: () => <double>[3.0, 7.0, 5.0, 2.0],
    );

    final maxY = (data.reduce((double a, double b) => a > b ? a : b) + 2.0)
        .clamp(4.0, 20.0);

    final colors = [
      AppColors.success,
      AppColors.info,
      AppColors.warning,
      AppColors.error,
    ];
    final labels = ['Low', 'Med', 'High', 'Urgent'];

    return _ChartCard(
      title: 'Priority Breakdown',
      subtitle: 'Tickets by priority level',
      child: SizedBox(
        height: 180,
        child: BarChart(
          BarChartData(
            maxY: maxY,
            borderData: FlBorderData(show: false),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (_) => FlLine(
                color: cs.outline.withOpacity(0.2),
                strokeWidth: 1,
              ),
            ),
            titlesData: FlTitlesData(
              leftTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (v, _) => Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      labels[v.toInt()],
                      style: TextStyle(
                          fontSize: 11,
                          color: cs.onSurface.withOpacity(0.5)),
                    ),
                  ),
                ),
              ),
            ),
            barGroups: List.generate(
              4,
              (i) => BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: data[i],
                    color: colors[i],
                    width: 28,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(6)),
                    backDrawRodData: BackgroundBarChartRodData(
                      show: true,
                      toY: maxY,
                      color: colors[i].withOpacity(0.06),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: 400.ms);
  }
}

// ────────────────────────────────────────────────────────────────
// RECENT TICKETS LIST
// ────────────────────────────────────────────────────────────────

class _RecentTicketsList extends StatelessWidget {
  final AsyncValue<dynamic> ticketsAsync;

  const _RecentTicketsList({required this.ticketsAsync});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return _ChartCard(
      title: 'Recent Tickets',
      subtitle: 'Latest activity',
      trailing: TextButton(
        onPressed: () => context.go(AppRoutes.tickets),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: const Text('View all', style: TextStyle(fontSize: 12)),
      ),
      child: ticketsAsync.when(
        loading: () => const _TicketShimmer(),
        error: (e, _) => Text('Error loading',
            style: TextStyle(color: AppColors.error, fontSize: 13)),
        data: (tickets) {
          if (tickets.isEmpty) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text('No tickets yet',
                    style: TextStyle(
                        color: cs.onSurface.withOpacity(0.4), fontSize: 13)),
              ),
            );
          }
          return Column(
            children: tickets.take(5).map<Widget>((t) {
              final priorityColor = {
                    'low': AppColors.success,
                    'medium': AppColors.info,
                    'high': AppColors.warning,
                    'urgent': AppColors.error,
                  }[t.priority.name] ??
                  AppColors.info;
              final statusColor = {
                    'open': AppColors.warning,
                    'inProgress': AppColors.info,
                    'resolved': AppColors.success,
                    'closed': AppColors.lightTextSecondary,
                  }[t.status.name] ??
                  AppColors.info;

              return Container(
                margin: const EdgeInsets.symmetric(vertical: 4),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: cs.outline.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 36,
                      decoration: BoxDecoration(
                        color: priorityColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  t.status.displayName,
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: statusColor,
                                      fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded,
                        size: 16, color: cs.onSurface.withOpacity(0.3)),
                  ],
                ),
              );
            }).toList(),
          );
        },
      ),
    ).animate().fadeIn(delay: 350.ms);
  }
}

class _TicketShimmer extends StatelessWidget {
  const _TicketShimmer();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        3,
        (_) => Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.lightBorder.withOpacity(0.5),
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────
// PERFORMANCE METRICS
// ────────────────────────────────────────────────────────────────

class _PerformanceSection extends StatelessWidget {
  final AsyncValue<dynamic> ticketsAsync;

  const _PerformanceSection({required this.ticketsAsync});

  @override
  Widget build(BuildContext context) {
    final metrics = ticketsAsync.maybeWhen(
      data: (tickets) {
        final list = tickets as List<dynamic>;
        final total = list.length;
        if (total == 0) {
          return <_MetricData>[
            _MetricData('Resolution Rate', 0, AppColors.success),
            _MetricData('In Progress', 0, AppColors.info),
            _MetricData('SLA Compliance', 0, AppColors.primary),
          ];
        }
        final resolved =
            list.where((t) => t.status.name == 'resolved').length;
        final inProgress =
            list.where((t) => t.status.name == 'inProgress').length;
        final nonUrgent =
            list.where((t) => t.priority.name != 'urgent').length;
        return <_MetricData>[
          _MetricData('Resolution Rate', resolved / total, AppColors.success),
          _MetricData('In Progress', inProgress / total, AppColors.info),
          _MetricData('SLA Compliance', nonUrgent / total, AppColors.primary),
        ];
      },
      orElse: () => <_MetricData>[
        _MetricData('Resolution Rate', 0.72, AppColors.success),
        _MetricData('In Progress', 0.18, AppColors.info),
        _MetricData('SLA Compliance', 0.85, AppColors.primary),
      ],
    );

    return _ChartCard(
      title: 'Performance Metrics',
      subtitle: 'Ticket KPIs at a glance',
      child: Column(
        children: metrics
            .map(
              (m) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(m.label,
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w500)),
                        Text(
                          '${(m.value * 100).toInt()}%',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: m.color),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    LinearPercentIndicator(
                      lineHeight: 8,
                      percent: m.value.clamp(0.0, 1.0),
                      backgroundColor: m.color.withOpacity(0.1),
                      progressColor: m.color,
                      barRadius: const Radius.circular(4),
                      padding: EdgeInsets.zero,
                      animation: true,
                      animationDuration: 900,
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    ).animate().fadeIn(delay: 450.ms);
  }
}

class _MetricData {
  final String label;
  final double value;
  final Color color;

  const _MetricData(this.label, this.value, this.color);
}

// ────────────────────────────────────────────────────────────────
// QUICK ACTIONS
// ────────────────────────────────────────────────────────────────

class _QuickActionsSection extends StatelessWidget {
  final _actions = const [
    (
      'New Flow',
      Icons.account_tree_rounded,
      AppColors.primary,
      AppRoutes.flows
    ),
    (
      'New Form',
      Icons.dynamic_form_rounded,
      AppColors.accent,
      AppRoutes.forms
    ),
    (
      'Add User',
      Icons.person_add_rounded,
      AppColors.success,
      AppRoutes.users
    ),
    (
      'New Ticket',
      Icons.support_agent_rounded,
      AppColors.warning,
      AppRoutes.tickets
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Quick Actions',
            style:
                Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        LayoutBuilder(builder: (context, constraints) {
          final isWide = constraints.maxWidth > 500;
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _actions.asMap().entries.map((e) {
              final (label, icon, color, route) = e.value;
              return GestureDetector(
                onTap: () => context.go(route),
                child: Container(
                  width: isWide
                      ? (constraints.maxWidth - 36) / 4
                      : (constraints.maxWidth - 12) / 2,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cs.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: color.withOpacity(0.25)),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(isDark ? 0.08 : 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(icon, color: color, size: 18),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          label,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: cs.onSurface,
                          ),
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios_rounded,
                          size: 12, color: color.withOpacity(0.6)),
                    ],
                  ),
                ),
              ).animate(delay: (e.key * 70).ms).fadeIn().slideX(begin: 0.05);
            }).toList(),
          );
        }),
      ],
    );
  }
}

// ────────────────────────────────────────────────────────────────
// SHARED CHART CARD WRAPPER
// ────────────────────────────────────────────────────────────────

class _ChartCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;
  final Widget? trailing;

  const _ChartCard({
    required this.title,
    required this.subtitle,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outline.withOpacity(0.4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  Text(subtitle,
                      style: TextStyle(
                          fontSize: 11,
                          color: cs.onSurface.withOpacity(0.45))),
                ],
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;

  const _Legend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 3,
          decoration: BoxDecoration(
              color: color, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 5),
        Text(label,
            style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
      ],
    );
  }
}

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:percent_indicator/percent_indicator.dart';

import '../../core/constants.dart';
import '../../models/company.dart';
import '../../models/ticket.dart';
import '../../providers/auth_provider.dart';
import '../../providers/company_provider.dart';
import '../../providers/flow_provider.dart';
import '../../providers/realtime_provider.dart';
import '../../providers/ticket_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common_widgets.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final companiesAsync = ref.watch(companiesProvider);
    final ticketsAsync = ref.watch(ticketsProvider(null));
    final flowsAsync = ref.watch(flowsProvider(null));

    ref.listen(realtimeStreamProvider, (_, next) {
      next.whenData((msg) {
        final type = msg['type'] as String? ?? '';
        if (type == 'ticket.created' || type == 'ticket.status_updated') {
          ref.invalidate(ticketsProvider(null));
        }
        if (type == 'flow.instance_started') {
          ref.invalidate(flowsProvider(null));
        }
        if (type == 'ticket.created' ||
            type == 'ticket.status_updated' ||
            type == 'flow.instance_started') {
          ref.invalidate(companiesProvider);
        }
      });
    });

    final companies = companiesAsync.valueOrNull ?? <Company>[];
    final tickets = ticketsAsync.valueOrNull ?? <Ticket>[];
    final flowCount = flowsAsync.valueOrNull?.length ?? 0;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SingleChildScrollView(
        padding: AppPageLayout.contentPadding(
          context,
          horizontal: 20,
          bottom: 32,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _WelcomeBanner(user: user)
                .animate()
                .fadeIn(duration: 400.ms)
                .slideY(begin: -0.04, duration: 400.ms),
            const SizedBox(height: 24),
            _KpiRow(
              companyCount: companies.length,
              flowCount: flowCount,
              openTickets:
                  tickets.where((t) => t.status == TicketStatus.open).length,
              resolvedTickets:
                  tickets.where((t) => t.status == TicketStatus.resolved).length,
              isLoading: companiesAsync.isLoading ||
                  ticketsAsync.isLoading ||
                  flowsAsync.isLoading,
            ),
            const SizedBox(height: 24),
            LayoutBuilder(builder: (context, constraints) {
              final wide = constraints.maxWidth > 780;
              if (wide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Expanded(flex: 5, child: _ActivityLineChart()),
                    const SizedBox(width: 16),
                    Expanded(
                        flex: 3, child: _TicketStatusDonut(tickets: tickets)),
                  ],
                );
              }
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const _ActivityLineChart(),
                  const SizedBox(height: 16),
                  _TicketStatusDonut(tickets: tickets),
                ],
              );
            }),
            const SizedBox(height: 16),
            LayoutBuilder(builder: (context, constraints) {
              final wide = constraints.maxWidth > 780;
              if (wide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                        flex: 3,
                        child: _PriorityBarChart(tickets: tickets)),
                    const SizedBox(width: 16),
                    Expanded(
                        flex: 4,
                        child: _RecentTicketsList(tickets: tickets)),
                  ],
                );
              }
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _PriorityBarChart(tickets: tickets),
                  const SizedBox(height: 16),
                  _RecentTicketsList(tickets: tickets),
                ],
              );
            }),
            const SizedBox(height: 16),
            _PerformanceSection(tickets: tickets),
            const SizedBox(height: 16),
            const _QuickActionsSection(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// WELCOME BANNER
// ─────────────────────────────────────────────────────────────

class _WelcomeBanner extends StatelessWidget {
  final dynamic user;

  const _WelcomeBanner({this.user});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final hour = now.hour;
    final greeting =
        hour < 12 ? 'Good morning' : hour < 17 ? 'Good afternoon' : 'Good evening';
    final dayName =
        ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][now.weekday - 1];
    final monthName = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ][now.month - 1];

    final screenWidth = MediaQuery.of(context).size.width;
    final narrow = screenWidth < 600;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(narrow ? 18 : 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
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
                  '$greeting, ${user?.firstName ?? 'there'}!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: narrow ? 18 : 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Here's what's happening in your organization today.",
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: narrow ? 13 : 14,
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _BannerPill(
                      icon: Icons.calendar_today_rounded,
                      label: '$dayName, ${now.day} $monthName ${now.year}',
                    ),
                    _BannerPill(
                      icon: Icons.access_time_rounded,
                      label:
                          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (!narrow) ...[
            const SizedBox(width: 16),
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                color: Colors.white,
                size: 32,
              ),
            ),
          ],
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
        color: Colors.white.withValues(alpha: 0.18),
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
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// KPI CARDS
// ─────────────────────────────────────────────────────────────

class _KpiRow extends StatelessWidget {
  final int companyCount;
  final int flowCount;
  final int openTickets;
  final int resolvedTickets;
  final bool isLoading;

  const _KpiRow({
    required this.companyCount,
    required this.flowCount,
    required this.openTickets,
    required this.resolvedTickets,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final cards = [
      _KpiCardData(
        label: 'Companies',
        value: isLoading ? '—' : companyCount.toString(),
        subtitle: 'Active organizations',
        icon: Icons.business_rounded,
        color: AppColors.primary,
        route: AppRoutes.companies,
        trendUp: true,
      ),
      _KpiCardData(
        label: 'Active Flows',
        value: isLoading ? '—' : flowCount.toString(),
        subtitle: 'Automation pipelines',
        icon: Icons.account_tree_rounded,
        color: AppColors.accent,
        route: AppRoutes.flows,
        trendUp: true,
      ),
      _KpiCardData(
        label: 'Open Tickets',
        value: isLoading ? '—' : openTickets.toString(),
        subtitle: 'Needs attention',
        icon: Icons.support_agent_rounded,
        color: AppColors.warning,
        route: AppRoutes.tickets,
        trendUp: false,
      ),
      _KpiCardData(
        label: 'Resolved',
        value: isLoading ? '—' : resolvedTickets.toString(),
        subtitle: 'Closed tickets',
        icon: Icons.check_circle_rounded,
        color: AppColors.success,
        route: AppRoutes.tickets,
        trendUp: true,
      ),
    ];

    return LayoutBuilder(builder: (context, constraints) {
      final wide = constraints.maxWidth > 700;
      if (wide) {
        return Row(
          children: cards.asMap().entries.map((e) {
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(left: e.key == 0 ? 0 : 12),
                child: _KpiCard(data: e.value)
                    .animate(delay: (e.key * 80).ms)
                    .fadeIn()
                    .scale(begin: const Offset(0.94, 0.94)),
              ),
            );
          }).toList(),
        );
      }
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(children: [
            Expanded(
              child: _KpiCard(data: cards[0])
                  .animate(delay: 0.ms)
                  .fadeIn()
                  .scale(begin: const Offset(0.94, 0.94)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _KpiCard(data: cards[1])
                  .animate(delay: 80.ms)
                  .fadeIn()
                  .scale(begin: const Offset(0.94, 0.94)),
            ),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: _KpiCard(data: cards[2])
                  .animate(delay: 160.ms)
                  .fadeIn()
                  .scale(begin: const Offset(0.94, 0.94)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _KpiCard(data: cards[3])
                  .animate(delay: 240.ms)
                  .fadeIn()
                  .scale(begin: const Offset(0.94, 0.94)),
            ),
          ]),
        ],
      );
    });
  }
}

class _KpiCardData {
  final String label;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String route;
  final bool trendUp;

  const _KpiCardData({
    required this.label,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.route,
    required this.trendUp,
  });
}

class _KpiCard extends ConsumerWidget {
  final _KpiCardData data;

  const _KpiCard({required this.data});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tintedSurface = data.color.withValues(alpha: isDark ? 0.13 : 0.10);

    return AppCard(
      onTap: () => context.go(data.route),
      color: tintedSurface,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: data.color.withValues(alpha: isDark ? 0.18 : 0.14),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: data.color.withValues(alpha: isDark ? 0.24 : 0.18),
                  ),
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
          const SizedBox(height: 12),
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
              color: cs.onSurface.withValues(alpha: 0.45),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// ACTIVITY LINE CHART (static demo data)
// ─────────────────────────────────────────────────────────────

class _ActivityLineChart extends StatelessWidget {
  static const _ticketData = [3.0, 7.0, 4.0, 10.0, 6.0, 8.0, 5.0];
  static const _flowData = [1.0, 4.0, 2.0, 6.0, 4.0, 5.0, 3.0];
  static const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  const _ActivityLineChart();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return _ChartCard(
      title: 'Activity Overview',
      subtitle: 'Tickets & flows – last 7 days',
      trailing: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ChartLegend(color: AppColors.primary, label: 'Tickets'),
          SizedBox(width: 12),
          _ChartLegend(color: AppColors.accent, label: 'Flows'),
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
                color: cs.outline.withValues(alpha: 0.2),
                strokeWidth: 1,
              ),
            ),
            borderData: FlBorderData(show: false),
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
                  interval: 1,
                  getTitlesWidget: (v, _) => Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      _days[v.toInt() % 7],
                      style: TextStyle(
                        fontSize: 11,
                        color: cs.onSurface.withValues(alpha: 0.45),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (_) =>
                    isDark ? AppColors.darkCard : Colors.white,
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
                      fontSize: 12,
                    ),
                  );
                }).toList(),
              ),
            ),
            lineBarsData: [
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
                      AppColors.primary.withValues(alpha: 0.18),
                      AppColors.primary.withValues(alpha: 0.0),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
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
                      AppColors.accent.withValues(alpha: 0.12),
                      AppColors.accent.withValues(alpha: 0.0),
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

// ─────────────────────────────────────────────────────────────
// TICKET STATUS DONUT
// ─────────────────────────────────────────────────────────────

class _TicketStatusDonut extends StatefulWidget {
  final List<Ticket> tickets;

  const _TicketStatusDonut({required this.tickets});

  @override
  State<_TicketStatusDonut> createState() => _TicketStatusDonutState();
}

class _TicketStatusDonutState extends State<_TicketStatusDonut> {
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final counts = [
      widget.tickets.where((t) => t.status == TicketStatus.open).length,
      widget.tickets.where((t) => t.status == TicketStatus.inProgress).length,
      widget.tickets.where((t) => t.status == TicketStatus.resolved).length,
      widget.tickets.where((t) => t.status == TicketStatus.closed).length,
    ];
    final labels = ['Open', 'In Progress', 'Resolved', 'Closed'];
    final colors = [
      AppColors.chartColors[3], // amber (open)
      AppColors.chartColors[4], // blue (in progress)
      AppColors.chartColors[2], // green (resolved)
      AppColors.chartColors[1], // cyan (closed)
    ];
    final total = counts.fold(0, (a, b) => a + b);

    return _ChartCard(
      title: 'Ticket Status',
      subtitle: 'Distribution overview',
      child: Column(
        children: [
          SizedBox(
            height: 160,
            child: total == 0
                ? Center(
                    child: Text(
                      'No tickets yet',
                      style: TextStyle(
                          color: cs.onSurface.withValues(alpha: 0.4)),
                    ),
                  )
                : PieChart(
                    PieChartData(
                      sectionsSpace: 3,
                      centerSpaceRadius: 44,
                      pieTouchData: PieTouchData(
                        touchCallback: (_, response) {
                          setState(() {
                            _touchedIndex =
                                response?.touchedSection?.touchedSectionIndex ??
                                    -1;
                          });
                        },
                      ),
                      sections: List.generate(4, (i) {
                        final touched = _touchedIndex == i;
                        return PieChartSectionData(
                          value: counts[i].toDouble(),
                          color: colors[i],
                          radius: touched ? 52 : 44,
                          showTitle: false,
                        );
                      }),
                    ),
                  ),
          ),
          const SizedBox(height: 16),
          ...List.generate(
            4,
            (i) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration:
                        BoxDecoration(color: colors[i], shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child:
                        Text(labels[i], style: const TextStyle(fontSize: 12)),
                  ),
                  Text(
                    counts[i].toString(),
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms);
  }
}

// ─────────────────────────────────────────────────────────────
// PRIORITY BAR CHART
// ─────────────────────────────────────────────────────────────

class _PriorityBarChart extends StatelessWidget {
  final List<Ticket> tickets;

  const _PriorityBarChart({required this.tickets});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final data = <double>[
      tickets.where((t) => t.priority == TicketPriority.low).length.toDouble(),
      tickets
          .where((t) => t.priority == TicketPriority.medium)
          .length
          .toDouble(),
      tickets.where((t) => t.priority == TicketPriority.high).length.toDouble(),
      tickets
          .where((t) => t.priority == TicketPriority.urgent)
          .length
          .toDouble(),
    ];

    final maxY = tickets.isEmpty
        ? 8.0
        : (data.reduce((a, b) => a > b ? a : b) + 2.0).clamp(4.0, 20.0);

    const colors = [
      AppColors.success,
      AppColors.info,
      AppColors.warning,
      AppColors.error,
    ];
    const labels = ['Low', 'Med', 'High', 'Urgent'];

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
                color: cs.outline.withValues(alpha: 0.2),
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
                  getTitlesWidget: (v, _) {
                    final idx = v.toInt();
                    if (idx < 0 || idx >= labels.length) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        labels[idx],
                        style: TextStyle(
                          fontSize: 11,
                          color: cs.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    );
                  },
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
                      color: colors[i].withValues(alpha: 0.06),
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

// ─────────────────────────────────────────────────────────────
// RECENT TICKETS LIST
// ─────────────────────────────────────────────────────────────

class _RecentTicketsList extends StatelessWidget {
  final List<Ticket> tickets;

  const _RecentTicketsList({required this.tickets});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
      child: tickets.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'No tickets yet',
                  style: TextStyle(
                    color: cs.onSurface.withValues(alpha: 0.4),
                    fontSize: 13,
                  ),
                ),
              ),
            )
          : Column(
              children: tickets.take(5).map((t) {
                final priorityColor = _priorityColor(t.priority);
                final statusColor = _statusColor(t.status);
                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color:
                        isDark ? AppColors.darkSurface : AppColors.lightSurface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isDark
                          ? AppColors.darkBorder
                          : AppColors.lightBorder,
                    ),
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
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                t.status.displayName,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: statusColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 16,
                        color: cs.onSurface.withValues(alpha: 0.3),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
    ).animate().fadeIn(delay: 350.ms);
  }

  Color _priorityColor(TicketPriority p) {
    switch (p) {
      case TicketPriority.low:
        return AppColors.success;
      case TicketPriority.medium:
        return AppColors.info;
      case TicketPriority.high:
        return AppColors.warning;
      case TicketPriority.urgent:
        return AppColors.error;
    }
  }

  Color _statusColor(TicketStatus s) {
    switch (s) {
      case TicketStatus.open:
        return AppColors.warning;
      case TicketStatus.inProgress:
        return AppColors.info;
      case TicketStatus.resolved:
        return AppColors.success;
      case TicketStatus.closed:
        return AppColors.lightTextSecondary;
    }
  }
}

// ─────────────────────────────────────────────────────────────
// PERFORMANCE METRICS
// ─────────────────────────────────────────────────────────────

class _PerformanceSection extends StatelessWidget {
  final List<Ticket> tickets;

  const _PerformanceSection({required this.tickets});

  @override
  Widget build(BuildContext context) {
    final total = tickets.length;

    final List<_MetricData> metrics;
    if (total == 0) {
      metrics = const [
        _MetricData('Resolution Rate', 0.0, AppColors.success),
        _MetricData('In Progress', 0.0, AppColors.info),
        _MetricData('SLA Compliance', 0.0, AppColors.primary),
      ];
    } else {
      final resolved =
          tickets.where((t) => t.status == TicketStatus.resolved).length;
      final inProgress =
          tickets.where((t) => t.status == TicketStatus.inProgress).length;
      final nonUrgent =
          tickets.where((t) => t.priority != TicketPriority.urgent).length;
      metrics = [
        _MetricData('Resolution Rate', resolved / total, AppColors.success),
        _MetricData('In Progress', inProgress / total, AppColors.info),
        _MetricData('SLA Compliance', nonUrgent / total, AppColors.primary),
      ];
    }

    return _ChartCard(
      title: 'Performance Metrics',
      subtitle: 'Ticket KPIs at a glance',
      child: Column(
        children: metrics.map((m) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      m.label,
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                    Text(
                      '${(m.value * 100).toInt()}%',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: m.color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                LinearPercentIndicator(
                  lineHeight: 8,
                  percent: m.value.clamp(0.0, 1.0),
                  backgroundColor: m.color.withValues(alpha: 0.1),
                  progressColor: m.color,
                  barRadius: const Radius.circular(4),
                  padding: EdgeInsets.zero,
                  animation: true,
                  animationDuration: 900,
                ),
              ],
            ),
          );
        }).toList(),
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

// ─────────────────────────────────────────────────────────────
// QUICK ACTIONS
// ─────────────────────────────────────────────────────────────

class _QuickActionsSection extends StatelessWidget {
  const _QuickActionsSection();

  static const _actions = [
    (
      label: 'New Flow',
      icon: Icons.account_tree_rounded,
      color: AppColors.primary,
      route: AppRoutes.flows,
    ),
    (
      label: 'New Form',
      icon: Icons.dynamic_form_rounded,
      color: AppColors.accent,
      route: AppRoutes.forms,
    ),
    (
      label: 'Add User',
      icon: Icons.person_add_rounded,
      color: AppColors.success,
      route: AppRoutes.users,
    ),
    (
      label: 'New Ticket',
      icon: Icons.support_agent_rounded,
      color: AppColors.warning,
      route: AppRoutes.tickets,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(builder: (context, constraints) {
          final wide = constraints.maxWidth > 500;
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _actions.asMap().entries.map((e) {
              final idx = e.key;
              final action = e.value;
              final cardWidth = wide
                  ? (constraints.maxWidth - 36) / 4
                  : (constraints.maxWidth - 12) / 2;
              return SizedBox(
                width: cardWidth,
                child: AppCard(
                  onTap: () => context.go(action.route),
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: action.color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child:
                            Icon(action.icon, color: action.color, size: 18),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          action.label,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: cs.onSurface,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 12,
                        color: action.color.withValues(alpha: 0.6),
                      ),
                    ],
                  ),
                ),
              )
                  .animate(delay: (idx * 70).ms)
                  .fadeIn()
                  .slideX(begin: 0.05);
            }).toList(),
          );
        }),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// SHARED CHART CARD
// ─────────────────────────────────────────────────────────────

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

    return AppCard(
      padding: const EdgeInsets.all(20),
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
                  Text(
                    title,
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: cs.onSurface.withValues(alpha: 0.45),
                    ),
                  ),
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

class _ChartLegend extends StatelessWidget {
  final Color color;
  final String label;

  const _ChartLegend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 3,
          decoration:
              BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}

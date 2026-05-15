import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/ticket.dart';
import '../../providers/realtime_provider.dart';
import '../../providers/ticket_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/ios_tab_bar.dart';
import '../../data/ui_text.dart';

class TicketsScreen extends ConsumerStatefulWidget {
  const TicketsScreen({super.key});

  @override
  ConsumerState<TicketsScreen> createState() => _TicketsScreenState();
}

class _TicketsScreenState extends ConsumerState<TicketsScreen> {
  final _searchController = TextEditingController();
  String _search = '';
  int _selectedTabIndex = 0;

  // Sticky tab bar state
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _headerKey = GlobalKey();
  double _headerContentHeight = 400;
  bool _showStickyBar = false;

  static List<String> get _tabs => [
        UiText.all,
        UiText.open,
        UiText.inProgress,
        UiText.resolved,
        UiText.closed
      ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureHeader());
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final shouldShow = _scrollController.offset > _headerContentHeight;
    if (shouldShow != _showStickyBar) {
      setState(() => _showStickyBar = shouldShow);
    }
  }

  void _measureHeader() {
    if (!mounted) return;
    final ctx = _headerKey.currentContext;
    if (ctx == null) return;
    final box = ctx.findRenderObject() as RenderBox?;
    if (box == null) return;
    final h = box.size.height;
    if ((h - _headerContentHeight).abs() > 2) {
      setState(() => _headerContentHeight = h);
    }
  }

  TicketStatus? get _selectedStatus {
    switch (_selectedTabIndex) {
      case 1:
        return TicketStatus.open;
      case 2:
        return TicketStatus.inProgress;
      case 3:
        return TicketStatus.resolved;
      case 4:
        return TicketStatus.closed;
      default:
        return null;
    }
  }

  void _showCreateTicket(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => _CreateTicketDialog(
        onCreate: (data) async {
          await ref.read(ticketNotifierProvider.notifier).create(data);
        },
      ),
    );
  }

  void _selectTab(int index) {
    setState(() => _selectedTabIndex = index);
    // Re-measure after tab change so threshold stays accurate.
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureHeader());
  }

  @override
  Widget build(BuildContext context) {
    final ticketsAsync = ref.watch(ticketNotifierProvider);
    final isMobile = MediaQuery.of(context).size.width < 768;
    // On mobile the shell overrides MediaQuery.padding.top to equal the
    // content start (below the floating bar). On tablet/desktop the body
    // already starts beneath the top bar, so we pin at y=0.
    final stickyTop = isMobile ? MediaQuery.of(context).padding.top : 0.0;

    ref.listen(realtimeStreamProvider, (_, next) {
      next.whenData((msg) {
        final type = msg['type'] as String? ?? '';
        if (type == 'ticket.created' || type == 'ticket.status_updated') {
          ref.invalidate(ticketNotifierProvider);
          WidgetsBinding.instance
              .addPostFrameCallback((_) => _measureHeader());
        }
      });
    });

    return Scaffold(
      body: ticketsAsync.when(
        loading: () => const LoadingList(),
        error: (e, _) => AppErrorWidget(
          message: e.toString(),
          onRetry: () => ref.read(ticketNotifierProvider.notifier).refresh(),
        ),
        data: (tickets) {
          var filtered = tickets;
          final status = _selectedStatus;
          if (status != null) {
            filtered = filtered.where((t) => t.status == status).toList();
          }
          if (_search.isNotEmpty) {
            filtered = filtered
                .where((t) =>
                    t.title.toLowerCase().contains(_search.toLowerCase()) ||
                    (t.description ?? '')
                        .toLowerCase()
                        .contains(_search.toLowerCase()))
                .toList();
          }

          final tabBar = IosTabBar(
            tabs: _tabs,
            selectedIndex: _selectedTabIndex,
            onTabSelected: _selectTab,
          );

          final scrollView = CustomScrollView(
            controller: _scrollController,
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  key: _headerKey,
                  padding: AppPageLayout.contentPadding(
                    context,
                    horizontal: 20,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      AppPageHeader(
                        title: UiText.supportTickets,
                        description: UiText
                            .trackCustomerRequestsPrioritizeUrgentWorkAndKeepEveryResolut,
                        actionLabel: UiText.newTicket,
                        compactActionLabel: UiText.newText,
                        actionIcon: Icons.add,
                        onAction: () => _showCreateTicket(context),
                      ).animate().fadeIn(duration: 300.ms),
                      const SizedBox(height: 14),

                      // Stats row
                      _TicketStatsRow(tickets: tickets),
                      const SizedBox(height: 16),

                      // Charts row
                      LayoutBuilder(builder: (ctx, constraints) {
                        final isWide = constraints.maxWidth > 600;
                        if (isWide) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 5,
                                child: _PriorityBarChart(tickets: tickets),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 4,
                                child: _StatusDonut(tickets: tickets),
                              ),
                            ],
                          );
                        }
                        return Column(
                          children: [
                            _PriorityBarChart(tickets: tickets),
                            const SizedBox(height: 12),
                            _StatusDonut(tickets: tickets),
                          ],
                        );
                      }),
                      const SizedBox(height: 16),

                      // Search
                      SearchField(
                        controller: _searchController,
                        hintText: UiText.searchTickets,
                        onChanged: (v) => setState(() => _search = v),
                      ),
                      const SizedBox(height: 4),
                    ],
                  ),
                ),
              ),

              // Inline tab bar (scrolls normally; hidden by sticky overlay when pinned)
              SliverToBoxAdapter(child: tabBar),

              if (filtered.isEmpty)
                SliverFillRemaining(
                  child: EmptyState(
                    title: UiText.noTicketsFound,
                    subtitle: UiText.tryAdjustingYourFilters,
                    icon: Icons.support_agent_outlined,
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) => Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                      child: _TicketCard(
                        ticket: filtered[i],
                        index: i,
                        onTap: () => context.push('/tickets/${filtered[i].id}'),
                        onUpdateStatus: (s) async {
                          await ref
                              .read(ticketNotifierProvider.notifier)
                              .updateStatus(filtered[i].id, s);
                        },
                      ),
                    ),
                    childCount: filtered.length,
                  ),
                ),
              const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
            ],
          );

          return Stack(
            children: [
              scrollView,

              // Sticky tab bar overlay — appears once the inline tab bar
              // has scrolled off the top, positioned correctly below the
              // floating mobile bar (or at the very top of the body on
              // tablet/desktop where the body already starts beneath the
              // app bar).
              if (_showStickyBar)
                Positioned(
                  top: stickyTop,
                  left: 0,
                  right: 0,
                  child: IosTabBar(
                    tabs: _tabs,
                    selectedIndex: _selectedTabIndex,
                    onTabSelected: _selectTab,
                    isOverlay: true,
                  )
                      .animate()
                      .slideY(
                        begin: -0.6,
                        end: 0,
                        duration: 220.ms,
                        curve: Curves.easeOutCubic,
                      )
                      .fadeIn(duration: 180.ms),
                ),
            ],
          );
        },
      ),
    );
  }
}

// ── Stats Row ──────────────────────────────────────────────────────

class _TicketStatsRow extends StatelessWidget {
  final List<Ticket> tickets;

  const _TicketStatsRow({required this.tickets});

  @override
  Widget build(BuildContext context) {
    final total = tickets.length;
    final open = tickets.where((t) => t.status == TicketStatus.open).length;
    final inProgress =
        tickets.where((t) => t.status == TicketStatus.inProgress).length;
    final resolved =
        tickets.where((t) => t.status == TicketStatus.resolved).length;

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
            icon: Icons.confirmation_number_rounded,
            value: '$total',
            label: UiText.total,
            color: AppColors.primary,
          ),
          AppStatCard(
            icon: Icons.inbox_rounded,
            value: '$open',
            label: UiText.open,
            color: AppColors.warning,
          ),
          AppStatCard(
            icon: Icons.sync_rounded,
            value: '$inProgress',
            label: UiText.inProgress,
            color: AppColors.info,
          ),
          AppStatCard(
            icon: Icons.check_circle_rounded,
            value: '$resolved',
            label: UiText.resolved,
            color: AppColors.success,
          ),
        ],
      );
    });
  }
}

// ── Priority Bar Chart ─────────────────────────────────────────────

class _PriorityBarChart extends StatelessWidget {
  final List<Ticket> tickets;

  const _PriorityBarChart({required this.tickets});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final data = [
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
    final maxY = (data.reduce((a, b) => a > b ? a : b) + 2).clamp(4.0, 20.0);
    final colors = [
      AppColors.chartColors[2], // green
      AppColors.chartColors[4], // blue
      AppColors.chartColors[3], // amber
      AppColors.chartColors[5], // red
    ];
    final labels = [
      UiText.low,
      UiText.med,
      UiText.high,
      UiText.urgent
    ];

    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(UiText.priorityBreakdown,
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700)),
          Text(UiText.ticketsByPriorityLevel,
              style: TextStyle(
                  fontSize: 11, color: cs.onSurface.withValues(alpha: 0.45))),
          const SizedBox(height: 16),
          SizedBox(
            height: 140,
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
                  leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) => Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          labels[v.toInt()],
                          style: TextStyle(
                              fontSize: 11,
                              color: cs.onSurface.withValues(alpha: 0.5)),
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
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(6)),
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
        ],
      ),
    );
  }
}

// ── Status Donut ───────────────────────────────────────────────────

class _StatusDonut extends StatefulWidget {
  final List<Ticket> tickets;

  const _StatusDonut({required this.tickets});

  @override
  State<_StatusDonut> createState() => _StatusDonutState();
}

class _StatusDonutState extends State<_StatusDonut> {
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final open =
        widget.tickets.where((t) => t.status == TicketStatus.open).length;
    final inProgress =
        widget.tickets.where((t) => t.status == TicketStatus.inProgress).length;
    final resolved =
        widget.tickets.where((t) => t.status == TicketStatus.resolved).length;
    final closed =
        widget.tickets.where((t) => t.status == TicketStatus.closed).length;
    final data = [open, inProgress, resolved, closed];
    final total = data.fold(0, (a, b) => a + b);

    final labels = [
      UiText.open,
      UiText.inProgress,
      UiText.resolved,
      UiText.closed
    ];
    final colors = [
      AppColors.chartColors[3], // amber (open)
      AppColors.chartColors[4], // blue (in progress)
      AppColors.chartColors[2], // green (resolved)
      AppColors.chartColors[1], // cyan (closed)
    ];

    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(UiText.statusDistribution,
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700)),
          Text(UiText.currentTicketStates,
              style: TextStyle(
                  fontSize: 11, color: cs.onSurface.withValues(alpha: 0.45))),
          const SizedBox(height: 16),
          Row(
            children: [
              SizedBox(
                width: 100,
                height: 100,
                child: total == 0
                    ? Center(
                        child: Text(UiText.noData,
                            style: TextStyle(
                                fontSize: 11,
                                color: cs.onSurface.withValues(alpha: 0.4))))
                    : PieChart(
                        PieChartData(
                          sectionsSpace: 2,
                          centerSpaceRadius: 28,
                          pieTouchData: PieTouchData(
                            touchCallback: (event, response) {
                              setState(() {
                                _touchedIndex = response
                                        ?.touchedSection?.touchedSectionIndex ??
                                    -1;
                              });
                            },
                          ),
                          sections: List.generate(4, (i) {
                            final isTouched = _touchedIndex == i;
                            return PieChartSectionData(
                              value: data[i].toDouble(),
                              color: colors[i],
                              radius: isTouched ? 36 : 28,
                              showTitle: false,
                            );
                          }),
                        ),
                      ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: List.generate(
                      4,
                      (i) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 3),
                            child: Row(
                              children: [
                                Container(
                                  width: 9,
                                  height: 9,
                                  decoration: BoxDecoration(
                                    color: colors[i],
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                    child: Text(labels[i],
                                        style: const TextStyle(fontSize: 11))),
                                Text(
                                  data[i].toString(),
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: colors[i]),
                                ),
                              ],
                            ),
                          )),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Ticket Card ────────────────────────────────────────────────────

class _TicketCard extends StatelessWidget {
  final Ticket ticket;
  final int index;
  final VoidCallback onTap;
  final ValueChanged<TicketStatus> onUpdateStatus;

  const _TicketCard({
    required this.ticket,
    required this.index,
    required this.onTap,
    required this.onUpdateStatus,
  });

  Color _priorityColor() {
    switch (ticket.priority) {
      case TicketPriority.urgent:
        return AppColors.error;
      case TicketPriority.high:
        return AppColors.warning;
      case TicketPriority.medium:
        return AppColors.info;
      case TicketPriority.low:
        return AppColors.success;
    }
  }

  Color _statusColor() {
    switch (ticket.status) {
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

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final priorityColor = _priorityColor();
    final statusColor = _statusColor();
    final hasDescription =
        ticket.description != null && ticket.description!.trim().isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: ticket.isRead
                ? cs.outline.withValues(alpha: 0.4)
                : priorityColor.withValues(alpha: 0.35),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Priority accent bar
              Container(
                width: 5,
                decoration: BoxDecoration(
                  color: priorityColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                  ),
                ),
              ),

              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          // Unread dot
                          if (!ticket.isRead)
                            Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsetsDirectional.only(end: 8),
                              decoration: BoxDecoration(
                                color: priorityColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                          Expanded(
                            child: Text(
                              ticket.title,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(
                                    fontWeight: ticket.isRead
                                        ? FontWeight.w500
                                        : FontWeight.w700,
                                  ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          GlassContextMenuButton<TicketStatus>(
                            icon: Icon(Icons.more_vert,
                                size: 18,
                                color: cs.onSurface.withValues(alpha: 0.4)),
                            itemBuilder: (_) => TicketStatus.values
                                .map<GlassContextMenuEntry<TicketStatus>>((s) => GlassContextMenuItem(
                                      value: s,
                                      child: Text(s.displayName),
                                    ))
                                .toList(),
                            onSelected: onUpdateStatus,
                          ),
                        ],
                      ),

                      if (hasDescription) ...[
                        const SizedBox(height: 4),
                        Text(
                          ticket.description!,
                          style: TextStyle(
                            fontSize: 12,
                            color: cs.onSurface.withValues(alpha: 0.55),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],

                      const SizedBox(height: 10),

                      // Tags
                      if (ticket.tags.isNotEmpty) ...[
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: ticket.tags.map((tag) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: cs.outline.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Text(
                                tag,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: cs.onSurface.withValues(alpha: 0.55),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 10),
                      ],

                      // Footer row
                      Row(
                        children: [
                          // Status badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              ticket.status.displayName,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: statusColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          // Priority badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: priorityColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              ticket.priority.displayName,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: priorityColor,
                              ),
                            ),
                          ),
                          const Spacer(),

                          // Assignee
                          if (ticket.assigneeName != null) ...[
                            Icon(Icons.person_outline,
                                size: 12,
                                color: cs.onSurface.withValues(alpha: 0.4)),
                            const SizedBox(width: 3),
                            Text(
                              ticket.assigneeName!,
                              style: TextStyle(
                                fontSize: 11,
                                color: cs.onSurface.withValues(alpha: 0.5),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],

                          // Message count
                          if (ticket.messageCount > 0) ...[
                            Icon(Icons.chat_bubble_outline,
                                size: 12,
                                color: cs.onSurface.withValues(alpha: 0.4)),
                            const SizedBox(width: 3),
                            Text(
                              ticket.messageCount.toString(),
                              style: TextStyle(
                                fontSize: 11,
                                color: cs.onSurface.withValues(alpha: 0.5),
                              ),
                            ),
                          ],

                          // Due date
                          if (ticket.dueDate != null) ...[
                            const SizedBox(width: 8),
                            Icon(Icons.schedule_rounded,
                                size: 12,
                                color: _isOverdue(ticket.dueDate!)
                                    ? AppColors.error
                                    : cs.onSurface.withValues(alpha: 0.4)),
                            const SizedBox(width: 3),
                            Text(
                              _formatDue(ticket.dueDate!),
                              style: TextStyle(
                                fontSize: 11,
                                color: _isOverdue(ticket.dueDate!)
                                    ? AppColors.error
                                    : cs.onSurface.withValues(alpha: 0.5),
                                fontWeight: _isOverdue(ticket.dueDate!)
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: index * 40))
        .slideY(begin: 0.04, curve: Curves.easeOut);
  }

  bool _isOverdue(DateTime due) =>
      due.isBefore(DateTime.now()) &&
      ticket.status != TicketStatus.resolved &&
      ticket.status != TicketStatus.closed;

  String _formatDue(DateTime due) {
    final diff = due.difference(DateTime.now());
    if (diff.inDays > 0) return UiText.dueInDays(diff.inDays);
    if (diff.inDays < 0) return UiText.daysOverdue(-diff.inDays);
    return UiText.dueToday;
  }
}

// ── Create Ticket Dialog ───────────────────────────────────────────

class _CreateTicketDialog extends StatefulWidget {
  final Future<void> Function(Map<String, dynamic>) onCreate;

  const _CreateTicketDialog({required this.onCreate});

  @override
  State<_CreateTicketDialog> createState() => _CreateTicketDialogState();
}

class _CreateTicketDialogState extends State<_CreateTicketDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  TicketPriority _priority = TicketPriority.medium;
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    return GlassAlertDialog(
      title: Text(UiText.newTicket),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleController,
                decoration:
                    InputDecoration(labelText: UiText.titleRequired),
                validator: (v) =>
                    v?.isEmpty ?? true ? UiText.titleIsRequired : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descController,
                decoration: InputDecoration(labelText: UiText.description),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<TicketPriority>(
                value: _priority,
                items: TicketPriority.values
                    .map((p) =>
                        DropdownMenuItem(value: p, child: Text(p.displayName)))
                    .toList(),
                onChanged: (v) => setState(() => _priority = v!),
                decoration: InputDecoration(labelText: UiText.priority),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(UiText.cancel),
        ),
        AppButton(
          label: UiText.create,
          loading: _saving,
          onPressed: () async {
            if (!_formKey.currentState!.validate()) return;
            setState(() => _saving = true);
            try {
              await widget.onCreate({
                'title': _titleController.text,
                'description': _descController.text,
                'priority': _priority.name,
                'status': TicketStatus.open.name,
              });
              if (context.mounted) Navigator.pop(context);
            } finally {
              if (mounted) setState(() => _saving = false);
            }
          },
        ),
      ],
    );
  }
}

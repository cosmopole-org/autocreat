import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart' hide Flow;
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/flow.dart';
import '../../providers/flow_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common_widgets.dart';

class FlowsScreen extends ConsumerStatefulWidget {
  const FlowsScreen({super.key});

  @override
  ConsumerState<FlowsScreen> createState() => _FlowsScreenState();
}

class _FlowsScreenState extends ConsumerState<FlowsScreen> {
  final _searchController = TextEditingController();
  String _search = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _createFlow(BuildContext context) async {
    final repo = ref.read(flowRepositoryProvider);
    final flow = await repo.createFlow({
      'name': 'New Flow',
      'status': 'draft',
      'nodes': [
        {
          'id': 'start_1',
          'label': 'Start',
          'type': 'start',
          'x': 100.0,
          'y': 200.0,
          'width': 160.0,
          'height': 60.0,
        },
        {
          'id': 'end_1',
          'label': 'End',
          'type': 'end',
          'x': 400.0,
          'y': 200.0,
          'width': 160.0,
          'height': 60.0,
        },
      ],
      'edges': [],
    });
    if (context.mounted) {
      context.go('/flows/${flow.id}/edit');
    }
  }

  @override
  Widget build(BuildContext context) {
    final flowsAsync = ref.watch(flowsProvider(null));

    return Scaffold(
      body: flowsAsync.when(
        loading: () => const LoadingGrid(),
        error: (e, _) => AppErrorWidget(
          message: e.toString(),
          onRetry: () => ref.invalidate(flowsProvider),
        ),
        data: (flows) => _buildContent(context, flows),
      ),
    );
  }

  Widget _buildContent(BuildContext context, List<Flow> flows) {
    final filtered = _search.isEmpty
        ? flows
        : flows
            .where(
                (f) => f.name.toLowerCase().contains(_search.toLowerCase()))
            .toList();

    final active = flows.where((f) => f.status == 'active').length;
    final draft = flows.where((f) => f.status == 'draft').length;
    final totalNodes = flows.fold<int>(0, (s, f) => s + f.nodes.length);
    final totalEdges = flows.fold<int>(0, (s, f) => s + f.edges.length);

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: AppPageLayout.contentPadding(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isNarrow = constraints.maxWidth < 500;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Automation Flows',
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall
                                        ?.copyWith(
                                            fontWeight:
                                                FontWeight.w800),
                                  ),
                                  if (!isNarrow)
                                    Text(
                                      'Design and manage organizational process flows',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall,
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            AppButton(
                              label: isNarrow ? 'New' : 'New Flow',
                              icon: Icons.add,
                              onPressed: () => _createFlow(context),
                            ),
                          ],
                        ),
                        if (isNarrow) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Design and manage organizational process flows',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ],
                    );
                  },
                ).animate().fadeIn(duration: 300.ms),
                const SizedBox(height: 20),

                // Stats
                _FlowStatsRow(
                  total: flows.length,
                  active: active,
                  draft: draft,
                  totalNodes: totalNodes,
                ).animate().fadeIn(delay: 100.ms),
                const SizedBox(height: 20),

                // Nodes distribution chart
                if (flows.isNotEmpty)
                  _FlowsChart(flows: flows, totalEdges: totalEdges)
                      .animate()
                      .fadeIn(delay: 200.ms),
                if (flows.isNotEmpty) const SizedBox(height: 20),

                // Search
                SearchField(
                  controller: _searchController,
                  hintText: 'Search flows...',
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
              title: 'No flows yet',
              subtitle: 'Create your first organizational flow',
              icon: Icons.account_tree_outlined,
              actionLabel: 'Create Flow',
              onAction: () => _createFlow(context),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 360,
                mainAxisExtent: 226,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, i) => _FlowCard(
                  flow: filtered[i],
                  onEdit: () => context.go('/flows/${filtered[i].id}/edit'),
                  onDelete: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (_) => const ConfirmDialog(
                        title: 'Delete Flow',
                        message: 'This will delete the flow permanently.',
                      ),
                    );
                    if (confirmed == true) {
                      await ref
                          .read(flowRepositoryProvider)
                          .deleteFlow(filtered[i].id);
                      ref.invalidate(flowsProvider);
                    }
                  },
                ).animate().fadeIn(delay: Duration(milliseconds: 60 + i * 50)),
                childCount: filtered.length,
              ),
            ),
          ),
      ],
    );
  }
}

// ── Stats Row ──────────────────────────────────────────────────

class _FlowStatsRow extends StatelessWidget {
  final int total;
  final int active;
  final int draft;
  final int totalNodes;

  const _FlowStatsRow({
    required this.total,
    required this.active,
    required this.draft,
    required this.totalNodes,
  });

  @override
  Widget build(BuildContext context) {
    final stats = [
      (Icons.account_tree_rounded, 'Total Flows', total.toString(), AppColors.primary),
      (Icons.play_circle_rounded, 'Active', active.toString(), AppColors.success),
      (Icons.edit_note_rounded, 'Draft', draft.toString(), AppColors.warning),
      (Icons.hub_rounded, 'Total Nodes', totalNodes.toString(), AppColors.accent),
    ];

    return LayoutBuilder(builder: (context, constraints) {
      final isWide = constraints.maxWidth > 700;
      final cards = stats
          .map((s) => AppStatCard(icon: s.$1, label: s.$2, value: s.$3, color: s.$4))
          .toList();
      if (isWide) {
        return Row(
          children: cards.asMap().entries.map((e) => Expanded(
            child: Padding(
              padding: EdgeInsets.only(left: e.key == 0 ? 0 : 12),
              child: e.value,
            ),
          )).toList(),
        );
      }
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(children: [
            Expanded(child: cards[0]),
            const SizedBox(width: 12),
            Expanded(child: cards[1]),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: cards[2]),
            const SizedBox(width: 12),
            Expanded(child: cards[3]),
          ]),
        ],
      );
    });
  }
}

// ── Flow Nodes Chart ───────────────────────────────────────────

class _FlowsChart extends StatelessWidget {
  final List<Flow> flows;
  final int totalEdges;

  const _FlowsChart({required this.flows, required this.totalEdges});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final maxY = flows
            .map((f) => f.nodes.length.toDouble())
            .fold<double>(0, (a, b) => a > b ? a : b) +
        2;

    final colors = AppColors.chartColors;

    // Node type breakdown
    final typeMap = <String, int>{};
    for (final f in flows) {
      for (final n in f.nodes) {
        final t = n.type.name;
        typeMap[t] = (typeMap[t] ?? 0) + 1;
      }
    }

    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Flow Complexity',
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  Text('Nodes and edges per flow',
                      style: TextStyle(
                          fontSize: 11,
                          color: cs.onSurface.withValues(alpha: 0.45))),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.timeline_rounded,
                        size: 12, color: AppColors.accent),
                    const SizedBox(width: 4),
                    Text(
                      '$totalEdges edges total',
                      style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.accent,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          LayoutBuilder(builder: (context, constraints) {
            final isWide = constraints.maxWidth > 500;
            return isWide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: SizedBox(
                          height: 140,
                          child: _buildBarChart(flows, colors, cs, maxY),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        flex: 2,
                        child: _buildNodeTypeBreakdown(typeMap, cs),
                      ),
                    ],
                  )
                : Column(
                    children: [
                      SizedBox(
                        height: 130,
                        child: _buildBarChart(flows, colors, cs, maxY),
                      ),
                      const SizedBox(height: 12),
                      _buildNodeTypeBreakdown(typeMap, cs),
                    ],
                  );
          }),
        ],
      ),
    );
  }

  Widget _buildBarChart(
      List<Flow> flows, List<Color> colors, ColorScheme cs, double maxY) {
    return BarChart(
      BarChartData(
        maxY: maxY.clamp(4.0, 20.0),
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
                if (idx >= flows.length) return const SizedBox();
                final name = flows[idx].name;
                final short = name.length > 10
                    ? '${name.substring(0, 9)}…'
                    : name;
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(short,
                      style: TextStyle(
                          fontSize: 9,
                          color: cs.onSurface.withValues(alpha: 0.5))),
                );
              },
            ),
          ),
        ),
        barGroups: flows.asMap().entries.map((e) {
          final color = colors[e.key % colors.length];
          return BarChartGroupData(
            x: e.key,
            barRods: [
              BarChartRodData(
                toY: e.value.nodes.length.toDouble(),
                color: color,
                width: 24,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(6)),
                backDrawRodData: BackgroundBarChartRodData(
                  show: true,
                  toY: maxY.clamp(4.0, 20.0),
                  color: color.withValues(alpha: 0.06),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildNodeTypeBreakdown(
      Map<String, int> typeMap, ColorScheme cs) {
    final nodeColors = {
      'start': AppColors.success,
      'end': AppColors.error,
      'step': AppColors.primary,
      'decision': AppColors.warning,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Node Types',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: cs.onSurface.withValues(alpha: 0.7))),
        const SizedBox(height: 8),
        ...typeMap.entries.map((e) {
          final color =
              nodeColors[e.key] ?? AppColors.lightTextSecondary;
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration:
                      BoxDecoration(color: color, shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(e.key,
                      style: const TextStyle(fontSize: 11),
                      overflow: TextOverflow.ellipsis),
                ),
                Text('${e.value}',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: color)),
              ],
            ),
          );
        }),
      ],
    );
  }
}

// ── Flow Card ──────────────────────────────────────────────────

class _FlowCard extends StatelessWidget {
  final Flow flow;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _FlowCard({
    required this.flow,
    required this.onEdit,
    required this.onDelete,
  });

  Color get _statusColor {
    switch (flow.status) {
      case 'active':
        return AppColors.success;
      case 'draft':
        return AppColors.warning;
      default:
        return AppColors.lightTextSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final steps = flow.nodes.where((n) => n.type == NodeType.step).length;
    final decisions = flow.nodes.where((n) => n.type == NodeType.decision).length;

    return AppCard(
      onTap: onEdit,
      padding: const EdgeInsets.all(18),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.account_tree_rounded,
                      color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    flow.status.toUpperCase(),
                    style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: _statusColor,
                        letterSpacing: 0.5),
                  ),
                ),
                const Spacer(),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert,
                      size: 18, color: cs.onSurface.withValues(alpha: 0.5)),
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                        value: 'edit', child: Text('Open Editor')),
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

            const SizedBox(height: 12),

            Text(
              flow.name,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),

            if (flow.description != null) ...[
              const SizedBox(height: 4),
              Text(
                flow.description!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.55),
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],

            const Spacer(),

            // Flow stats chips
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _FlowChip(
                  icon: Icons.hub_rounded,
                  label: '${flow.nodes.length} nodes',
                  color: AppColors.primary,
                ),
                _FlowChip(
                  icon: Icons.timeline_rounded,
                  label: '${flow.edges.length} edges',
                  color: AppColors.accent,
                ),
                if (steps > 0)
                  _FlowChip(
                    icon: Icons.task_alt_rounded,
                    label: '$steps steps',
                    color: AppColors.success,
                  ),
                if (decisions > 0)
                  _FlowChip(
                    icon: Icons.call_split_rounded,
                    label: '$decisions decisions',
                    color: AppColors.warning,
                  ),
              ],
            ),

            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(Icons.edit_outlined,
                    size: 14, color: cs.onSurface.withValues(alpha: 0.3)),
              ],
            ),
          ],
        ),
    );
  }
}

class _FlowChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _FlowChip({
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

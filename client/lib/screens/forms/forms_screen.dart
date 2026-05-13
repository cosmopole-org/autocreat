import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/form_definition.dart';
import '../../providers/form_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common_widgets.dart';

class FormsScreen extends ConsumerStatefulWidget {
  const FormsScreen({super.key});

  @override
  ConsumerState<FormsScreen> createState() => _FormsScreenState();
}

class _FormsScreenState extends ConsumerState<FormsScreen> {
  final _searchController = TextEditingController();
  String _search = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _createForm(BuildContext context) async {
    final repo = ref.read(formRepositoryProvider);
    final form = await repo.createForm({
      'name': 'New Form',
      'status': 'draft',
      'fields': [],
    });
    if (context.mounted) {
      context.go('/forms/${form.id}/edit');
    }
  }

  @override
  Widget build(BuildContext context) {
    final formsAsync = ref.watch(formsProvider(null));

    return Scaffold(
      body: formsAsync.when(
        loading: () => const LoadingGrid(),
        error: (e, _) => AppErrorWidget(
          message: e.toString(),
          onRetry: () => ref.invalidate(formsProvider),
        ),
        data: (forms) => _buildContent(context, forms),
      ),
    );
  }

  Widget _buildContent(BuildContext context, List<FormDefinition> forms) {
    final filtered = _search.isEmpty
        ? forms
        : forms
            .where(
                (f) => f.name.toLowerCase().contains(_search.toLowerCase()))
            .toList();

    final active = forms.where((f) => f.status == 'active').length;
    final draft = forms.where((f) => f.status == 'draft').length;
    final totalFields = forms.fold<int>(0, (s, f) => s + f.fields.length);

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
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
                            'Form Definitions',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          Text(
                            'Build and manage data collection forms',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    AppButton(
                      label: 'New Form',
                      icon: Icons.add,
                      onPressed: () => _createForm(context),
                    ),
                  ],
                ).animate().fadeIn(duration: 300.ms),
                const SizedBox(height: 20),

                // Stats
                _FormsStatsRow(
                  total: forms.length,
                  active: active,
                  draft: draft,
                  totalFields: totalFields,
                ).animate().fadeIn(delay: 100.ms),
                const SizedBox(height: 20),

                // Field type chart
                if (forms.isNotEmpty)
                  _FieldTypeChart(forms: forms).animate().fadeIn(delay: 200.ms),
                if (forms.isNotEmpty) const SizedBox(height: 20),

                // Search
                SearchField(
                  controller: _searchController,
                  hintText: 'Search forms...',
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
              title: 'No forms yet',
              subtitle: 'Create your first form definition',
              icon: Icons.dynamic_form_outlined,
              actionLabel: 'Create Form',
              onAction: () => _createForm(context),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 360,
                mainAxisExtent: 200,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, i) => _FormCard(
                  form: filtered[i],
                  onEdit: () => context.go('/forms/${filtered[i].id}/edit'),
                  onDelete: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (_) => const ConfirmDialog(
                        title: 'Delete Form',
                        message: 'This will delete the form permanently.',
                      ),
                    );
                    if (confirmed == true) {
                      await ref
                          .read(formRepositoryProvider)
                          .deleteForm(filtered[i].id);
                      ref.invalidate(formsProvider);
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

class _FormsStatsRow extends StatelessWidget {
  final int total;
  final int active;
  final int draft;
  final int totalFields;

  const _FormsStatsRow({
    required this.total,
    required this.active,
    required this.draft,
    required this.totalFields,
  });

  @override
  Widget build(BuildContext context) {
    final stats = [
      (Icons.dynamic_form_rounded, 'Total Forms', total.toString(), AppColors.accent),
      (Icons.check_circle_rounded, 'Active', active.toString(), AppColors.success),
      (Icons.edit_note_rounded, 'Draft', draft.toString(), AppColors.warning),
      (Icons.list_alt_rounded, 'Total Fields', totalFields.toString(), AppColors.primary),
    ];

    return LayoutBuilder(builder: (context, constraints) {
      final isWide = constraints.maxWidth > 700;
      final cards = stats
          .map((s) => _StatCard(icon: s.$1, label: s.$2, value: s.$3, color: s.$4))
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

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outline.withOpacity(0.4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
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
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: color,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: cs.onSurface.withOpacity(0.55),
                  ),
                  maxLines: 1,
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

// ── Field Type Chart ───────────────────────────────────────────

class _FieldTypeChart extends StatelessWidget {
  final List<FormDefinition> forms;

  const _FieldTypeChart({required this.forms});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final typeMap = <String, int>{};
    for (final form in forms) {
      for (final field in form.fields) {
        final t = field.type.name;
        typeMap[t] = (typeMap[t] ?? 0) + 1;
      }
    }

    final entries = typeMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = entries.take(6).toList();

    final colors = [
      AppColors.primary,
      AppColors.accent,
      AppColors.success,
      AppColors.warning,
      AppColors.info,
      AppColors.error,
    ];

    final maxVal = top.isEmpty ? 1.0 : top.first.value.toDouble();

    return Container(
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
        children: [
          Text('Field Types Distribution',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700)),
          Text('Count of each field type across all forms',
              style: TextStyle(
                  fontSize: 11, color: cs.onSurface.withOpacity(0.45))),
          const SizedBox(height: 16),
          if (top.isEmpty)
            Center(
              child: Text('No fields defined',
                  style:
                      TextStyle(color: cs.onSurface.withOpacity(0.4))),
            )
          else
            SizedBox(
              height: 160,
              child: BarChart(
                BarChartData(
                  maxY: maxVal + 1,
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
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              top[idx].key,
                              style: TextStyle(
                                  fontSize: 10,
                                  color: cs.onSurface.withOpacity(0.5)),
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
                          toY: e.value.value.toDouble(),
                          color: color,
                          width: 26,
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(6)),
                          backDrawRodData: BackgroundBarChartRodData(
                            show: true,
                            toY: maxVal + 1,
                            color: color.withOpacity(0.06),
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

// ── Form Card ──────────────────────────────────────────────────

class _FormCard extends StatelessWidget {
  final FormDefinition form;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _FormCard({
    required this.form,
    required this.onEdit,
    required this.onDelete,
  });

  Color get _statusColor {
    switch (form.status) {
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onEdit,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.outline.withOpacity(0.4)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.dynamic_form_rounded,
                      color: AppColors.accent, size: 20),
                ),
                const SizedBox(width: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    form.status.toUpperCase(),
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
                      size: 18, color: cs.onSurface.withOpacity(0.5)),
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
              form.name,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),

            if (form.description != null) ...[
              const SizedBox(height: 4),
              Text(
                form.description!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: cs.onSurface.withOpacity(0.55),
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],

            const Spacer(),

            // Field type mini tags
            if (form.fields.isNotEmpty) ...[
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: form.fields
                    .take(3)
                    .map((f) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: cs.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            f.type.name,
                            style: TextStyle(
                                fontSize: 9,
                                color: cs.onSurface.withOpacity(0.6)),
                          ),
                        ))
                    .toList()
                  ..addAll(form.fields.length > 3
                      ? [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primarySurface,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '+${form.fields.length - 3}',
                              style: const TextStyle(
                                  fontSize: 9, color: AppColors.primary),
                            ),
                          )
                        ]
                      : []),
              ),
              const SizedBox(height: 8),
            ],

            Row(
              children: [
                Icon(Icons.list_alt_rounded,
                    size: 13, color: cs.onSurface.withOpacity(0.4)),
                const SizedBox(width: 4),
                Text(
                  '${form.fields.length} fields',
                  style: TextStyle(
                      fontSize: 11, color: cs.onSurface.withOpacity(0.55)),
                ),
                const Spacer(),
                Icon(Icons.edit_outlined,
                    size: 14, color: cs.onSurface.withOpacity(0.3)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

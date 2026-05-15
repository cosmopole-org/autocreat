import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/form_definition.dart';
import '../../providers/form_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common_widgets.dart';
import '../../data/ui_text.dart';

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
      'name': UiText.newForm,
      'status': 'draft',
      'fields': [],
    });
    if (context.mounted) {
      context.push('/forms/${form.id}/edit');
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
            .where((f) => f.name.toLowerCase().contains(_search.toLowerCase()))
            .toList();

    final active = forms.where((f) => f.status == 'active').length;
    final draft = forms.where((f) => f.status == 'draft').length;
    final totalFields = forms.fold<int>(0, (s, f) => s + f.fields.length);

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: AppPageLayout.contentPadding(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                AppPageHeader(
                  title: UiText.formDefinitions,
                  description: UiText
                      .buildStructuredFormsThatCaptureReliableDataGuideUsersBeautif,
                  actionLabel: UiText.newForm,
                  compactActionLabel: UiText.newText,
                  actionIcon: Icons.add,
                  onAction: () => _createForm(context),
                ).animate().fadeIn(duration: 300.ms),
                const SizedBox(height: 18),

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
                  hintText: UiText.searchForms,
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
              title: UiText.noFormsYet,
              subtitle: UiText.createYourFirstFormDefinition,
              icon: Icons.dynamic_form_outlined,
              actionLabel: UiText.createForm,
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
                  onEdit: () => context.push('/forms/${filtered[i].id}/edit'),
                  onDelete: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (_) => ConfirmDialog(
                        title: UiText.deleteForm,
                        message: UiText.thisWillDeleteTheFormPermanently,
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
      (
        Icons.dynamic_form_rounded,
        UiText.totalForms,
        total.toString(),
        AppColors.accent
      ),
      (
        Icons.check_circle_rounded,
        UiText.active,
        active.toString(),
        AppColors.success
      ),
      (
        Icons.edit_note_rounded,
        UiText.draft,
        draft.toString(),
        AppColors.warning
      ),
      (
        Icons.list_alt_rounded,
        UiText.totalFields,
        totalFields.toString(),
        AppColors.primary
      ),
    ];

    return LayoutBuilder(builder: (context, constraints) {
      final isWide = constraints.maxWidth > 700;
      final cards = stats
          .map((s) =>
              AppStatCard(icon: s.$1, label: s.$2, value: s.$3, color: s.$4))
          .toList();
      if (isWide) {
        return Row(
          children: cards
              .asMap()
              .entries
              .map((e) => Expanded(
                    child: Padding(
                      padding: EdgeInsetsDirectional.only(start: e.key == 0 ? 0 : 12),
                      child: e.value,
                    ),
                  ))
              .toList(),
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

// ── Field Type Chart ───────────────────────────────────────────

class _FieldTypeChart extends StatelessWidget {
  final List<FormDefinition> forms;

  const _FieldTypeChart({required this.forms});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

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

    const colors = AppColors.chartColors;

    final maxVal = top.isEmpty ? 1.0 : top.first.value.toDouble();

    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(UiText.fieldTypesDistribution,
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700)),
          Text(UiText.countOfEachFieldTypeAcrossAllForms,
              style: TextStyle(
                  fontSize: 11, color: cs.onSurface.withValues(alpha: 0.45))),
          const SizedBox(height: 16),
          if (top.isEmpty)
            Center(
              child: Text(UiText.noFieldsDefined,
                  style: TextStyle(color: cs.onSurface.withValues(alpha: 0.4))),
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
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              FormFieldType.values.where((t) => t.name == top[idx].key).isEmpty ? top[idx].key : FormFieldType.values.firstWhere((t) => t.name == top[idx].key).displayName,
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
                          toY: e.value.value.toDouble(),
                          color: color,
                          width: 26,
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(6)),
                          backDrawRodData: BackgroundBarChartRodData(
                            show: true,
                            toY: maxVal + 1,
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
                  color: AppColors.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.dynamic_form_rounded,
                    color: AppColors.accent, size: 20),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  UiText.statusLabel(form.status).toUpperCase(),
                  style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: _statusColor,
                      letterSpacing: 0.5),
                ),
              ),
              const Spacer(),
              GlassContextMenuButton<String>(
                icon: Icon(Icons.more_vert,
                    size: 18, color: cs.onSurface.withValues(alpha: 0.5)),
                itemBuilder: (_) => [
                  GlassContextMenuItem(
                      value: 'edit', child: Text(UiText.openEditor)),
                  GlassContextMenuItem(
                      value: 'delete',
                      child: Text(UiText.delete,
                          style: const TextStyle(color: AppColors.error))),
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
                    color: cs.onSurface.withValues(alpha: 0.55),
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
                          f.type.displayName,
                          style: TextStyle(
                              fontSize: 9,
                              color: cs.onSurface.withValues(alpha: 0.6)),
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
                            UiText.moreCount(form.fields.length - 3),
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
                  size: 13, color: cs.onSurface.withValues(alpha: 0.4)),
              const SizedBox(width: 4),
              Text(
                UiText.fieldCount(form.fields.length),
                style: TextStyle(
                    fontSize: 11, color: cs.onSurface.withValues(alpha: 0.55)),
              ),
              const Spacer(),
              Icon(Icons.edit_outlined,
                  size: 14, color: cs.onSurface.withValues(alpha: 0.3)),
            ],
          ),
        ],
      ),
    );
  }
}

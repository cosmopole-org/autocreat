import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/model_definition.dart';
import '../../providers/model_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common_widgets.dart';

class ModelsScreen extends ConsumerStatefulWidget {
  const ModelsScreen({super.key});

  @override
  ConsumerState<ModelsScreen> createState() => _ModelsScreenState();
}

class _ModelsScreenState extends ConsumerState<ModelsScreen> {
  final _searchController = TextEditingController();
  String _search = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _createModel(BuildContext context) async {
    final repo = ref.read(modelRepositoryProvider);
    final model = await repo.createModel({
      'name': 'New Model',
      'fields': [],
    });
    if (context.mounted) context.go('/models/${model.id}/edit');
  }

  @override
  Widget build(BuildContext context) {
    final modelsAsync = ref.watch(modelsProvider(null));

    return Scaffold(
      body: modelsAsync.when(
        loading: () => const LoadingList(),
        error: (e, _) => AppErrorWidget(
          message: e.toString(),
          onRetry: () => ref.invalidate(modelsProvider),
        ),
        data: (models) => _buildContent(context, models),
      ),
    );
  }

  Widget _buildContent(BuildContext context, List<ModelDefinition> models) {
    final filtered = _search.isEmpty
        ? models
        : models
            .where(
                (m) => m.name.toLowerCase().contains(_search.toLowerCase()))
            .toList();

    final totalFields = models.fold<int>(0, (s, m) => s + m.fields.length);

    // Field type distribution across all models
    final typeMap = <String, int>{};
    for (final m in models) {
      for (final f in m.fields) {
        final t = f.type.displayName;
        typeMap[t] = (typeMap[t] ?? 0) + 1;
      }
    }

    final requiredFields = models.fold<int>(
        0, (s, m) => s + m.fields.where((f) => f.required).length);
    final uniqueFields = models.fold<int>(
        0, (s, m) => s + m.fields.where((f) => f.unique).length);

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: AppPageLayout.contentPadding(context),
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
                            'Data Models',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          Text(
                            'Define entity schemas and data structures',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    AppButton(
                      label: 'New Model',
                      icon: Icons.add,
                      onPressed: () => _createModel(context),
                    ),
                  ],
                ).animate().fadeIn(duration: 300.ms),
                const SizedBox(height: 20),

                // Stats
                _ModelStatsRow(
                  total: models.length,
                  totalFields: totalFields,
                  required: requiredFields,
                  unique: uniqueFields,
                ).animate().fadeIn(delay: 100.ms),
                const SizedBox(height: 20),

                // Field type chart
                if (models.isNotEmpty && typeMap.isNotEmpty)
                  _FieldTypeDonut(typeMap: typeMap)
                      .animate()
                      .fadeIn(delay: 200.ms),
                if (models.isNotEmpty && typeMap.isNotEmpty)
                  const SizedBox(height: 20),

                // Search
                SearchField(
                  controller: _searchController,
                  hintText: 'Search models...',
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
              title: 'No models yet',
              subtitle: 'Define your data structures',
              icon: Icons.data_object_outlined,
              actionLabel: 'Create Model',
              onAction: () => _createModel(context),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _ModelCard(
                    model: filtered[i],
                    onEdit: () =>
                        context.go('/models/${filtered[i].id}/edit'),
                    onDelete: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (_) => const ConfirmDialog(
                          title: 'Delete Model',
                          message: 'Delete this model permanently?',
                        ),
                      );
                      if (confirmed == true) {
                        await ref
                            .read(modelRepositoryProvider)
                            .deleteModel(filtered[i].id);
                        ref.invalidate(modelsProvider);
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

class _ModelStatsRow extends StatelessWidget {
  final int total;
  final int totalFields;
  final int required;
  final int unique;

  const _ModelStatsRow({
    required this.total,
    required this.totalFields,
    required this.required,
    required this.unique,
  });

  @override
  Widget build(BuildContext context) {
    final stats = [
      (Icons.data_object_rounded, 'Total Models', total.toString(), AppColors.info),
      (Icons.list_alt_rounded, 'Total Fields', totalFields.toString(), AppColors.primary),
      (Icons.star_rounded, 'Required Fields', required.toString(), AppColors.warning),
      (Icons.fingerprint_rounded, 'Unique Fields', unique.toString(), AppColors.success),
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

// ── Field Type Donut ───────────────────────────────────────────

class _FieldTypeDonut extends StatefulWidget {
  final Map<String, int> typeMap;

  const _FieldTypeDonut({required this.typeMap});

  @override
  State<_FieldTypeDonut> createState() => _FieldTypeDonutState();
}

class _FieldTypeDonutState extends State<_FieldTypeDonut> {
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final entries = widget.typeMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final colors = [
      AppColors.primary,
      AppColors.accent,
      AppColors.success,
      AppColors.warning,
      AppColors.info,
      AppColors.error,
    ];

    final total = entries.fold<int>(0, (s, e) => s + e.value);

    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Field Type Distribution',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700)),
          Text('Breakdown of field types across all models',
              style: TextStyle(
                  fontSize: 11, color: cs.onSurface.withValues(alpha: 0.45))),
          const SizedBox(height: 16),
          LayoutBuilder(builder: (context, constraints) {
            final isWide = constraints.maxWidth > 500;
            return isWide
                ? Row(
                    children: [
                      SizedBox(
                        height: 140,
                        width: 140,
                        child: PieChart(
                          PieChartData(
                            sectionsSpace: 2,
                            centerSpaceRadius: 35,
                            pieTouchData: PieTouchData(
                              touchCallback: (event, response) {
                                setState(() {
                                  _touchedIndex = response
                                          ?.touchedSection
                                          ?.touchedSectionIndex ??
                                      -1;
                                });
                              },
                            ),
                            sections: entries.asMap().entries.map((e) {
                              final isTouched = _touchedIndex == e.key;
                              final color = colors[e.key % colors.length];
                              return PieChartSectionData(
                                value: e.value.value.toDouble(),
                                color: color,
                                radius: isTouched ? 48 : 40,
                                showTitle: false,
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: Column(
                          children: entries.asMap().entries.map((e) {
                            final color = colors[e.key % colors.length];
                            final pct =
                                (e.value.value / total * 100).toStringAsFixed(0);
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                        color: color, shape: BoxShape.circle),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(e.value.key,
                                        style: const TextStyle(fontSize: 12),
                                        overflow: TextOverflow.ellipsis),
                                  ),
                                  Text('${e.value.value} ($pct%)',
                                      style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: color)),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  )
                : Column(
                    children: [
                      SizedBox(
                        height: 120,
                        child: PieChart(
                          PieChartData(
                            sectionsSpace: 2,
                            centerSpaceRadius: 25,
                            sections: entries.asMap().entries.map((e) {
                              final color = colors[e.key % colors.length];
                              return PieChartSectionData(
                                value: e.value.value.toDouble(),
                                color: color,
                                radius: 40,
                                showTitle: false,
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 6,
                        children: entries.asMap().entries.map((e) {
                          final color = colors[e.key % colors.length];
                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                    color: color, shape: BoxShape.circle),
                              ),
                              const SizedBox(width: 4),
                              Text('${e.value.key}: ${e.value.value}',
                                  style: const TextStyle(fontSize: 11)),
                            ],
                          );
                        }).toList(),
                      ),
                    ],
                  );
          }),
        ],
      ),
    );
  }
}

// ── Model Card ─────────────────────────────────────────────────

class _ModelCard extends StatelessWidget {
  final ModelDefinition model;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ModelCard({
    required this.model,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final reqCount = model.fields.where((f) => f.required).length;
    final uniqueCount = model.fields.where((f) => f.unique).length;

    return AppCard(
      onTap: onEdit,
      padding: const EdgeInsets.all(18),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.info.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.data_object_rounded,
                      color: AppColors.info, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        model.name,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (model.description != null)
                        Text(
                          model.description!,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
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

            // Field chips
            if (model.fields.isNotEmpty) ...[
              Wrap(
                spacing: 5,
                runSpacing: 5,
                children: model.fields
                    .take(5)
                    .map((f) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primarySurface,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                f.name,
                                style: const TextStyle(
                                    fontSize: 10,
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w500),
                              ),
                              const Text(' · ',
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: AppColors.primary)),
                              Text(
                                f.type.displayName,
                                style: TextStyle(
                                    fontSize: 10,
                                    color: AppColors.primary
                                        .withValues(alpha: 0.7)),
                              ),
                            ],
                          ),
                        ))
                    .toList()
                  ..addAll(model.fields.length > 5
                      ? [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: cs.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '+${model.fields.length - 5} more',
                              style: TextStyle(
                                  fontSize: 10,
                                  color: cs.onSurface.withValues(alpha: 0.5)),
                            ),
                          )
                        ]
                      : []),
              ),
              const SizedBox(height: 12),
            ],

            // Footer stats
            Row(
              children: [
                _FieldBadge(
                    icon: Icons.list_alt_rounded,
                    label: '${model.fields.length} fields',
                    color: AppColors.info),
                const SizedBox(width: 8),
                if (reqCount > 0)
                  _FieldBadge(
                      icon: Icons.star_rounded,
                      label: '$reqCount req',
                      color: AppColors.warning),
                if (reqCount > 0) const SizedBox(width: 8),
                if (uniqueCount > 0)
                  _FieldBadge(
                      icon: Icons.fingerprint_rounded,
                      label: '$uniqueCount unique',
                      color: AppColors.success),
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

class _FieldBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _FieldBadge({
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

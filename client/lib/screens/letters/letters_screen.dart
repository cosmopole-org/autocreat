import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/letter_template.dart';
import '../../providers/letter_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common_widgets.dart';
import '../../data/mock_ui_text.dart';

class LettersScreen extends ConsumerStatefulWidget {
  const LettersScreen({super.key});

  @override
  ConsumerState<LettersScreen> createState() => _LettersScreenState();
}

class _LettersScreenState extends ConsumerState<LettersScreen> {
  final _searchController = TextEditingController();
  String _search = '';
  String? _categoryFilter;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _createLetter(BuildContext context) async {
    final repo = ref.read(letterRepositoryProvider);
    final letter = await repo.createLetter({
      'name': MockUiText.newLetterTemplate,
      'status': 'draft',
      'content': '',
      MockUiText.deltacontent: {},
    });
    if (context.mounted) context.push('/letters/${letter.id}/edit');
  }

  @override
  Widget build(BuildContext context) {
    final lettersAsync = ref.watch(letterNotifierProvider);

    return Scaffold(
      body: lettersAsync.when(
        loading: () => const LoadingGrid(),
        error: (e, _) => AppErrorWidget(
          message: e.toString(),
          onRetry: () => ref.invalidate(letterNotifierProvider),
        ),
        data: (letters) => _buildContent(context, letters),
      ),
    );
  }

  Widget _buildContent(BuildContext context, List<LetterTemplate> letters) {
    final categories = letters
        .map((l) => l.category ?? MockUiText.uncategorized)
        .toSet()
        .toList();
    final filtered = letters.where((l) {
      final matchesSearch = _search.isEmpty ||
          l.name.toLowerCase().contains(_search.toLowerCase());
      final matchesCat = _categoryFilter == null ||
          (l.category ?? MockUiText.uncategorized) == _categoryFilter;
      return matchesSearch && matchesCat;
    }).toList();

    final active = letters.where((l) => l.status == 'active').length;
    final draft = letters.where((l) => l.status == 'draft').length;
    final totalVars = letters.fold<int>(0, (s, l) => s + l.variables.length);

    return Column(
      children: [
        Expanded(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: AppPageLayout.contentPadding(context),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      AppPageHeader(
                        title: MockUiText.letterTemplates,
                        description: MockUiText
                            .manageReusableLetterTemplatesWithDynamicVariablesReadyToSend,
                        actionLabel: MockUiText.newTemplate,
                        compactActionLabel: MockUiText.newText,
                        actionIcon: Icons.add,
                        onAction: () => _createLetter(context),
                      ).animate().fadeIn(duration: 300.ms),
                      const SizedBox(height: 14),

                      // Stats row
                      _StatsRow(
                        total: letters.length,
                        active: active,
                        draft: draft,
                        totalVars: totalVars,
                      ).animate().fadeIn(delay: 100.ms),
                      const SizedBox(height: 20),

                      // Chart + category breakdown
                      if (letters.isNotEmpty)
                        _CategoryChart(letters: letters)
                            .animate()
                            .fadeIn(delay: 200.ms),
                      if (letters.isNotEmpty) const SizedBox(height: 20),

                      // Search + filter row
                      Row(
                        children: [
                          Expanded(
                            child: SearchField(
                              controller: _searchController,
                              hintText: MockUiText.searchTemplates,
                              onChanged: (v) => setState(() => _search = v),
                            ),
                          ),
                          if (categories.isNotEmpty) ...[
                            const SizedBox(width: 12),
                            _CategoryDropdown(
                              categories: categories,
                              selected: _categoryFilter,
                              onChanged: (v) =>
                                  setState(() => _categoryFilter = v),
                            ),
                          ],
                        ],
                      ).animate().fadeIn(delay: 250.ms),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
              if (filtered.isEmpty)
                SliverFillRemaining(
                  child: EmptyState(
                    title: MockUiText.noLetterTemplates,
                    subtitle: MockUiText.createReusableLetterTemplates,
                    icon: Icons.mail_outline,
                    actionLabel: MockUiText.createTemplate,
                    onAction: () => _createLetter(context),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 360,
                      mainAxisExtent: 210,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, i) => _LetterCard(
                        letter: filtered[i],
                        onEdit: () =>
                            context.push('/letters/${filtered[i].id}/edit'),
                        onDelete: () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (_) => ConfirmDialog(
                              title: MockUiText.deleteTemplate,
                              message: MockUiText
                                  .deleteThisLetterTemplatePermanently,
                            ),
                          );
                          if (confirmed == true) {
                            await ref
                                .read(letterNotifierProvider.notifier)
                                .delete(filtered[i].id);
                          }
                        },
                      )
                          .animate()
                          .fadeIn(delay: Duration(milliseconds: 60 + i * 50)),
                      childCount: filtered.length,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Stats Row ──────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  final int total;
  final int active;
  final int draft;
  final int totalVars;

  const _StatsRow({
    required this.total,
    required this.active,
    required this.draft,
    required this.totalVars,
  });

  @override
  Widget build(BuildContext context) {
    final stats = [
      (
        Icons.mail_rounded,
        MockUiText.totalTemplates,
        total.toString(),
        AppColors.primary
      ),
      (
        Icons.check_circle_rounded,
        MockUiText.active,
        active.toString(),
        AppColors.success
      ),
      (
        Icons.edit_note_rounded,
        MockUiText.draft,
        draft.toString(),
        AppColors.warning
      ),
      (
        Icons.code_rounded,
        MockUiText.totalVariables,
        totalVars.toString(),
        AppColors.accent
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
                      padding: EdgeInsets.only(left: e.key == 0 ? 0 : 12),
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

// ── Category Chart ─────────────────────────────────────────────

class _CategoryChart extends StatelessWidget {
  final List<LetterTemplate> letters;

  const _CategoryChart({required this.letters});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final catMap = <String, int>{};
    for (final l in letters) {
      final cat = l.category ?? MockUiText.uncategorized;
      catMap[cat] = (catMap[cat] ?? 0) + 1;
    }
    final cats = catMap.entries.toList();
    const colors = AppColors.chartColors;

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
                  Text(MockUiText.templatesByCategory,
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  Text(MockUiText.distributionAcrossCategories,
                      style: TextStyle(
                          fontSize: 11,
                          color: cs.onSurface.withValues(alpha: 0.45))),
                ],
              ),
              // Variable usage indicator
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.code, size: 12, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Text(
                      MockUiText.avgVars((letters.fold<int>(
                                  0, (s, l) => s + l.variables.length) /
                              (letters.isEmpty ? 1 : letters.length))
                          .toStringAsFixed(1)),
                      style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.primary,
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
                    children: [
                      SizedBox(
                        height: 140,
                        width: 140,
                        child: _buildPie(cats, colors),
                      ),
                      const SizedBox(width: 24),
                      Expanded(child: _buildLegend(cats, colors, context)),
                    ],
                  )
                : Column(
                    children: [
                      SizedBox(
                        height: 120,
                        child: _buildPie(cats, colors),
                      ),
                      const SizedBox(height: 12),
                      _buildLegend(cats, colors, context),
                    ],
                  );
          }),
        ],
      ),
    );
  }

  Widget _buildPie(List<MapEntry<String, int>> cats, List<Color> colors) {
    return PieChart(
      PieChartData(
        sectionsSpace: 2,
        centerSpaceRadius: 30,
        sections: cats.asMap().entries.map((e) {
          final color = colors[e.key % colors.length];
          return PieChartSectionData(
            value: e.value.value.toDouble(),
            color: color,
            radius: 40,
            showTitle: false,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLegend(List<MapEntry<String, int>> cats, List<Color> colors,
      BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: cats.asMap().entries.map((e) {
        final color = colors[e.key % colors.length];
        final pct =
            (e.value.value / cats.fold<int>(0, (s, c) => s + c.value) * 100)
                .toStringAsFixed(0);
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(e.value.key,
                    style: const TextStyle(fontSize: 12),
                    overflow: TextOverflow.ellipsis),
              ),
              Text(MockUiText.distributionLegend(e.value.value, pct),
                  style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700, color: color)),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ── Category Dropdown ──────────────────────────────────────────

class _CategoryDropdown extends StatelessWidget {
  final List<String> categories;
  final String? selected;
  final ValueChanged<String?> onChanged;

  const _CategoryDropdown({
    required this.categories,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outline.withValues(alpha: 0.5)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: selected,
          hint: Text(MockUiText.allCategories, style: const TextStyle(fontSize: 13)),
          style: TextStyle(fontSize: 13, color: cs.onSurface),
          items: [
            DropdownMenuItem<String?>(
              value: null,
              child: Text(MockUiText.allCategories),
            ),
            ...categories.map((c) => DropdownMenuItem<String?>(
                  value: c,
                  child: Text(c),
                )),
          ],
          onChanged: onChanged,
          isDense: true,
        ),
      ),
    );
  }
}

// ── Letter Card ────────────────────────────────────────────────

class _LetterCard extends StatelessWidget {
  final LetterTemplate letter;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _LetterCard({
    required this.letter,
    required this.onEdit,
    required this.onDelete,
  });

  Color get _statusColor {
    switch (letter.status) {
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
          // Top row: icon + status + menu
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.mail_rounded,
                    color: AppColors.warning, size: 20),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  letter.status.toUpperCase(),
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
                      value: 'edit', child: Text(MockUiText.edit)),
                  GlassContextMenuItem(
                      value: 'delete',
                      child: Text(MockUiText.delete,
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

          // Name
          Text(
            letter.name,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),

          // Description
          if (letter.description != null) ...[
            const SizedBox(height: 4),
            Text(
              letter.description!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.55),
                  ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],

          const Spacer(),

          // Footer: category + variable count
          Row(
            children: [
              if (letter.category != null) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    letter.category!,
                    style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500),
                  ),
                ),
                const SizedBox(width: 6),
              ],
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.code,
                        size: 10, color: cs.onSurface.withValues(alpha: 0.5)),
                    const SizedBox(width: 3),
                    Text(
                      MockUiText.varsCount(letter.variables.length),
                      style: TextStyle(
                          fontSize: 10,
                          color: cs.onSurface.withValues(alpha: 0.6)),
                    ),
                  ],
                ),
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

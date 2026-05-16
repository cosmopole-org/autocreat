import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../../core/constants.dart';
import '../../data/demo_data.dart';
import '../../models/company.dart';
import '../../providers/company_provider.dart';
import '../../providers/demo_provider.dart';
import '../../providers/flow_provider.dart';
import '../../data/demo_overrides.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common_widgets.dart';
import '../../data/ui_text.dart';

class CompanyDetailScreen extends ConsumerStatefulWidget {
  final String id;

  const CompanyDetailScreen({super.key, required this.id});

  @override
  ConsumerState<CompanyDetailScreen> createState() =>
      _CompanyDetailScreenState();
}

class _CompanyDetailScreenState extends ConsumerState<CompanyDetailScreen> {
  String? _logoPath;

  Future<void> _pickLogo() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 256,
      maxHeight: 256,
    );
    if (picked != null && mounted) {
      setState(() => _logoPath = picked.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDemo = ref.watch(isDemoModeProvider);
    final companyAsync = isDemo
        ? AsyncValue.data(Company.fromJson(DemoData.company))
        : ref.watch(companyDetailProvider(widget.id));
    final flowsAsync = isDemo
        ? ref.watch(demoTypedFlowsProvider)
        : ref.watch(flowsProvider(widget.id));

    return companyAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(
          leading: AppBarBackButton(onPressed: () => context.pop()),
        ),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(
          leading: AppBarBackButton(onPressed: () => context.pop()),
        ),
        body: AppErrorWidget(message: e.toString()),
      ),
      data: (company) {
        // Capacity metrics (mock values to show progress indicators)
        final memberUsage = company.memberCount > 0
            ? (company.memberCount / 50).clamp(0.0, 1.0)
            : 0.0;
        final flowUsage = company.flowCount > 0
            ? (company.flowCount / 20).clamp(0.0, 1.0)
            : 0.0;

        return Scaffold(
          appBar: AppBar(
            leading: AppBarBackButton(onPressed: () => context.pop()),
            title: Text(company.name,
                maxLines: 1, overflow: TextOverflow.ellipsis),
            titleSpacing: 0,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hero header — branded summary card
                EditorHeroHeader(
                  title: company.name,
                  subtitle: company.industry,
                  leading: GestureDetector(
                    onTap: _pickLogo,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        _CompanyLogo(
                          logoUrl: _logoPath ?? company.logo,
                          name: company.name,
                          size: 64,
                        ),
                        Positioned(
                          bottom: -2,
                          right: -2,
                          child: Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: Theme.of(context)
                                      .scaffoldBackgroundColor,
                                  width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary
                                      .withValues(alpha: 0.30),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(Icons.camera_alt,
                                size: 12, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                  chips: [
                    EditorHeroChip(
                      icon: Icons.circle,
                      label: company.status,
                      color: company.status == 'active'
                          ? AppColors.success
                          : AppColors.warning,
                    ),
                    EditorHeroChip(
                      icon: Icons.people_outline_rounded,
                      label:
                          '${company.memberCount} ${UiText.members.toLowerCase()}',
                      color: AppColors.accent,
                    ),
                    EditorHeroChip(
                      icon: Icons.account_tree_outlined,
                      label:
                          '${company.flowCount} ${UiText.flows.toLowerCase()}',
                      color: AppColors.warning,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Capacity indicators
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(UiText.capacity,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: _CapacityIndicator(
                              label: UiText.members,
                              value: memberUsage,
                              count: company.memberCount,
                              max: 50,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            child: _CapacityIndicator(
                              label: UiText.flows,
                              value: flowUsage,
                              count: company.flowCount,
                              max: 20,
                              color: AppColors.accent,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Info
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(UiText.details,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 12),
                      if (company.description != null)
                        InfoRow(
                            label: UiText.description,
                            value: company.description!),
                      if (company.website != null)
                        InfoRow(
                            label: UiText.website,
                            value: company.website!,
                            icon: Icons.link),
                      InfoRow(
                          label: UiText.members,
                          value: '${company.memberCount}',
                          icon: Icons.people),
                      InfoRow(
                          label: UiText.flows,
                          value: '${company.flowCount}',
                          icon: Icons.account_tree),
                      if (company.createdAt != null)
                        InfoRow(
                          label: UiText.created,
                          value: company.createdAt!
                              .toLocal()
                              .toString()
                              .split(UiText.text)[0],
                          icon: Icons.calendar_today,
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Flows
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(UiText.flows,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700)),
                      TextButton.icon(
                        icon: const Icon(Icons.add, size: 16),
                        label: Text(UiText.newFlow),
                        onPressed: () => context.go(AppRoutes.flows),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                flowsAsync.when(
                  loading: () => const LoadingList(count: 3),
                  error: (e, _) => const SizedBox.shrink(),
                  data: (flows) {
                    if (flows.isEmpty) {
                      return AppCard(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Row(
                            children: [
                              Icon(Icons.account_tree_outlined,
                                  size: 18,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.45)),
                              const SizedBox(width: 10),
                              Text(UiText.noFlowsYet,
                                  style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withValues(alpha: 0.62))),
                            ],
                          ),
                        ),
                      );
                    }
                    return Column(
                      children: [
                        for (final f in flows) ...[
                          AppCard(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                            onTap: () => context.push('/flows/${f.id}/edit'),
                            child: Row(
                              children: [
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary
                                        .withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                      Icons.account_tree_outlined,
                                      size: 18,
                                      color: AppColors.primary),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(f.name,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleSmall
                                              ?.copyWith(
                                                  fontWeight:
                                                      FontWeight.w600)),
                                      const SizedBox(height: 2),
                                      Text(f.status,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Directionality.of(context) ==
                                          TextDirection.rtl
                                      ? Icons.chevron_left_rounded
                                      : Icons.chevron_right_rounded,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.45),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Company Logo ───────────────────────────────────────────────

class _CompanyLogo extends StatelessWidget {
  final String? logoUrl;
  final String name;
  final double size;

  const _CompanyLogo(
      {required this.logoUrl, required this.name, required this.size});

  @override
  Widget build(BuildContext context) {
    if (logoUrl != null && logoUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: logoUrl!,
        imageBuilder: (context, imageProvider) => Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            image: DecorationImage(image: imageProvider, fit: BoxFit.cover),
          ),
        ),
        placeholder: (context, url) => _LogoFallback(name: name, size: size),
        errorWidget: (context, url, error) =>
            _LogoFallback(name: name, size: size),
      );
    }
    return _LogoFallback(name: name, size: size);
  }
}

class _LogoFallback extends StatelessWidget {
  final String name;
  final double size;

  const _LogoFallback({required this.name, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}

// ── Capacity Indicator ─────────────────────────────────────────

class _CapacityIndicator extends StatelessWidget {
  final String label;
  final double value;
  final int count;
  final int max;
  final Color color;

  const _CapacityIndicator({
    required this.label,
    required this.value,
    required this.count,
    required this.max,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: Theme.of(context).textTheme.labelMedium),
            Text(UiText.capacityRatio(count, max),
                style: Theme.of(context)
                    .textTheme
                    .labelMedium
                    ?.copyWith(color: color, fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 8),
        LinearPercentIndicator(
          lineHeight: 8,
          percent: value,
          backgroundColor: color.withValues(alpha: 0.12),
          progressColor: color,
          barRadius: const Radius.circular(4),
          padding: EdgeInsets.zero,
          animation: true,
          animationDuration: 800,
        ),
      ],
    );
  }
}

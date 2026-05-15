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
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Company header
                AppCard(
                  child: Row(
                    children: [
                      // Logo with upload capability
                      GestureDetector(
                        onTap: _pickLogo,
                        child: Stack(
                          children: [
                            _CompanyLogo(
                              logoUrl: _logoPath ?? company.logo,
                              name: company.name,
                              size: 72,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: Colors.white, width: 1.5),
                                ),
                                child: const Icon(Icons.camera_alt,
                                    size: 12, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              company.name,
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            if (company.industry != null)
                              Text(
                                company.industry!,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            const SizedBox(height: 8),
                            StatusChip(status: company.status),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Capacity indicators
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(UiText.capacity,
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 16),
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
                          style: Theme.of(context).textTheme.titleMedium),
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(UiText.flows,
                        style: Theme.of(context).textTheme.titleMedium),
                    TextButton.icon(
                      icon: const Icon(Icons.add, size: 16),
                      label: Text(UiText.newFlow),
                      onPressed: () => context.go(AppRoutes.flows),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                flowsAsync.when(
                  loading: () => const LoadingList(count: 3),
                  error: (e, _) => const SizedBox.shrink(),
                  data: (flows) {
                    if (flows.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Text(UiText.noFlowsYet,
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54))),
                      );
                    }
                    return Column(
                      children: flows
                          .map((f) => ListTile(
                                leading: const Icon(Icons.account_tree_outlined,
                                    color: AppColors.primary),
                                title: Text(f.name),
                                subtitle: Text(f.status),
                                trailing: Icon(
                                  Directionality.of(context) == TextDirection.rtl
                                      ? Icons.chevron_left
                                      : Icons.chevron_right,
                                ),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                onTap: () =>
                                    context.push('/flows/${f.id}/edit'),
                              ))
                          .toList(),
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

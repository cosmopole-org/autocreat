import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants.dart';
import '../../providers/company_provider.dart';
import '../../providers/flow_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common_widgets.dart';

class CompanyDetailScreen extends ConsumerWidget {
  final String id;

  const CompanyDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final companyAsync = ref.watch(companyDetailProvider(id));
    final flowsAsync = ref.watch(flowsProvider(id));

    return companyAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(
        body: ErrorWidget(message: e.toString()),
      ),
      data: (company) => Scaffold(
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Company header
              AppCard(
                child: Row(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Text(
                          company.name.isNotEmpty
                              ? company.name[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
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

              // Info
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Details',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 12),
                    if (company.description != null)
                      InfoRow(label: 'Description', value: company.description!),
                    if (company.website != null)
                      InfoRow(
                          label: 'Website',
                          value: company.website!,
                          icon: Icons.link),
                    InfoRow(
                        label: 'Members',
                        value: '${company.memberCount}',
                        icon: Icons.people),
                    InfoRow(
                        label: 'Flows',
                        value: '${company.flowCount}',
                        icon: Icons.account_tree),
                    if (company.createdAt != null)
                      InfoRow(
                        label: 'Created',
                        value: company.createdAt!.toLocal().toString().split('.')[0],
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
                  Text('Flows',
                      style: Theme.of(context).textTheme.titleMedium),
                  TextButton.icon(
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('New Flow'),
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
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Text('No flows yet',
                          style:
                              TextStyle(color: AppColors.lightTextSecondary)),
                    );
                  }
                  return Column(
                    children: flows
                        .map((f) => ListTile(
                              leading: const Icon(Icons.account_tree_outlined,
                                  color: AppColors.primary),
                              title: Text(f.name),
                              subtitle: Text(f.status),
                              trailing: const Icon(Icons.chevron_right),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              onTap: () =>
                                  context.go('/flows/${f.id}/edit'),
                            ))
                        .toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

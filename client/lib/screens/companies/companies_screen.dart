import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/company.dart';
import '../../providers/company_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common_widgets.dart';

class CompaniesScreen extends ConsumerStatefulWidget {
  const CompaniesScreen({super.key});

  @override
  ConsumerState<CompaniesScreen> createState() => _CompaniesScreenState();
}

class _CompaniesScreenState extends ConsumerState<CompaniesScreen> {
  final _searchController = TextEditingController();
  String _search = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showCreateDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => _CompanyDialog(
        onSave: (data) async {
          await ref.read(companyNotifierProvider.notifier).create(data);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final companiesAsync = ref.watch(companyNotifierProvider);

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LayoutBuilder(builder: (context, constraints) {
                  final isNarrow = constraints.maxWidth < 500;
                  return Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Companies',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                      AppButton(
                        label: isNarrow ? 'New' : 'New Company',
                        icon: Icons.add,
                        onPressed: () => _showCreateDialog(context),
                      ),
                    ],
                  );
                }),
                const SizedBox(height: 12),
                SearchField(
                  controller: _searchController,
                  hintText: 'Search companies...',
                  onChanged: (v) => setState(() => _search = v),
                ),
              ],
            ),
          ),
          Expanded(
            child: companiesAsync.when(
              loading: () => const LoadingGrid(),
              error: (e, _) => AppErrorWidget(
                  message: e.toString(),
                  onRetry: () =>
                      ref.read(companyNotifierProvider.notifier).refresh()),
              data: (companies) {
                final filtered = _search.isEmpty
                    ? companies
                    : companies
                        .where((c) => c.name
                            .toLowerCase()
                            .contains(_search.toLowerCase()))
                        .toList();

                if (filtered.isEmpty) {
                  return EmptyState(
                    title: _search.isEmpty
                        ? 'No companies yet'
                        : 'No results found',
                    subtitle: _search.isEmpty
                        ? 'Create your first company to get started'
                        : null,
                    icon: Icons.business_outlined,
                    actionLabel: _search.isEmpty ? 'Create Company' : null,
                    onAction: _search.isEmpty
                        ? () => _showCreateDialog(context)
                        : null,
                  );
                }

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: _CompanyStatsRow(companies: companies),
                    ),
                    Expanded(
                      child: GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate:
                            const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 320,
                          mainAxisExtent: 160,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: filtered.length,
                        itemBuilder: (context, i) => _CompanyCard(
                          company: filtered[i],
                          onTap: () =>
                              context.go('/companies/${filtered[i].id}'),
                          onEdit: () => showDialog(
                            context: context,
                            builder: (_) => _CompanyDialog(
                              company: filtered[i],
                              onSave: (data) async {
                                await ref
                                    .read(companyNotifierProvider.notifier)
                                    .updateItem(filtered[i].id, data);
                              },
                            ),
                          ),
                          onDelete: () async {
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (_) => const ConfirmDialog(
                                title: 'Delete Company',
                                message:
                                    'Are you sure you want to delete this company?',
                              ),
                            );
                            if (confirmed == true) {
                              await ref
                                  .read(companyNotifierProvider.notifier)
                                  .delete(filtered[i].id);
                            }
                          },
                        ).animate().fadeIn(
                              delay: Duration(milliseconds: i * 50),
                            ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CompanyStatsRow extends StatelessWidget {
  final List<Company> companies;

  const _CompanyStatsRow({required this.companies});

  @override
  Widget build(BuildContext context) {
    final total = companies.length;
    final active = companies.where((c) => c.status == 'active').length;
    final members = companies.fold<int>(
      0,
      (sum, c) => sum + c.memberCount,
    );
    final flows = companies.fold<int>(
      0,
      (sum, c) => sum + c.flowCount,
    );

    return LayoutBuilder(builder: (context, constraints) {
      final cols = constraints.maxWidth > 500 ? 4 : 2;
      return GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: cols,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: constraints.maxWidth > 500 ? 2.05 : 1.6,
        children: [
          AppStatCard(
            icon: Icons.business_rounded,
            value: '$total',
            label: 'Companies',
            color: AppColors.primary,
          ),
          AppStatCard(
            icon: Icons.check_circle_rounded,
            value: '$active',
            label: 'Active',
            color: AppColors.success,
          ),
          AppStatCard(
            icon: Icons.people_rounded,
            value: '$members',
            label: 'Members',
            color: AppColors.accent,
          ),
          AppStatCard(
            icon: Icons.account_tree_rounded,
            value: '$flows',
            label: 'Flows',
            color: AppColors.warning,
          ),
        ],
      );
    });
  }
}

class _CompanyCard extends StatelessWidget {
  final dynamic company;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CompanyCard({
    required this.company,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: company.logo != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(company.logo, fit: BoxFit.cover),
                      )
                    : Center(
                        child: Text(
                          company.name.isNotEmpty
                              ? company.name[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      company.name,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (company.industry != null)
                      Text(
                        company.industry!,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, size: 18),
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
          const Spacer(),
          Row(
            children: [
              StatusChip(status: company.status),
              const Spacer(),
              _InfoChip(
                  icon: Icons.people,
                  label: '${company.memberCount}'),
              const SizedBox(width: 8),
              _InfoChip(
                  icon: Icons.account_tree,
                  label: '${company.flowCount}'),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 12, color: AppColors.lightTextSecondary),
        const SizedBox(width: 3),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}

class _CompanyDialog extends StatefulWidget {
  final dynamic company;
  final Future<void> Function(Map<String, dynamic>) onSave;

  const _CompanyDialog({this.company, required this.onSave});

  @override
  State<_CompanyDialog> createState() => _CompanyDialogState();
}

class _CompanyDialogState extends State<_CompanyDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descController;
  late TextEditingController _industryController;
  late TextEditingController _websiteController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.company?.name ?? '');
    _descController =
        TextEditingController(text: widget.company?.description ?? '');
    _industryController =
        TextEditingController(text: widget.company?.industry ?? '');
    _websiteController =
        TextEditingController(text: widget.company?.website ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _industryController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title:
          Text(widget.company == null ? 'New Company' : 'Edit Company'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Company name *'),
                validator: (v) =>
                    v?.isEmpty ?? true ? 'Name is required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _industryController,
                decoration: const InputDecoration(labelText: 'Industry'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _websiteController,
                decoration: const InputDecoration(labelText: 'Website'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        AppButton(
          label: 'Save',
          loading: _saving,
          onPressed: () async {
            if (!_formKey.currentState!.validate()) return;
            setState(() => _saving = true);
            try {
              await widget.onSave({
                'name': _nameController.text,
                'description': _descController.text,
                'industry': _industryController.text,
                'website': _websiteController.text,
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

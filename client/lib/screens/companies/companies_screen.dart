import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/company.dart';
import '../../providers/company_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common_widgets.dart';
import '../../data/mock_ui_text.dart';

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
      body: companiesAsync.when(
        loading: () => CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: AppPageLayout.contentPadding(context, horizontal: 20),
                child: AppPageHeader(
                  title: MockUiText.companies,
                  description: MockUiText
                      .organizeClientAndPartnerWorkspacesMonitorPortfolioHealthAndK,
                  actionLabel: MockUiText.newCompany,
                  compactActionLabel: MockUiText.newText,
                  actionIcon: Icons.add,
                  onAction: () => _showCreateDialog(context),
                ).animate().fadeIn(duration: 300.ms),
              ),
            ),
            const SliverFillRemaining(child: LoadingGrid()),
          ],
        ),
        error: (e, _) => AppErrorWidget(
          message: e.toString(),
          onRetry: () => ref.read(companyNotifierProvider.notifier).refresh(),
        ),
        data: (companies) {
          final filtered = _search.isEmpty
              ? companies
              : companies
                  .where((c) =>
                      c.name.toLowerCase().contains(_search.toLowerCase()))
                  .toList();

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding:
                      AppPageLayout.contentPadding(context, horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppPageHeader(
                        title: MockUiText.companies,
                        description: MockUiText
                            .organizeClientAndPartnerWorkspacesMonitorPortfolioHealthAndK,
                        actionLabel: MockUiText.newCompany,
                        compactActionLabel: MockUiText.newText,
                        actionIcon: Icons.add,
                        onAction: () => _showCreateDialog(context),
                      ).animate().fadeIn(duration: 300.ms),
                      const SizedBox(height: 14),
                      _CompanyStatsRow(companies: companies)
                          .animate()
                          .fadeIn(delay: 100.ms),
                      const SizedBox(height: 24),
                      SearchField(
                        controller: _searchController,
                        hintText: MockUiText.searchCompanies,
                        onChanged: (v) => setState(() => _search = v),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
              if (filtered.isEmpty)
                SliverFillRemaining(
                  child: EmptyState(
                    title: _search.isEmpty
                        ? MockUiText.noCompaniesYet
                        : MockUiText.noResultsFound,
                    subtitle: _search.isEmpty
                        ? MockUiText.createYourFirstCompanyToGetStarted
                        : null,
                    icon: Icons.business_outlined,
                    actionLabel:
                        _search.isEmpty ? MockUiText.createCompany : null,
                    onAction: _search.isEmpty
                        ? () => _showCreateDialog(context)
                        : null,
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  sliver: SliverGrid(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) => _CompanyCard(
                        company: filtered[i],
                        onTap: () =>
                            context.push('/companies/${filtered[i].id}'),
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
                            builder: (_) => ConfirmDialog(
                              title: MockUiText.deleteCompany,
                              message: MockUiText
                                  .areYouSureYouWantToDeleteThisCompany,
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
                      childCount: filtered.length,
                    ),
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 320,
                      mainAxisExtent: 160,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                  ),
                ),
            ],
          );
        },
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
        padding: EdgeInsets.zero,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: cols,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: constraints.maxWidth > 500 ? 2.05 : 1.6,
        children: [
          AppStatCard(
            icon: Icons.business_rounded,
            value: '$total',
            label: MockUiText.companies,
            color: AppColors.primary,
          ),
          AppStatCard(
            icon: Icons.check_circle_rounded,
            value: '$active',
            label: MockUiText.active,
            color: AppColors.success,
          ),
          AppStatCard(
            icon: Icons.people_rounded,
            value: '$members',
            label: MockUiText.members,
            color: AppColors.accent,
          ),
          AppStatCard(
            icon: Icons.account_tree_rounded,
            value: '$flows',
            label: MockUiText.flows,
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
                  PopupMenuItem(value: 'edit', child: Text(MockUiText.edit)),
                  PopupMenuItem(
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
          const Spacer(),
          Row(
            children: [
              StatusChip(status: company.status),
              const Spacer(),
              _InfoChip(icon: Icons.people, label: '${company.memberCount}'),
              const SizedBox(width: 8),
              _InfoChip(
                  icon: Icons.account_tree, label: '${company.flowCount}'),
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
    _nameController = TextEditingController(text: widget.company?.name ?? '');
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
      title: Text(widget.company == null
          ? MockUiText.newCompany
          : MockUiText.editCompany),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration:
                    InputDecoration(labelText: MockUiText.companyNameRequired),
                validator: (v) =>
                    v?.isEmpty ?? true ? MockUiText.nameIsRequired : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _industryController,
                decoration: InputDecoration(labelText: MockUiText.industry),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _websiteController,
                decoration: InputDecoration(labelText: MockUiText.website),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descController,
                decoration: InputDecoration(labelText: MockUiText.description),
                maxLines: 3,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(MockUiText.cancel),
        ),
        AppButton(
          label: MockUiText.save,
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

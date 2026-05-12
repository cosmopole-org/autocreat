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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: SearchField(
                    controller: _searchController,
                    hintText: 'Search forms...',
                    onChanged: (v) => setState(() => _search = v),
                  ),
                ),
                const SizedBox(width: 12),
                AppButton(
                  label: 'New Form',
                  icon: Icons.add,
                  onPressed: () => _createForm(context),
                ),
              ],
            ),
          ),
          Expanded(
            child: formsAsync.when(
              loading: () => const LoadingGrid(),
              error: (e, _) => ErrorWidget(message: e.toString()),
              data: (forms) {
                final filtered = _search.isEmpty
                    ? forms
                    : forms
                        .where((f) => f.name
                            .toLowerCase()
                            .contains(_search.toLowerCase()))
                        .toList();

                if (filtered.isEmpty) {
                  return EmptyState(
                    title: 'No forms yet',
                    subtitle: 'Create your first form definition',
                    icon: Icons.dynamic_form_outlined,
                    actionLabel: 'Create Form',
                    onAction: () => _createForm(context),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate:
                      const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 320,
                    mainAxisExtent: 160,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (context, i) => _FormCard(
                    form: filtered[i],
                    onEdit: () =>
                        context.go('/forms/${filtered[i].id}/edit'),
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
                  ).animate().fadeIn(delay: Duration(milliseconds: i * 50)),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FormCard extends StatelessWidget {
  final FormDefinition form;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _FormCard({
    required this.form,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onEdit,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.dynamic_form_outlined,
                    color: AppColors.accent, size: 20),
              ),
              const Spacer(),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, size: 18),
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
          const Spacer(),
          Text(
            form.name,
            style: Theme.of(context).textTheme.titleMedium,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (form.description != null)
            Text(
              form.description!,
              style: Theme.of(context).textTheme.bodySmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              StatusChip(status: form.status),
              const Spacer(),
              Text(
                '${form.fields.length} fields',
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

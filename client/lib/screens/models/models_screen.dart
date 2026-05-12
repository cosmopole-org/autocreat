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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: SearchField(
                    controller: _searchController,
                    hintText: 'Search models...',
                    onChanged: (v) => setState(() => _search = v),
                  ),
                ),
                const SizedBox(width: 12),
                AppButton(
                  label: 'New Model',
                  icon: Icons.add,
                  onPressed: () => _createModel(context),
                ),
              ],
            ),
          ),
          Expanded(
            child: modelsAsync.when(
              loading: () => const LoadingGrid(),
              error: (e, _) => ErrorWidget(message: e.toString()),
              data: (models) {
                final filtered = _search.isEmpty
                    ? models
                    : models
                        .where((m) => m.name
                            .toLowerCase()
                            .contains(_search.toLowerCase()))
                        .toList();

                if (filtered.isEmpty) {
                  return EmptyState(
                    title: 'No models yet',
                    subtitle: 'Define your data structures',
                    icon: Icons.data_object_outlined,
                    actionLabel: 'Create Model',
                    onAction: () => _createModel(context),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  itemBuilder: (context, i) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
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
                    ).animate().fadeIn(delay: Duration(milliseconds: i * 50)),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

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
    return AppCard(
      onTap: onEdit,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.info.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.data_object_outlined,
                color: AppColors.info, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(model.name,
                    style: Theme.of(context).textTheme.titleMedium),
                if (model.description != null)
                  Text(model.description!,
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 4,
                  children: model.fields
                      .take(4)
                      .map((f) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primarySurface,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${f.name}: ${f.type.displayName}',
                              style: const TextStyle(
                                  fontSize: 10, color: AppColors.primary),
                            ),
                          ))
                      .toList()
                    ..addAll(model.fields.length > 4
                        ? [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primarySurface,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '+${model.fields.length - 4} more',
                                style: const TextStyle(
                                    fontSize: 10,
                                    color: AppColors.lightTextSecondary),
                              ),
                            )
                          ]
                        : []),
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
    );
  }
}

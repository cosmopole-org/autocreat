import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/flow.dart';
import '../../providers/flow_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common_widgets.dart';

class FlowsScreen extends ConsumerStatefulWidget {
  const FlowsScreen({super.key});

  @override
  ConsumerState<FlowsScreen> createState() => _FlowsScreenState();
}

class _FlowsScreenState extends ConsumerState<FlowsScreen> {
  final _searchController = TextEditingController();
  String _search = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _createFlow(BuildContext context) async {
    final repo = ref.read(flowRepositoryProvider);
    final flow = await repo.createFlow({
      'name': 'New Flow',
      'status': 'draft',
      'nodes': [
        {
          'id': 'start_1',
          'label': 'Start',
          'type': 'start',
          'x': 100.0,
          'y': 200.0,
          'width': 160.0,
          'height': 60.0,
        },
        {
          'id': 'end_1',
          'label': 'End',
          'type': 'end',
          'x': 400.0,
          'y': 200.0,
          'width': 160.0,
          'height': 60.0,
        },
      ],
      'edges': [],
    });
    if (context.mounted) {
      context.go('/flows/${flow.id}/edit');
    }
  }

  @override
  Widget build(BuildContext context) {
    final flowsAsync = ref.watch(flowsProvider(null));

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
                    hintText: 'Search flows...',
                    onChanged: (v) => setState(() => _search = v),
                  ),
                ),
                const SizedBox(width: 12),
                AppButton(
                  label: 'New Flow',
                  icon: Icons.add,
                  onPressed: () => _createFlow(context),
                ),
              ],
            ),
          ),
          Expanded(
            child: flowsAsync.when(
              loading: () => const LoadingGrid(),
              error: (e, _) => AppErrorWidget(message: e.toString()),
              data: (flows) {
                final filtered = _search.isEmpty
                    ? flows
                    : flows
                        .where((f) => f.name
                            .toLowerCase()
                            .contains(_search.toLowerCase()))
                        .toList();

                if (filtered.isEmpty) {
                  return EmptyState(
                    title: 'No flows yet',
                    subtitle: 'Create your first organizational flow',
                    icon: Icons.account_tree_outlined,
                    actionLabel: 'Create Flow',
                    onAction: () => _createFlow(context),
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
                  itemBuilder: (context, i) => _FlowCard(
                    flow: filtered[i],
                    onEdit: () =>
                        context.go('/flows/${filtered[i].id}/edit'),
                    onDelete: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (_) => const ConfirmDialog(
                          title: 'Delete Flow',
                          message: 'This will delete the flow permanently.',
                        ),
                      );
                      if (confirmed == true) {
                        await ref
                            .read(flowRepositoryProvider)
                            .deleteFlow(filtered[i].id);
                        ref.invalidate(flowsProvider);
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

class _FlowCard extends StatelessWidget {
  final Flow flow;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _FlowCard({
    required this.flow,
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
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.account_tree_outlined,
                    color: AppColors.primary, size: 20),
              ),
              const Spacer(),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, size: 18),
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'edit', child: Text('Open Editor')),
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
            flow.name,
            style: Theme.of(context).textTheme.titleMedium,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (flow.description != null)
            Text(
              flow.description!,
              style: Theme.of(context).textTheme.bodySmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              StatusChip(status: flow.status),
              const Spacer(),
              Text(
                '${flow.nodes.length} nodes',
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

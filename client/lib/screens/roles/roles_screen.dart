import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/role.dart';
import '../../providers/role_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common_widgets.dart';

class RolesScreen extends ConsumerStatefulWidget {
  const RolesScreen({super.key});

  @override
  ConsumerState<RolesScreen> createState() => _RolesScreenState();
}

class _RolesScreenState extends ConsumerState<RolesScreen> {
  final _searchController = TextEditingController();
  String _search = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rolesAsync = ref.watch(roleNotifierProvider);

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
                    hintText: 'Search roles...',
                    onChanged: (v) => setState(() => _search = v),
                  ),
                ),
                const SizedBox(width: 12),
                AppButton(
                  label: 'New Role',
                  icon: Icons.add,
                  onPressed: () => context.go('/roles/new/edit'),
                ),
              ],
            ),
          ),
          Expanded(
            child: rolesAsync.when(
              loading: () => const LoadingList(),
              error: (e, _) => ErrorWidget(
                  message: e.toString(),
                  onRetry: () =>
                      ref.read(roleNotifierProvider.notifier).refresh()),
              data: (roles) {
                final filtered = _search.isEmpty
                    ? roles
                    : roles
                        .where((r) => r.name
                            .toLowerCase()
                            .contains(_search.toLowerCase()))
                        .toList();

                if (filtered.isEmpty) {
                  return EmptyState(
                    title: 'No roles yet',
                    subtitle: 'Create roles to manage access control',
                    icon: Icons.shield_outlined,
                    actionLabel: 'Create Role',
                    onAction: () => context.go('/roles/new/edit'),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  itemBuilder: (context, i) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _RoleCard(
                      role: filtered[i],
                      onEdit: () =>
                          context.go('/roles/${filtered[i].id}/edit'),
                      onDelete: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (_) => const ConfirmDialog(
                            title: 'Delete Role',
                            message: 'Delete this role permanently?',
                          ),
                        );
                        if (confirmed == true) {
                          await ref
                              .read(roleNotifierProvider.notifier)
                              .delete(filtered[i].id);
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

class _RoleCard extends StatelessWidget {
  final Role role;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _RoleCard({
    required this.role,
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
              color: AppColors.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.shield_outlined,
                color: AppColors.success, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(role.name,
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primarySurface,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        role.level,
                        style: const TextStyle(
                            fontSize: 10, color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
                if (role.description != null)
                  Text(role.description!,
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 1),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _PermChip(
                        label: '${role.permissions.length} permissions'),
                    const SizedBox(width: 8),
                    _PermChip(label: '${role.memberCount} members'),
                    const Spacer(),
                    StatusChip(
                        status: role.isActive ? 'active' : 'inactive'),
                  ],
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

class _PermChip extends StatelessWidget {
  final String label;

  const _PermChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.lightBorder.withOpacity(0.5),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label,
          style: const TextStyle(
              fontSize: 10, color: AppColors.lightTextSecondary)),
    );
  }
}

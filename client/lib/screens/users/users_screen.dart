import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/user.dart';
import '../../providers/user_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common_widgets.dart';

class UsersScreen extends ConsumerStatefulWidget {
  const UsersScreen({super.key});

  @override
  ConsumerState<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends ConsumerState<UsersScreen> {
  final _searchController = TextEditingController();
  String _search = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(userNotifierProvider);

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
                    hintText: 'Search users...',
                    onChanged: (v) => setState(() => _search = v),
                  ),
                ),
                const SizedBox(width: 12),
                AppButton(
                  label: 'New User',
                  icon: Icons.person_add_outlined,
                  onPressed: () => context.go('/users/new/edit'),
                ),
              ],
            ),
          ),
          Expanded(
            child: usersAsync.when(
              loading: () => const LoadingList(),
              error: (e, _) => AppErrorWidget(
                  message: e.toString(),
                  onRetry: () =>
                      ref.read(userNotifierProvider.notifier).refresh()),
              data: (users) {
                final filtered = _search.isEmpty
                    ? users
                    : users
                        .where((u) =>
                            u.fullName
                                .toLowerCase()
                                .contains(_search.toLowerCase()) ||
                            u.email
                                .toLowerCase()
                                .contains(_search.toLowerCase()))
                        .toList();

                if (filtered.isEmpty) {
                  return EmptyState(
                    title: 'No users yet',
                    subtitle: 'Add team members to your organization',
                    icon: Icons.people_outline,
                    actionLabel: 'Add User',
                    onAction: () => context.go('/users/new/edit'),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  itemBuilder: (context, i) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _UserCard(
                      user: filtered[i],
                      onEdit: () =>
                          context.go('/users/${filtered[i].id}/edit'),
                      onDelete: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (_) => const ConfirmDialog(
                            title: 'Remove User',
                            message: 'Remove this user from the system?',
                          ),
                        );
                        if (confirmed == true) {
                          await ref
                              .read(userNotifierProvider.notifier)
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

class _UserCard extends StatelessWidget {
  final User user;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _UserCard({
    required this.user,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onEdit,
      child: Row(
        children: [
          AvatarWidget(
            imageUrl: user.avatar,
            initials: user.initials,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.fullName,
                    style: Theme.of(context).textTheme.titleMedium),
                Text(user.email,
                    style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primarySurface,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(user.role,
                          style: const TextStyle(
                              fontSize: 10, color: AppColors.primary)),
                    ),
                    const SizedBox(width: 8),
                    StatusChip(
                        status: user.isActive ? 'active' : 'inactive'),
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
                  child: Text('Remove',
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

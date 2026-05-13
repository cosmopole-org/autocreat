import 'package:data_table_2/data_table_2.dart';
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
  bool _tableView = false;

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
                const SizedBox(width: 8),
                IconButton.outlined(
                  icon: Icon(_tableView
                      ? Icons.view_list_rounded
                      : Icons.table_chart_outlined),
                  tooltip: _tableView ? 'List view' : 'Table view',
                  onPressed: () => setState(() => _tableView = !_tableView),
                ),
                const SizedBox(width: 8),
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

                return _tableView
                    ? _UsersTable(
                        users: filtered,
                        onEdit: (u) => context.go('/users/${u.id}/edit'),
                        onDelete: (u) => _confirmDelete(context, u),
                      )
                    : _UsersList(
                        users: filtered,
                        onEdit: (u) => context.go('/users/${u.id}/edit'),
                        onDelete: (u) => _confirmDelete(context, u),
                      );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, User user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => const ConfirmDialog(
        title: 'Remove User',
        message: 'Remove this user from the system?',
      ),
    );
    if (confirmed == true) {
      await ref.read(userNotifierProvider.notifier).delete(user.id);
    }
  }
}

// ── List View ──────────────────────────────────────────────────

class _UsersList extends StatelessWidget {
  final List<User> users;
  final ValueChanged<User> onEdit;
  final ValueChanged<User> onDelete;

  const _UsersList({
    required this.users,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: users.length,
      itemBuilder: (context, i) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: _UserCard(
          user: users[i],
          onEdit: () => onEdit(users[i]),
          onDelete: () => onDelete(users[i]),
        ).animate().fadeIn(delay: Duration(milliseconds: i * 50)),
      ),
    );
  }
}

// ── Table View ─────────────────────────────────────────────────

class _UsersTable extends StatelessWidget {
  final List<User> users;
  final ValueChanged<User> onEdit;
  final ValueChanged<User> onDelete;

  const _UsersTable({
    required this.users,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: DataTable2(
        columnSpacing: 16,
        horizontalMargin: 12,
        minWidth: 600,
        headingRowColor: WidgetStateProperty.all(
          isDark ? AppColors.darkCard : AppColors.lightBg,
        ),
        headingTextStyle: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
        dataRowColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.hovered)) {
            return AppColors.primary.withOpacity(0.05);
          }
          return null;
        }),
        border: TableBorder.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1,
          borderRadius: BorderRadius.circular(12),
        ),
        columns: const [
          DataColumn2(label: Text('User'), size: ColumnSize.L),
          DataColumn2(label: Text('Email'), size: ColumnSize.M),
          DataColumn2(label: Text('Role'), size: ColumnSize.S),
          DataColumn2(label: Text('Status'), size: ColumnSize.S),
          DataColumn2(label: Text('Actions'), size: ColumnSize.S, numeric: true),
        ],
        rows: users.map((user) {
          return DataRow2(
            cells: [
              DataCell(Row(
                children: [
                  AvatarWidget(
                    imageUrl: user.avatar,
                    initials: user.initials,
                    size: 32,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      user.fullName,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              )),
              DataCell(Text(user.email,
                  style: Theme.of(context).textTheme.bodySmall,
                  overflow: TextOverflow.ellipsis)),
              DataCell(Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(user.role,
                    style:
                        const TextStyle(fontSize: 11, color: AppColors.primary)),
              )),
              DataCell(
                  StatusChip(status: user.isActive ? 'active' : 'inactive')),
              DataCell(Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    onPressed: () => onEdit(user),
                    tooltip: 'Edit',
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(6),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline,
                        size: 18, color: AppColors.error),
                    onPressed: () => onDelete(user),
                    tooltip: 'Remove',
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(6),
                  ),
                ],
              )),
            ],
            onTap: () => onEdit(user),
          );
        }).toList(),
      ),
    );
  }
}

// ── Card (list view) ───────────────────────────────────────────

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
          AvatarWidget(imageUrl: user.avatar, initials: user.initials),
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
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'edit', child: Text('Edit')),
              PopupMenuItem(
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

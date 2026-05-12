import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/ticket.dart';
import '../../providers/ticket_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common_widgets.dart';

class TicketsScreen extends ConsumerStatefulWidget {
  const TicketsScreen({super.key});

  @override
  ConsumerState<TicketsScreen> createState() => _TicketsScreenState();
}

class _TicketsScreenState extends ConsumerState<TicketsScreen>
    with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  String _search = '';
  late TabController _tabController;

  static const _tabs = ['All', 'Open', 'In Progress', 'Resolved', 'Closed'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  TicketStatus? get _selectedStatus {
    switch (_tabController.index) {
      case 1: return TicketStatus.open;
      case 2: return TicketStatus.inProgress;
      case 3: return TicketStatus.resolved;
      case 4: return TicketStatus.closed;
      default: return null;
    }
  }

  void _showCreateTicket(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => _CreateTicketDialog(
        onCreate: (data) async {
          await ref.read(ticketNotifierProvider.notifier).create(data);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ticketsAsync = ref.watch(ticketNotifierProvider);

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: SearchField(
                    controller: _searchController,
                    hintText: 'Search tickets...',
                    onChanged: (v) => setState(() => _search = v),
                  ),
                ),
                const SizedBox(width: 12),
                AppButton(
                  label: 'New Ticket',
                  icon: Icons.add,
                  onPressed: () => _showCreateTicket(context),
                ),
              ],
            ),
          ),
          TabBar(
            controller: _tabController,
            isScrollable: true,
            onTap: (_) => setState(() {}),
            tabs: _tabs.map((t) => Tab(text: t)).toList(),
          ),
          Expanded(
            child: ticketsAsync.when(
              loading: () => const LoadingList(),
              error: (e, _) => AppErrorWidget(message: e.toString()),
              data: (tickets) {
                var filtered = tickets;
                final status = _selectedStatus;
                if (status != null) {
                  filtered = filtered
                      .where((t) => t.status == status)
                      .toList();
                }
                if (_search.isNotEmpty) {
                  filtered = filtered
                      .where((t) => t.title
                          .toLowerCase()
                          .contains(_search.toLowerCase()))
                      .toList();
                }

                if (filtered.isEmpty) {
                  return EmptyState(
                    title: 'No tickets found',
                    subtitle: 'Create a new ticket to start',
                    icon: Icons.support_agent_outlined,
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  itemBuilder: (context, i) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _TicketCard(
                      ticket: filtered[i],
                      onTap: () =>
                          context.go('/tickets/${filtered[i].id}'),
                      onUpdateStatus: (status) async {
                        await ref
                            .read(ticketNotifierProvider.notifier)
                            .updateStatus(filtered[i].id, status);
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

class _TicketCard extends StatelessWidget {
  final Ticket ticket;
  final VoidCallback onTap;
  final ValueChanged<TicketStatus> onUpdateStatus;

  const _TicketCard({
    required this.ticket,
    required this.onTap,
    required this.onUpdateStatus,
  });

  Color _priorityColor() {
    switch (ticket.priority) {
      case TicketPriority.urgent: return AppColors.error;
      case TicketPriority.high: return AppColors.warning;
      case TicketPriority.medium: return AppColors.info;
      case TicketPriority.low: return AppColors.lightTextSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          // Priority indicator
          Container(
            width: 4,
            height: 52,
            decoration: BoxDecoration(
              color: _priorityColor(),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              ticket.isRead
                  ? Icons.confirmation_number_outlined
                  : Icons.confirmation_number,
              color: AppColors.warning,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ticket.title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: ticket.isRead
                            ? FontWeight.w400
                            : FontWeight.w600,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    StatusChip(status: ticket.status.displayName),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _priorityColor().withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        ticket.priority.displayName,
                        style: TextStyle(
                            fontSize: 10, color: _priorityColor()),
                      ),
                    ),
                    if (ticket.messageCount > 0) ...[
                      const SizedBox(width: 8),
                      Row(
                        children: [
                          Icon(Icons.chat_bubble_outline,
                              size: 12,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary),
                          const SizedBox(width: 3),
                          Text('${ticket.messageCount}',
                              style:
                                  const TextStyle(fontSize: 11)),
                        ],
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          PopupMenuButton<TicketStatus>(
            icon: const Icon(Icons.more_vert, size: 18),
            itemBuilder: (_) => TicketStatus.values
                .map((s) => PopupMenuItem(
                      value: s,
                      child: Text(s.displayName),
                    ))
                .toList(),
            onSelected: onUpdateStatus,
          ),
        ],
      ),
    );
  }
}

class _CreateTicketDialog extends StatefulWidget {
  final Future<void> Function(Map<String, dynamic>) onCreate;

  const _CreateTicketDialog({required this.onCreate});

  @override
  State<_CreateTicketDialog> createState() => _CreateTicketDialogState();
}

class _CreateTicketDialogState extends State<_CreateTicketDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  TicketPriority _priority = TicketPriority.medium;
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New Ticket'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title *'),
                validator: (v) =>
                    v?.isEmpty ?? true ? 'Title is required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<TicketPriority>(
                value: _priority,
                items: TicketPriority.values
                    .map((p) => DropdownMenuItem(
                        value: p, child: Text(p.displayName)))
                    .toList(),
                onChanged: (v) => setState(() => _priority = v!),
                decoration:
                    const InputDecoration(labelText: 'Priority'),
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
          label: 'Create',
          loading: _saving,
          onPressed: () async {
            if (!_formKey.currentState!.validate()) return;
            setState(() => _saving = true);
            try {
              await widget.onCreate({
                'title': _titleController.text,
                'description': _descController.text,
                'priority': _priority.name,
                'status': TicketStatus.open.name,
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

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../../core/extensions.dart';
import '../../data/demo_data.dart';
import '../../models/ticket.dart';
import '../../data/demo_overrides.dart';
import '../../providers/auth_provider.dart';
import '../../providers/demo_provider.dart';
import '../../providers/realtime_provider.dart';
import '../../providers/ticket_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common_widgets.dart';
import '../../data/ui_text.dart';

class TicketDetailScreen extends ConsumerStatefulWidget {
  final String ticketId;

  const TicketDetailScreen({super.key, required this.ticketId});

  @override
  ConsumerState<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends ConsumerState<TicketDetailScreen> {
  final _messageController = TextEditingController();
  bool _sending = false;
  final _scrollController = ScrollController();
  String? _attachmentName;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _pickAttachment() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      withData: false,
    );
    if (result != null && result.files.isNotEmpty && mounted) {
      setState(() => _attachmentName = result.files.single.name);
    }
  }

  Future<void> _sendMessage(Ticket ticket) async {
    final content = _messageController.text.trim();
    if (content.isEmpty && _attachmentName == null) return;
    setState(() => _sending = true);
    try {
      final repo = ref.read(ticketRepositoryProvider);
      final attachments = _attachmentName != null ? [_attachmentName!] : null;
      await repo.sendMessage(ticket.id,
          content.isNotEmpty ? content : UiText.attachment, attachments);
      _messageController.clear();
      setState(() => _attachmentName = null);
      ref.invalidate(ticketDetailProvider(ticket.id));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Color _priorityColor(TicketPriority p) {
    switch (p) {
      case TicketPriority.urgent:
        return AppColors.error;
      case TicketPriority.high:
        return AppColors.warning;
      case TicketPriority.medium:
        return AppColors.info;
      case TicketPriority.low:
        return AppColors.lightTextSecondary;
    }
  }

  double _slaProgress(Ticket ticket) {
    if (ticket.dueDate == null || ticket.createdAt == null) return 0.5;
    final now = DateTime.now();
    final total =
        ticket.dueDate!.difference(ticket.createdAt!).inMinutes.toDouble();
    if (total <= 0) return 1.0;
    final elapsed = now.difference(ticket.createdAt!).inMinutes.toDouble();
    return (elapsed / total).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    // Listen to global WS and refresh when a message arrives for this ticket
    ref.listen(realtimeStreamProvider, (prev, next) {
      next.whenData((msg) {
        if (msg['type'] == 'ticket.message_sent' &&
            msg['ticketId'] == widget.ticketId) {
          ref.invalidate(ticketDetailProvider(widget.ticketId));
        }
      });
    });

    final isDemo = ref.watch(isDemoModeProvider);
    final demoTickets = ref.watch(demoTypedTicketsProvider).value ??
        DemoData.tickets.map(Ticket.fromJson).toList();
    final ticketAsync = isDemo
        ? AsyncValue.data(
            demoTickets.firstWhere(
              (t) => t.id == widget.ticketId,
              orElse: () => demoTickets.first,
            ),
          )
        : ref.watch(ticketDetailProvider(widget.ticketId));
    final currentUser = isDemo
        ? ref.watch(demoCurrentUserProvider)
        : ref.watch(currentUserProvider);

    return ticketAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: AppErrorWidget(message: e.toString())),
      data: (ticket) => Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title:
              Text(ticket.title, maxLines: 1, overflow: TextOverflow.ellipsis),
          actions: [
            DropdownButton<TicketStatus>(
              value: ticket.status,
              underline: const SizedBox.shrink(),
              onChanged: (status) {
                if (status != null) {
                  ref
                      .read(ticketNotifierProvider.notifier)
                      .updateStatus(ticket.id, status);
                  ref.invalidate(ticketDetailProvider(ticket.id));
                }
              },
              items: TicketStatus.values
                  .map((s) => DropdownMenuItem(
                        value: s,
                        child: StatusChip(status: s.displayName),
                      ))
                  .toList(),
            ),
            const SizedBox(width: 16),
          ],
        ),
        body: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Message thread
            Expanded(
              flex: 3,
              child: Column(
                children: [
                  Expanded(
                    child: ticket.messages.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.chat_bubble_outline,
                                    size: 48,
                                    color: AppColors.lightTextSecondary),
                                const SizedBox(height: 12),
                                Text(UiText.noMessagesYet,
                                    style: const TextStyle(
                                        color: AppColors.lightTextSecondary)),
                              ],
                            ),
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.all(16),
                            itemCount: ticket.messages.length,
                            itemBuilder: (context, i) => _MessageBubble(
                              message: ticket.messages[i],
                              isOwn: ticket.messages[i].senderId ==
                                  currentUser?.id,
                            )
                                .animate()
                                .fadeIn(delay: Duration(milliseconds: i * 30)),
                          ),
                  ),

                  // Attachment preview strip
                  if (_attachmentName != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      color: AppColors.primarySurface,
                      child: Row(
                        children: [
                          const Icon(Icons.attach_file,
                              size: 16, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _attachmentName!,
                              style: const TextStyle(
                                  fontSize: 12, color: AppColors.primary),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close,
                                size: 16, color: AppColors.primary),
                            onPressed: () =>
                                setState(() => _attachmentName = null),
                            constraints: const BoxConstraints(),
                            padding: const EdgeInsets.all(4),
                          ),
                        ],
                      ),
                    ),

                  // Message input
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? AppColors.darkBorder
                              : AppColors.lightBorder,
                        ),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.attach_file, size: 20),
                          onPressed: _pickAttachment,
                          tooltip: UiText.attachFile,
                          color: _attachmentName != null
                              ? AppColors.primary
                              : null,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: TextField(
                            controller: _messageController,
                            decoration: InputDecoration(
                              hintText: UiText.typeAMessage,
                              border: const OutlineInputBorder(),
                            ),
                            maxLines: 3,
                            minLines: 1,
                            onSubmitted: (_) => _sendMessage(ticket),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            onPressed:
                                _sending ? null : () => _sendMessage(ticket),
                            child: _sending
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white),
                                  )
                                : const Icon(Icons.send),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Ticket info panel
            Container(
              width: 260,
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.darkBorder
                        : AppColors.lightBorder,
                  ),
                ),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(UiText.ticketDetails,
                        style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 16),
                    InfoRow(
                        label: UiText.status,
                        value: ticket.status.displayName),
                    InfoRow(
                        label: UiText.priority,
                        value: ticket.priority.displayName),
                    InfoRow(
                        label: UiText.creator,
                        value: ticket.creatorName ?? ticket.creatorId),
                    if (ticket.assigneeName != null)
                      InfoRow(
                          label: UiText.assignee,
                          value: ticket.assigneeName!),
                    if (ticket.dueDate != null)
                      InfoRow(
                          label: UiText.dueDate,
                          value: ticket.dueDate!.formatted),
                    if (ticket.createdAt != null)
                      InfoRow(
                          label: UiText.created,
                          value: ticket.createdAt!.timeAgo),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 12),

                    // SLA Progress
                    if (ticket.dueDate != null) ...[
                      Text(UiText.slaProgress,
                          style: Theme.of(context).textTheme.labelMedium),
                      const SizedBox(height: 8),
                      Builder(builder: (context) {
                        final sla = _slaProgress(ticket);
                        final slaColor = sla >= 0.9
                            ? AppColors.error
                            : sla >= 0.7
                                ? AppColors.warning
                                : AppColors.success;
                        return LinearPercentIndicator(
                          lineHeight: 8,
                          percent: sla,
                          backgroundColor: slaColor.withValues(alpha: 0.15),
                          progressColor: slaColor,
                          barRadius: const Radius.circular(4),
                          padding: EdgeInsets.zero,
                          animation: true,
                          animationDuration: 800,
                          trailing: Text(
                            UiText.percent(sla),
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: slaColor),
                          ),
                        );
                      }),
                      const SizedBox(height: 12),
                      const Divider(),
                      const SizedBox(height: 12),
                    ],

                    // Priority indicator
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _priorityColor(ticket.priority)
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: _priorityColor(ticket.priority)
                                .withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.flag_outlined,
                              color: _priorityColor(ticket.priority), size: 16),
                          const SizedBox(width: 8),
                          Text(
                            UiText.priorityLabel(
                                ticket.priority.displayName),
                            style: TextStyle(
                                color: _priorityColor(ticket.priority),
                                fontWeight: FontWeight.w600,
                                fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    if (ticket.tags.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(UiText.tags,
                          style: Theme.of(context).textTheme.labelLarge),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: ticket.tags
                            .map((t) =>
                                Chip(label: Text(t), padding: EdgeInsets.zero))
                            .toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final TicketMessage message;
  final bool isOwn;

  const _MessageBubble({required this.message, required this.isOwn});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isOwn ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isOwn) ...[
            AvatarWidget(
              initials:
                  message.senderName != null && message.senderName!.isNotEmpty
                      ? message.senderName![0]
                      : '?',
              size: 32,
              imageUrl: message.senderAvatar,
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isOwn ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!isOwn && message.senderName != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      message.senderName!,
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ),
                if (message.attachments.isNotEmpty) ...[
                  ...message.attachments.map((a) => Container(
                        margin: const EdgeInsets.only(bottom: 4),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isOwn
                              ? AppColors.primary.withValues(alpha: 0.8)
                              : (isDark ? AppColors.darkCard : Colors.white),
                          borderRadius: BorderRadius.circular(8),
                          border: isOwn
                              ? null
                              : Border.all(
                                  color: isDark
                                      ? AppColors.darkBorder
                                      : AppColors.lightBorder),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.attach_file,
                                size: 14,
                                color:
                                    isOwn ? Colors.white : AppColors.primary),
                            const SizedBox(width: 6),
                            Text(
                              a,
                              style: TextStyle(
                                  fontSize: 12,
                                  color:
                                      isOwn ? Colors.white : AppColors.primary),
                            ),
                          ],
                        ),
                      )),
                ],
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isOwn
                        ? AppColors.primary
                        : (isDark ? AppColors.darkCard : Colors.white),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(14),
                      topRight: const Radius.circular(14),
                      bottomLeft: Radius.circular(isOwn ? 14 : 4),
                      bottomRight: Radius.circular(isOwn ? 4 : 14),
                    ),
                    border: isOwn
                        ? null
                        : Border.all(
                            color: isDark
                                ? AppColors.darkBorder
                                : AppColors.lightBorder,
                          ),
                  ),
                  child: Text(
                    message.content,
                    style: TextStyle(
                      color: isOwn
                          ? Colors.white
                          : (isDark ? AppColors.darkText : AppColors.lightText),
                      fontSize: 14,
                    ),
                  ),
                ),
                if (message.createdAt != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      message.createdAt!.timeAgo,
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ),
              ],
            ),
          ),
          if (isOwn) ...[
            const SizedBox(width: 8),
            AvatarWidget(
              initials:
                  message.senderName != null && message.senderName!.isNotEmpty
                      ? message.senderName![0]
                      : '?',
              size: 32,
              imageUrl: message.senderAvatar,
            ),
          ],
        ],
      ),
    );
  }
}

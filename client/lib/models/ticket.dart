import 'package:freezed_annotation/freezed_annotation.dart';
import '../data/mock_ui_text.dart';

part 'ticket.freezed.dart';
part 'ticket.g.dart';

enum TicketPriority { low, medium, high, urgent }
enum TicketStatus { open, inProgress, resolved, closed }

@freezed
class TicketMessage with _$TicketMessage {
  const factory TicketMessage({
    required String id,
    required String ticketId,
    required String senderId,
    String? senderName,
    String? senderAvatar,
    required String content,
    @Default([]) List<String> attachments,
    @Default(false) bool isSystem,
    DateTime? createdAt,
  }) = _TicketMessage;

  factory TicketMessage.fromJson(Map<String, dynamic> json) =>
      _$TicketMessageFromJson(json);
}

@freezed
class Ticket with _$Ticket {
  const factory Ticket({
    required String id,
    required String title,
    String? description,
    String? companyId,
    String? flowId,
    String? flowNodeId,
    required String creatorId,
    String? creatorName,
    String? assigneeId,
    String? assigneeName,
    @Default(TicketStatus.open) TicketStatus status,
    @Default(TicketPriority.medium) TicketPriority priority,
    @Default([]) List<String> tags,
    @Default([]) List<TicketMessage> messages,
    @Default(0) int messageCount,
    @Default(false) bool isRead,
    DateTime? dueDate,
    DateTime? resolvedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _Ticket;

  factory Ticket.fromJson(Map<String, dynamic> json) =>
      _$TicketFromJson(json);
}

extension TicketStatusExt on TicketStatus {
  String get displayName {
    switch (this) {
      case TicketStatus.open: return MockUiText.open;
      case TicketStatus.inProgress: return MockUiText.inProgress;
      case TicketStatus.resolved: return MockUiText.resolved;
      case TicketStatus.closed: return MockUiText.closed;
    }
  }
}

extension TicketPriorityExt on TicketPriority {
  String get displayName {
    switch (this) {
      case TicketPriority.low: return MockUiText.low;
      case TicketPriority.medium: return MockUiText.medium;
      case TicketPriority.high: return MockUiText.high;
      case TicketPriority.urgent: return MockUiText.urgent;
    }
  }
}

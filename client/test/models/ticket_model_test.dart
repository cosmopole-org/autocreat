import 'package:flutter_test/flutter_test.dart';
import 'package:autocreat/models/ticket.dart';

void main() {
  group('TicketStatus', () {
    test('displayName for open', () {
      expect(TicketStatus.open.displayName.isNotEmpty, isTrue);
    });

    test('displayName for inProgress', () {
      expect(TicketStatus.inProgress.displayName.isNotEmpty, isTrue);
    });

    test('displayName for resolved', () {
      expect(TicketStatus.resolved.displayName.isNotEmpty, isTrue);
    });

    test('displayName for closed', () {
      expect(TicketStatus.closed.displayName.isNotEmpty, isTrue);
    });

    test('all status values are distinct', () {
      final names = TicketStatus.values.map((s) => s.name).toList();
      expect(names.toSet().length, names.length);
    });
  });

  group('TicketPriority', () {
    test('displayName for low', () {
      expect(TicketPriority.low.displayName.isNotEmpty, isTrue);
    });

    test('displayName for medium', () {
      expect(TicketPriority.medium.displayName.isNotEmpty, isTrue);
    });

    test('displayName for high', () {
      expect(TicketPriority.high.displayName.isNotEmpty, isTrue);
    });

    test('displayName for urgent', () {
      expect(TicketPriority.urgent.displayName.isNotEmpty, isTrue);
    });

    test('all priority values are distinct', () {
      final names = TicketPriority.values.map((p) => p.name).toList();
      expect(names.toSet().length, names.length);
    });
  });

  group('Ticket model', () {
    test('Ticket.fromJson parses status correctly', () {
      final json = {
        'id': 'ticket-1',
        'title': 'Test Ticket',
        'creatorId': 'user-1',
        'status': 'open',
        'priority': 'medium',
        'tags': <String>[],
        'messages': <Map<String, dynamic>>[],
        'messageCount': 0,
        'isRead': false,
      };
      final ticket = Ticket.fromJson(json);
      expect(ticket.id, 'ticket-1');
      expect(ticket.title, 'Test Ticket');
      expect(ticket.status, TicketStatus.open);
      expect(ticket.priority, TicketPriority.medium);
    });

    test('Ticket default status is open', () {
      const ticket = Ticket(
        id: 'id',
        title: 'My Ticket',
        creatorId: 'user-1',
      );
      expect(ticket.status, TicketStatus.open);
    });

    test('Ticket default priority is medium', () {
      const ticket = Ticket(
        id: 'id',
        title: 'My Ticket',
        creatorId: 'user-1',
      );
      expect(ticket.priority, TicketPriority.medium);
    });

    test('Ticket default isRead is false', () {
      const ticket = Ticket(
        id: 'id',
        title: 'My Ticket',
        creatorId: 'user-1',
      );
      expect(ticket.isRead, isFalse);
    });

    test('Ticket default messageCount is 0', () {
      const ticket = Ticket(
        id: 'id',
        title: 'My Ticket',
        creatorId: 'user-1',
      );
      expect(ticket.messageCount, 0);
    });

    test('Ticket.fromJson with all fields', () {
      final dueDate = DateTime(2024, 12, 31);
      final json = {
        'id': 'ticket-full',
        'title': 'Full Ticket',
        'description': 'A detailed description',
        'companyId': 'company-1',
        'creatorId': 'user-creator',
        'assigneeId': 'user-assignee',
        'creatorName': 'John Creator',
        'assigneeName': 'Jane Assignee',
        'status': 'inProgress',
        'priority': 'high',
        'tags': ['bug', 'critical'],
        'messages': <Map<String, dynamic>>[],
        'messageCount': 3,
        'isRead': true,
        'dueDate': dueDate.toIso8601String(),
      };
      final ticket = Ticket.fromJson(json);
      expect(ticket.status, TicketStatus.inProgress);
      expect(ticket.priority, TicketPriority.high);
      expect(ticket.tags, contains('bug'));
      expect(ticket.messageCount, 3);
      expect(ticket.isRead, isTrue);
      expect(ticket.assigneeId, 'user-assignee');
    });
  });

  group('TicketMessage model', () {
    test('TicketMessage.fromJson parses correctly', () {
      final json = {
        'id': 'msg-1',
        'ticketId': 'ticket-1',
        'senderId': 'user-1',
        'content': 'Hello there',
        'attachments': <String>[],
        'isSystem': false,
      };
      final msg = TicketMessage.fromJson(json);
      expect(msg.id, 'msg-1');
      expect(msg.content, 'Hello there');
      expect(msg.isSystem, isFalse);
    });

    test('TicketMessage defaults isSystem to false', () {
      const msg = TicketMessage(
        id: 'id',
        ticketId: 'ticket-id',
        senderId: 'user-id',
        content: 'test',
      );
      expect(msg.isSystem, isFalse);
    });
  });
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/ticket_repository.dart';
import '../models/ticket.dart';
import 'auth_provider.dart';

final ticketRepositoryProvider = Provider<TicketRepository>((ref) {
  return TicketRepository(ref.watch(apiClientProvider));
});

final ticketsProvider =
    FutureProvider.family<List<Ticket>, String?>((ref, companyId) async {
  return ref.watch(ticketRepositoryProvider).getTickets(companyId: companyId);
});

final ticketDetailProvider =
    FutureProvider.family<Ticket, String>((ref, id) async {
  return ref.watch(ticketRepositoryProvider).getTicket(id);
});

class TicketNotifier extends AsyncNotifier<List<Ticket>> {
  @override
  Future<List<Ticket>> build() async {
    return ref.watch(ticketRepositoryProvider).getTickets();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
        () => ref.read(ticketRepositoryProvider).getTickets());
  }

  Future<Ticket> create(Map<String, dynamic> data) async {
    final ticket =
        await ref.read(ticketRepositoryProvider).createTicket(data);
    final current = state.valueOrNull ?? [];
    state = AsyncValue.data([...current, ticket]);
    return ticket;
  }

  Future<Ticket> updateStatus(String id, TicketStatus status) async {
    final ticket =
        await ref.read(ticketRepositoryProvider).updateStatus(id, status);
    final current = state.valueOrNull ?? [];
    state = AsyncValue.data(
        current.map((t) => t.id == id ? ticket : t).toList());
    return ticket;
  }
}

final ticketNotifierProvider =
    AsyncNotifierProvider<TicketNotifier, List<Ticket>>(TicketNotifier.new);

final unreadTicketCountProvider = Provider<int>((ref) {
  return ref.watch(ticketNotifierProvider).maybeWhen(
    data: (tickets) => tickets.where((t) => !t.isRead).length,
    orElse: () => 0,
  );
});

import 'package:dio/dio.dart';
import '../../core/constants.dart';
import '../../models/ticket.dart';
import '../api_client.dart';

class TicketRepository {
  final ApiClient _apiClient;

  TicketRepository(this._apiClient);

  Future<List<Ticket>> getTickets({
    String? companyId,
    String? status,
    String? assigneeId,
  }) async {
    try {
      final response = await _apiClient.get(
        AppConstants.ticketsEndpoint,
        queryParameters: {
          if (companyId != null) 'companyId': companyId,
          if (status != null) 'status': status,
          if (assigneeId != null) 'assigneeId': assigneeId,
        },
      );
      final list = response.data as List<dynamic>;
      return list
          .map((e) => Ticket.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Ticket> getTicket(String id) async {
    try {
      final response =
          await _apiClient.get('${AppConstants.ticketsEndpoint}/$id');
      return Ticket.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Ticket> createTicket(Map<String, dynamic> data) async {
    try {
      final response =
          await _apiClient.post(AppConstants.ticketsEndpoint, data: data);
      return Ticket.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Ticket> updateTicket(String id, Map<String, dynamic> data) async {
    try {
      final response = await _apiClient
          .put('${AppConstants.ticketsEndpoint}/$id', data: data);
      return Ticket.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<TicketMessage> sendMessage(
      String ticketId, String content, List<String>? attachments) async {
    try {
      final response = await _apiClient.post(
        '${AppConstants.ticketsEndpoint}/$ticketId/messages',
        data: {
          'content': content,
          if (attachments != null) 'attachments': attachments,
        },
      );
      return TicketMessage.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Ticket> updateStatus(String id, TicketStatus status) async {
    try {
      final response = await _apiClient.patch(
        '${AppConstants.ticketsEndpoint}/$id/status',
        data: {'status': status.name},
      );
      return Ticket.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}

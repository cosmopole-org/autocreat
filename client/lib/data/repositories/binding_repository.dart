import 'package:dio/dio.dart';
import '../../models/binding.dart';
import '../api_client.dart';

class BindingRepository {
  final ApiClient _apiClient;

  BindingRepository(this._apiClient);

  // ---------- Form-Model Bindings ----------

  Future<List<FormModelBinding>> getNodeBindings(String nodeId) async {
    try {
      final response = await _apiClient.get('/nodes/$nodeId/bindings');
      final list = response.data as List<dynamic>;
      return list
          .whereType<Map<String, dynamic>>()
          .map(FormModelBinding.fromJson)
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<FormModelBinding> saveBinding(
      String nodeId, FormModelBinding binding) async {
    try {
      final response = await _apiClient.post(
        '/nodes/$nodeId/bindings',
        data: binding.toJson(),
      );
      return FormModelBinding.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> deleteBinding(String id) async {
    try {
      await _apiClient.delete('/bindings/$id');
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  // ---------- Node Letter Assignments ----------

  Future<List<NodeLetterAssignment>> getNodeLetterAssignments(
      String nodeId) async {
    try {
      final response =
          await _apiClient.get('/nodes/$nodeId/letter-assignments');
      final list = response.data as List<dynamic>;
      return list
          .whereType<Map<String, dynamic>>()
          .map(NodeLetterAssignment.fromJson)
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<NodeLetterAssignment> saveNodeLetterAssignment(
      String nodeId, NodeLetterAssignment assignment) async {
    try {
      final response = await _apiClient.post(
        '/nodes/$nodeId/letter-assignments',
        data: assignment.toJson(),
      );
      return NodeLetterAssignment.fromJson(
          response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> deleteNodeLetterAssignment(String id) async {
    try {
      await _apiClient.delete('/letter-assignments/$id');
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  // ---------- Step Letter Generation ----------

  Future<StepGeneratedLetter> generateLetterForStep({
    required String instanceId,
    required String stepId,
    required String assignmentId,
    String trigger = 'manual',
  }) async {
    try {
      final response = await _apiClient.post(
        '/instances/$instanceId/steps/$stepId/generate-letter',
        data: {
          'assignmentId': assignmentId,
          'trigger': trigger,
        },
      );
      return StepGeneratedLetter.fromJson(
          response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<List<StepGeneratedLetter>> getGeneratedLettersForStep({
    required String instanceId,
    required String stepId,
  }) async {
    try {
      final response = await _apiClient
          .get('/instances/$instanceId/steps/$stepId/generated-letters');
      final list = response.data as List<dynamic>;
      return list
          .whereType<Map<String, dynamic>>()
          .map(StepGeneratedLetter.fromJson)
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<List<AccessibleNodeFields>> getAccessibleFormFields(String nodeId) async {
    try {
      final response = await _apiClient.get('/nodes/$nodeId/accessible-form-fields');
      final list = response.data as List<dynamic>;
      return list
          .whereType<Map<String, dynamic>>()
          .map(AccessibleNodeFields.fromJson)
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}

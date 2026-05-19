class AppConstants {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8081',
  );
  static const String apiPrefix = '/api/v1';
  static const String fullBaseUrl = baseUrl + apiPrefix;

  static const String loginEndpoint = '/auth/login';
  static const String registerEndpoint = '/auth/register';
  static const String meEndpoint = '/auth/me';
  static const String refreshEndpoint = '/auth/refresh';
  static const String logoutEndpoint = '/auth/logout';

  static const String companiesEndpoint = '/companies';
  static const String flowsEndpoint = '/flows';
  static const String formsEndpoint = '/forms';
  static const String modelsEndpoint = '/models';
  static const String rolesEndpoint = '/roles';
  static const String usersEndpoint = '/users';
  static const String lettersEndpoint = '/letters';
  static const String ticketsEndpoint = '/tickets';
  static const String instancesEndpoint = '/instances';
  static const String myTasksEndpoint = '/instances/my-tasks';

  // Node-scoped binding endpoints (prefix with /nodes/:nodeId)
  static const String nodeBindingsSuffix = '/bindings';
  static const String nodeLetterAssignmentsSuffix = '/letter-assignments';

  // Step-scoped letter endpoints (prefix with /instances/:id/steps/:stepId)
  static const String generateLetterSuffix = '/generate-letter';
  static const String generatedLettersSuffix = '/generated-letters';

  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userIdKey = 'user_id';
}

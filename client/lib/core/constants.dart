class AppConstants {
  // API base URL — overridden at build time via:
  //   flutter build ... --dart-define=API_BASE_URL=https://your-api.example.com
  // Local dev defaults to the Go server's local install port (8081).
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8081',
  );
  static const String apiPrefix = '/api/v1';
  static const String fullBaseUrl = baseUrl + apiPrefix;

  // Auth endpoints
  static const String loginEndpoint = '/auth/login';
  static const String registerEndpoint = '/auth/register';
  static const String meEndpoint = '/auth/me';
  static const String refreshEndpoint = '/auth/refresh';
  static const String logoutEndpoint = '/auth/logout';

  // Resource endpoints
  static const String companiesEndpoint = '/companies';
  static const String flowsEndpoint = '/flows';
  static const String formsEndpoint = '/forms';
  static const String modelsEndpoint = '/models';
  static const String rolesEndpoint = '/roles';
  static const String usersEndpoint = '/users';
  static const String lettersEndpoint = '/letters';
  static const String ticketsEndpoint = '/tickets';

  // WebSocket — derived from baseUrl so https→wss and http→ws stay in sync.
  static String get wsBaseUrl {
    if (baseUrl.startsWith('https://')) {
      return 'wss://${baseUrl.substring('https://'.length)}';
    }
    if (baseUrl.startsWith('http://')) {
      return 'ws://${baseUrl.substring('http://'.length)}';
    }
    return baseUrl;
  }

  static const String wsRealtimeEndpoint = '/api/v1/realtime/ws';

  // Storage keys
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userIdKey = 'user_id';
  static const String themeKey = 'theme_mode';
  static const String glassModeKey = 'glass_mode';
  static const String languageKey = 'language_code';
  static const String lastCompanyKey = 'last_company_id';

  // App info
  static const String appName = 'AutoCreat';
  static const String appVersion = '1.0.0';
}

class AppRoutes {
  static const String login = '/login';
  static const String register = '/register';
  static const String dashboard = '/dashboard';
  static const String companies = '/companies';
  static const String companyDetail = '/companies/:id';
  static const String flows = '/flows';
  static const String flowEditor = '/flows/:id/edit';
  static const String forms = '/forms';
  static const String formEditor = '/forms/:id/edit';
  static const String models = '/models';
  static const String modelEditor = '/models/:id/edit';
  static const String roles = '/roles';
  static const String roleEditor = '/roles/:id/edit';
  static const String users = '/users';
  static const String userEditor = '/users/:id/edit';
  static const String letters = '/letters';
  static const String letterEditor = '/letters/:id/edit';
  static const String tickets = '/tickets';
  static const String ticketDetail = '/tickets/:id';
  static const String settings = '/settings';
}

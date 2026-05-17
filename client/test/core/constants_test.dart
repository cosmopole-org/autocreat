import 'package:flutter_test/flutter_test.dart';
import 'package:autocreat/core/constants.dart';

void main() {
  group('AppConstants', () {
    test('baseUrl is not empty', () {
      expect(AppConstants.baseUrl.isNotEmpty, isTrue);
    });

    test('fullBaseUrl combines base and prefix', () {
      expect(AppConstants.fullBaseUrl,
          '${AppConstants.baseUrl}${AppConstants.apiPrefix}');
    });

    test('storage keys are unique', () {
      final keys = [
        AppConstants.accessTokenKey,
        AppConstants.refreshTokenKey,
        AppConstants.userIdKey,
        AppConstants.themeKey,
        AppConstants.glassModeKey,
        AppConstants.languageKey,
        AppConstants.lastCompanyKey,
      ];
      final uniqueKeys = keys.toSet();
      expect(uniqueKeys.length, keys.length, reason: 'All storage keys must be unique');
    });

    test('auth endpoints start with slash', () {
      expect(AppConstants.loginEndpoint.startsWith('/'), isTrue);
      expect(AppConstants.registerEndpoint.startsWith('/'), isTrue);
      expect(AppConstants.meEndpoint.startsWith('/'), isTrue);
      expect(AppConstants.refreshEndpoint.startsWith('/'), isTrue);
      expect(AppConstants.logoutEndpoint.startsWith('/'), isTrue);
    });

    test('resource endpoints start with slash', () {
      expect(AppConstants.companiesEndpoint.startsWith('/'), isTrue);
      expect(AppConstants.flowsEndpoint.startsWith('/'), isTrue);
      expect(AppConstants.formsEndpoint.startsWith('/'), isTrue);
      expect(AppConstants.rolesEndpoint.startsWith('/'), isTrue);
      expect(AppConstants.usersEndpoint.startsWith('/'), isTrue);
      expect(AppConstants.ticketsEndpoint.startsWith('/'), isTrue);
    });

    test('appName is AutoCreat', () {
      expect(AppConstants.appName, 'AutoCreat');
    });

    test('wsBaseUrl starts with wss://', () {
      expect(AppConstants.wsBaseUrl.startsWith('wss://'), isTrue);
    });
  });

  group('AppRoutes', () {
    test('all routes start with slash', () {
      final routes = [
        AppRoutes.login,
        AppRoutes.register,
        AppRoutes.dashboard,
        AppRoutes.companies,
        AppRoutes.flows,
        AppRoutes.forms,
        AppRoutes.models,
        AppRoutes.roles,
        AppRoutes.users,
        AppRoutes.letters,
        AppRoutes.tickets,
        AppRoutes.settings,
      ];
      for (final route in routes) {
        expect(route.startsWith('/'), isTrue, reason: '$route should start with /');
      }
    });

    test('routes with id params contain :id', () {
      expect(AppRoutes.companyDetail.contains(':id'), isTrue);
      expect(AppRoutes.flowEditor.contains(':id'), isTrue);
      expect(AppRoutes.formEditor.contains(':id'), isTrue);
      expect(AppRoutes.ticketDetail.contains(':id'), isTrue);
    });

    test('login route is /login', () {
      expect(AppRoutes.login, '/login');
    });

    test('dashboard route is /dashboard', () {
      expect(AppRoutes.dashboard, '/dashboard');
    });
  });
}

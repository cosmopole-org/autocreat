import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/constants.dart';
import '../providers/auth_provider.dart';
import '../providers/demo_provider.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/companies/companies_screen.dart';
import '../screens/companies/company_detail_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/flows/flow_editor_screen.dart';
import '../screens/flows/flows_screen.dart';
import '../screens/forms/form_editor_screen.dart';
import '../screens/forms/forms_screen.dart';
import '../screens/letters/letter_editor_screen.dart';
import '../screens/letters/letters_screen.dart';
import '../screens/models/model_editor_screen.dart';
import '../screens/models/models_screen.dart';
import '../screens/roles/role_editor_screen.dart';
import '../screens/roles/roles_screen.dart';
import '../screens/tickets/ticket_detail_screen.dart';
import '../screens/tickets/tickets_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/users/user_editor_screen.dart';
import '../screens/users/users_screen.dart';
import '../widgets/responsive_shell.dart';
import '../widgets/secondary_page_wrapper.dart';

// Notifies GoRouter to re-evaluate its redirect whenever auth or demo state
// changes, without recreating the GoRouter instance itself.
class _RouterNotifier extends ChangeNotifier {
  _RouterNotifier(Ref ref) {
    ref.listen<AsyncValue<dynamic>>(authProvider, (_, __) => notifyListeners());
    ref.listen<bool>(isDemoModeProvider, (_, __) => notifyListeners());
  }
}

Page<void> _buildSecondaryPage(BuildContext context, GoRouterState state, Widget child) {
  final width = MediaQuery.of(context).size.width;
  final isMobile = width < 768;
  final wrapped = SecondaryPageWrapper(child: child);

  if (isMobile) {
    return MaterialPage(key: state.pageKey, child: wrapped);
  }

  return CustomTransitionPage(
    key: state.pageKey,
    opaque: false,
    barrierColor: Colors.black.withValues(alpha: 0.54),
    child: wrapped,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final fadeAnim = CurvedAnimation(parent: animation, curve: Curves.easeOut);
      final slideAnim = Tween<Offset>(
        begin: const Offset(0, 0.05),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));
      return FadeTransition(
        opacity: fadeAnim,
        child: SlideTransition(position: slideAnim, child: child),
      );
    },
  );
}

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = _RouterNotifier(ref);
  ref.onDispose(notifier.dispose);

  return GoRouter(
    initialLocation: AppRoutes.dashboard,
    refreshListenable: notifier,
    redirect: (context, state) {
      // Read current state at redirect time — not captured at router creation.
      final authState = ref.read(authProvider);
      final isDemoMode = ref.read(isDemoModeProvider);

      final isAuthenticated = authState.maybeWhen(
        data: (user) => user != null,
        orElse: () => false,
      );
      final isLoading = authState.isLoading;

      if (isLoading) return null;

      final isAuthRoute = state.matchedLocation == AppRoutes.login ||
          state.matchedLocation == AppRoutes.register;

      if (!isAuthenticated && !isDemoMode && !isAuthRoute) {
        return AppRoutes.login;
      }
      if ((isAuthenticated || isDemoMode) && isAuthRoute) {
        return AppRoutes.dashboard;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => ResponsiveShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.dashboard,
            name: 'dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: AppRoutes.flows,
            name: 'flows',
            builder: (context, state) => const FlowsScreen(),
          ),
          GoRoute(
            path: AppRoutes.forms,
            name: 'forms',
            builder: (context, state) => const FormsScreen(),
          ),
          GoRoute(
            path: AppRoutes.models,
            name: 'models',
            builder: (context, state) => const ModelsScreen(),
          ),
          GoRoute(
            path: AppRoutes.roles,
            name: 'roles',
            builder: (context, state) => const RolesScreen(),
          ),
          GoRoute(
            path: AppRoutes.users,
            name: 'users',
            builder: (context, state) => const UsersScreen(),
          ),
          GoRoute(
            path: AppRoutes.letters,
            name: 'letters',
            builder: (context, state) => const LettersScreen(),
          ),
          GoRoute(
            path: AppRoutes.tickets,
            name: 'tickets',
            builder: (context, state) => const TicketsScreen(),
          ),
          GoRoute(
            path: AppRoutes.settings,
            name: 'settings',
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
      // SECONDARY ROUTES - outside shell, with modal/fullscreen behavior
      GoRoute(
        path: AppRoutes.companies,
        name: 'companies',
        pageBuilder: (context, state) => _buildSecondaryPage(
          context,
          state,
          const CompaniesScreen(),
        ),
      ),
      GoRoute(
        path: '/companies/:id',
        name: 'company-detail',
        pageBuilder: (context, state) => _buildSecondaryPage(
          context,
          state,
          CompanyDetailScreen(id: state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: '/flows/:id/edit',
        name: 'flow-editor',
        pageBuilder: (context, state) => _buildSecondaryPage(
          context,
          state,
          FlowEditorScreen(flowId: state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: '/forms/:id/edit',
        name: 'form-editor',
        pageBuilder: (context, state) => _buildSecondaryPage(
          context,
          state,
          FormEditorScreen(formId: state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: '/models/:id/edit',
        name: 'model-editor',
        pageBuilder: (context, state) => _buildSecondaryPage(
          context,
          state,
          ModelEditorScreen(modelId: state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: '/roles/:id/edit',
        name: 'role-editor',
        pageBuilder: (context, state) => _buildSecondaryPage(
          context,
          state,
          RoleEditorScreen(roleId: state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: '/users/:id/edit',
        name: 'user-editor',
        pageBuilder: (context, state) => _buildSecondaryPage(
          context,
          state,
          UserEditorScreen(userId: state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: '/letters/:id/edit',
        name: 'letter-editor',
        pageBuilder: (context, state) => _buildSecondaryPage(
          context,
          state,
          LetterEditorScreen(letterId: state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: '/tickets/:id',
        name: 'ticket-detail',
        pageBuilder: (context, state) => _buildSecondaryPage(
          context,
          state,
          TicketDetailScreen(ticketId: state.pathParameters['id']!),
        ),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Page not found', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(state.error.toString()),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go(AppRoutes.dashboard),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    ),
  );
});

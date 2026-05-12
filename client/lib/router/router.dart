import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/constants.dart';
import '../providers/auth_provider.dart';
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
import '../screens/users/user_editor_screen.dart';
import '../screens/users/users_screen.dart';
import '../widgets/responsive_shell.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: AppRoutes.dashboard,
    redirect: (context, state) {
      final isAuthenticated = authState.maybeWhen(
        data: (user) => user != null,
        orElse: () => false,
      );
      final isLoading = authState.isLoading;

      if (isLoading) return null;

      final isAuthRoute = state.matchedLocation == AppRoutes.login ||
          state.matchedLocation == AppRoutes.register;

      if (!isAuthenticated && !isAuthRoute) {
        return AppRoutes.login;
      }
      if (isAuthenticated && isAuthRoute) {
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
            path: AppRoutes.companies,
            name: 'companies',
            builder: (context, state) => const CompaniesScreen(),
            routes: [
              GoRoute(
                path: ':id',
                name: 'company-detail',
                builder: (context, state) =>
                    CompanyDetailScreen(id: state.pathParameters['id']!),
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.flows,
            name: 'flows',
            builder: (context, state) => const FlowsScreen(),
          ),
          GoRoute(
            path: '/flows/:id/edit',
            name: 'flow-editor',
            builder: (context, state) =>
                FlowEditorScreen(flowId: state.pathParameters['id']!),
          ),
          GoRoute(
            path: AppRoutes.forms,
            name: 'forms',
            builder: (context, state) => const FormsScreen(),
          ),
          GoRoute(
            path: '/forms/:id/edit',
            name: 'form-editor',
            builder: (context, state) =>
                FormEditorScreen(formId: state.pathParameters['id']!),
          ),
          GoRoute(
            path: AppRoutes.models,
            name: 'models',
            builder: (context, state) => const ModelsScreen(),
          ),
          GoRoute(
            path: '/models/:id/edit',
            name: 'model-editor',
            builder: (context, state) =>
                ModelEditorScreen(modelId: state.pathParameters['id']!),
          ),
          GoRoute(
            path: AppRoutes.roles,
            name: 'roles',
            builder: (context, state) => const RolesScreen(),
          ),
          GoRoute(
            path: '/roles/:id/edit',
            name: 'role-editor',
            builder: (context, state) =>
                RoleEditorScreen(roleId: state.pathParameters['id']!),
          ),
          GoRoute(
            path: AppRoutes.users,
            name: 'users',
            builder: (context, state) => const UsersScreen(),
          ),
          GoRoute(
            path: '/users/:id/edit',
            name: 'user-editor',
            builder: (context, state) =>
                UserEditorScreen(userId: state.pathParameters['id']!),
          ),
          GoRoute(
            path: AppRoutes.letters,
            name: 'letters',
            builder: (context, state) => const LettersScreen(),
          ),
          GoRoute(
            path: '/letters/:id/edit',
            name: 'letter-editor',
            builder: (context, state) =>
                LetterEditorScreen(letterId: state.pathParameters['id']!),
          ),
          GoRoute(
            path: AppRoutes.tickets,
            name: 'tickets',
            builder: (context, state) => const TicketsScreen(),
          ),
          GoRoute(
            path: '/tickets/:id',
            name: 'ticket-detail',
            builder: (context, state) =>
                TicketDetailScreen(ticketId: state.pathParameters['id']!),
          ),
        ],
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

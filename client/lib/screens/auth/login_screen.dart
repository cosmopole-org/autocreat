import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants.dart';
import '../../providers/auth_provider.dart';
import '../../providers/demo_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common_widgets.dart';
import '../../data/mock_ui_text.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  static const _demoAccounts = [
    {'email': 'demo@autocreat.io', 'password': MockUiText.demo123, 'label': MockUiText.demo},
    {'email': 'admin@demo.com', 'password': 'password123', 'label': MockUiText.admin},
  ];

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await ref.read(authProvider.notifier).login(
            _emailController.text.trim(),
            _passwordController.text,
          );
    } catch (e) {
      setState(() => _errorMessage = e.toString().replaceAll(MockUiText.exception, ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _fillDemo(Map<String, String> account) {
    _emailController.text = account['email']!;
    _passwordController.text = account['password']!;
  }

  /// Activates client-side demo mode without any network call.
  ///
  /// Sets [isDemoModeProvider] to `true` and injects a synthetic demo user
  /// into [authProvider].  The router sees both flags and redirects straight
  /// to the dashboard, skipping the real login flow entirely.
  void _enterDemoMode() {
    ref.read(isDemoModeProvider.notifier).state = true;
    ref.read(authProvider.notifier).loginAsDemoUser();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width > 900;

    if (isDesktop) {
      return Scaffold(
        body: Row(
          children: [
            Expanded(child: _LeftPanel()),
            Expanded(child: _buildForm(context)),
          ],
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 40),
                _buildHeader(context),
                const SizedBox(height: 32),
                _buildFormContent(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(48),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(context),
                const SizedBox(height: 32),
                _buildFormContent(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.auto_awesome, color: AppColors.primary, size: 28),
            ),
            const SizedBox(width: 12),
            Text(
              MockUiText.autocreat,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ],
        ).animate().fadeIn(duration: 500.ms),
        const SizedBox(height: 20),
        Text(
          MockUiText.welcomeBack,
          style: Theme.of(context).textTheme.headlineSmall,
        ).animate().fadeIn(delay: 100.ms, duration: 400.ms),
        const SizedBox(height: 6),
        Text(
          MockUiText.signInToYourOrganizationAccount,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.lightTextSecondary,
              ),
        ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
      ],
    );
  }

  Widget _buildFormContent(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Demo chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _demoAccounts
                .map((a) => ActionChip(
                      label: Text(MockUiText.demoAccountLabel(a['label'] as String)),
                      avatar: const Icon(Icons.person_outline, size: 14),
                      onPressed: () => _fillDemo(
                          Map<String, String>.from(a)),
                    ))
                .toList(),
          ).animate().fadeIn(delay: 300.ms, duration: 400.ms),
          const SizedBox(height: 24),

          // Error message
          if (_errorMessage != null)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline,
                      color: AppColors.error, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(
                          color: AppColors.error, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ).animate().shake(duration: 400.ms).fadeIn(),

          // Email
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: MockUiText.emailAddress,
              prefixIcon: Icon(Icons.email_outlined, size: 20),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return MockUiText.emailIsRequired;
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                  .hasMatch(v)) {
                return MockUiText.invalidEmail;
              }
              return null;
            },
          ).animate().fadeIn(delay: 400.ms, duration: 400.ms).slideY(begin: 0.1),
          const SizedBox(height: 16),

          // Password
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: MockUiText.password,
              prefixIcon: const Icon(Icons.lock_outline, size: 20),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: 20,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return MockUiText.passwordIsRequired;
              if (v.length < 6) return MockUiText.passwordTooShort;
              return null;
            },
            onFieldSubmitted: (_) => _login(),
          ).animate().fadeIn(delay: 500.ms, duration: 400.ms).slideY(begin: 0.1),
          const SizedBox(height: 8),

          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {},
              child: Text(MockUiText.forgotPassword),
            ),
          ),
          const SizedBox(height: 20),

          // ── Try Demo Mode button ────────────────────────────────
          _DemoModeButton(onPressed: _enterDemoMode)
              .animate()
              .fadeIn(delay: 580.ms, duration: 400.ms)
              .slideY(begin: 0.1),
          const SizedBox(height: 12),

          AppButton(
            label: MockUiText.signIn3,
            onPressed: _login,
            loading: _isLoading,
            icon: Icons.login,
            width: double.infinity,
          ).animate().fadeIn(delay: 640.ms, duration: 400.ms).slideY(begin: 0.1),
          const SizedBox(height: 20),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                MockUiText.donTHaveAnAccount,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              TextButton(
                onPressed: () => context.go(AppRoutes.register),
                child: Text(MockUiText.createAccount3),
              ),
            ],
          ).animate().fadeIn(delay: 700.ms, duration: 400.ms),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DEMO MODE BUTTON
// ─────────────────────────────────────────────────────────────────────────────

/// A visually distinct card-style button that enters client-side demo mode.
///
/// Uses a gradient matching the app accent palette and a subtle MockUiText.demo3 badge
/// to make it clear no account is needed.
class _DemoModeButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _DemoModeButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF6C63FF), Color(0xFF48CAE4)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6C63FF).withValues(alpha: 0.35),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            // Eye icon
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.visibility_outlined,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    MockUiText.tryDemoMode,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.1,
                    ),
                  ),
                  Text(
                    MockUiText.noAccountNeededExploreWithSampleData,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            // MockUiText.demo3 badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white38),
              ),
              child: const Text(
                MockUiText.demo3,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LeftPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primaryDark, AppColors.primary, AppColors.primaryLight],
        ),
      ),
      padding: const EdgeInsets.all(48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.auto_awesome, color: Colors.white, size: 48)
              .animate()
              .fadeIn(duration: 600.ms)
              .scale(begin: const Offset(0.5, 0.5)),
          const SizedBox(height: 24),
          Text(
            MockUiText.autocreat,
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
          ).animate().fadeIn(delay: 200.ms, duration: 600.ms).slideX(begin: -0.1),
          const SizedBox(height: 16),
          Text(
            MockUiText.organizationalSystemBuilder,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white.withValues(alpha: 0.85),
                ),
          ).animate().fadeIn(delay: 300.ms, duration: 600.ms).slideX(begin: -0.1),
          const SizedBox(height: 40),
          ...[
            (MockUiText.designComplexOrganizationalFlows, Icons.account_tree_outlined),
            (MockUiText.buildFormsAndDataModels, Icons.dynamic_form_outlined),
            (MockUiText.manageRolesAndPermissions, Icons.shield_outlined),
            (MockUiText.communicateViaTickets, Icons.support_agent_outlined),
          ]
              .asMap()
              .entries
              .map(
                (e) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(e.value.$2, color: Colors.white, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        e.value.$1,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 14),
                      ),
                    ],
                  ).animate().fadeIn(
                      delay: Duration(milliseconds: 400 + e.key * 100),
                      duration: 400.ms),
                ),
              ),
        ],
      ),
    );
  }
}

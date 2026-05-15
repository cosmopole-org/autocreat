import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants.dart';
import '../../data/ui_text.dart';
import '../../models/company.dart';
import '../../providers/company_provider.dart';
import '../../providers/theme_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common_widgets.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ROOT SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  // Notification local state
  bool _emailNotifications = true;
  bool _pushNotifications = false;
  bool _soundEffects = true;

  // System local state
  bool _usageAnalytics = true;
  bool _autoSave = true;

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        backgroundColor: AppColors.primary,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _openCompanySelector(List<Company> companies) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth >= 768;

    if (isLargeScreen) {
      showDialog(
        context: context,
        builder: (_) => _CompanySelectorDialog(
          companies: companies,
          onSelect: _selectCompany,
        ),
      );
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _CompanySelectorSheet(
          companies: companies,
          onSelect: _selectCompany,
        ),
      );
    }
  }

  void _selectCompany(Company company) {
    ref.read(selectedCompanyIdProvider.notifier).state = company.id;
    final prefs = ref.read(sharedPreferencesProvider);
    prefs.setString(AppConstants.lastCompanyKey, company.id);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final glassMode = ref.watch(glassModeProvider);
    final cs = theme.colorScheme;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: AppPageLayout.contentPadding(
          context,
          horizontal: 20,
          bottom: 40,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Page Header ──────────────────────────────────────────────
            _SettingsHeader(glassMode: glassMode, isDark: isDark)
                .animate()
                .fadeIn(duration: 400.ms)
                .slideY(begin: -0.04, duration: 400.ms, curve: Curves.easeOut),

            const SizedBox(height: 24),

            // ── Workspace ────────────────────────────────────────────────
            _WorkspaceSection(
              isDark: isDark,
              glassMode: glassMode,
              cs: cs,
              onOpenSelector: _openCompanySelector,
            ).animate().fadeIn(duration: 400.ms, delay: 60.ms).slideY(begin: 0.04),

            const SizedBox(height: 16),

            // ── Appearance ───────────────────────────────────────────────
            _AppearanceSection(
              isDark: isDark,
              glassMode: glassMode,
              cs: cs,
            ).animate().fadeIn(duration: 400.ms, delay: 100.ms).slideY(begin: 0.04),

            const SizedBox(height: 16),

            // ── Language & Region ────────────────────────────────────────
            _LanguageSection(
              isDark: isDark,
              glassMode: glassMode,
              cs: cs,
            ).animate().fadeIn(duration: 400.ms, delay: 140.ms).slideY(begin: 0.04),

            const SizedBox(height: 16),

            // ── Notifications ────────────────────────────────────────────
            _SectionCard(
              isDark: isDark,
              glassMode: glassMode,
              cs: cs,
              icon: Icons.notifications_outlined,
              title: 'Notifications',
              child: Column(
                children: [
                  _ToggleRow(
                    icon: Icons.email_outlined,
                    title: 'Email Notifications',
                    subtitle: 'Receive updates via email',
                    value: _emailNotifications,
                    cs: cs,
                    onChanged: (v) => setState(() => _emailNotifications = v),
                  ),
                  _SectionDivider(cs: cs),
                  _ToggleRow(
                    icon: Icons.notifications_active_outlined,
                    title: 'Push Notifications',
                    subtitle: 'Browser & mobile alerts',
                    value: _pushNotifications,
                    cs: cs,
                    onChanged: (v) => setState(() => _pushNotifications = v),
                  ),
                  _SectionDivider(cs: cs),
                  _ToggleRow(
                    icon: Icons.volume_up_outlined,
                    title: 'Sound Effects',
                    subtitle: 'Play sounds for events',
                    value: _soundEffects,
                    cs: cs,
                    onChanged: (v) => setState(() => _soundEffects = v),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms, delay: 180.ms).slideY(begin: 0.04),

            const SizedBox(height: 16),

            // ── System ───────────────────────────────────────────────────
            _SectionCard(
              isDark: isDark,
              glassMode: glassMode,
              cs: cs,
              icon: Icons.settings_suggest_outlined,
              title: 'System',
              child: Column(
                children: [
                  _ToggleRow(
                    icon: Icons.analytics_outlined,
                    title: 'Usage Analytics',
                    subtitle: 'Help improve AutoCreat',
                    value: _usageAnalytics,
                    cs: cs,
                    onChanged: (v) => setState(() => _usageAnalytics = v),
                  ),
                  _SectionDivider(cs: cs),
                  _ToggleRow(
                    icon: Icons.save_outlined,
                    title: 'Auto Save',
                    subtitle: 'Automatically save changes',
                    value: _autoSave,
                    cs: cs,
                    onChanged: (v) => setState(() => _autoSave = v),
                  ),
                  _SectionDivider(cs: cs),
                  _ActionRow(
                    icon: Icons.cleaning_services_outlined,
                    title: 'Clear Cache',
                    subtitle: 'Free up storage',
                    cs: cs,
                    onTap: () => _showSnackBar('Cache cleared'),
                  ),
                  _SectionDivider(cs: cs),
                  _ActionRow(
                    icon: Icons.download_rounded,
                    title: 'Export Data',
                    subtitle: 'Download all your data',
                    cs: cs,
                    onTap: () => _showSnackBar('Export started'),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms, delay: 220.ms).slideY(begin: 0.04),

            const SizedBox(height: 16),

            // ── About ────────────────────────────────────────────────────
            _AboutSection(
              isDark: isDark,
              glassMode: glassMode,
              cs: cs,
              onSnackBar: _showSnackBar,
            ).animate().fadeIn(duration: 400.ms, delay: 260.ms).slideY(begin: 0.04),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PAGE HEADER
// ─────────────────────────────────────────────────────────────────────────────

class _SettingsHeader extends StatelessWidget {
  final bool glassMode;
  final bool isDark;

  const _SettingsHeader({required this.glassMode, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(24);

    Widget content = Stack(
      children: [
        // Decorative circles
        PositionedDirectional(
          top: -30,
          end: -30,
          child: Container(
            width: 130,
            height: 130,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: isDark ? 0.06 : 0.18),
            ),
          ),
        ),
        PositionedDirectional(
          bottom: -20,
          end: 90,
          child: Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: isDark ? 0.04 : 0.12),
            ),
          ),
        ),
        PositionedDirectional(
          top: 20,
          end: 20,
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: isDark ? 0.03 : 0.09),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Gear icon with gradient background
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.primaryLight, AppColors.accent],
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.36),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.settings_rounded,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Settings',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.5,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Customize your workspace',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.78),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );

    if (glassMode) {
      return ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: radius,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary.withValues(alpha: isDark ? 0.55 : 0.70),
                  AppColors.accent.withValues(alpha: isDark ? 0.40 : 0.60),
                ],
              ),
              border: Border.all(
                color: Colors.white.withValues(alpha: isDark ? 0.18 : 0.30),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.28),
                  blurRadius: 32,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: content,
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.accent],
          stops: [0.0, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.32),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: AppColors.accent.withValues(alpha: 0.18),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: ClipRRect(borderRadius: radius, child: content),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SECTION CARD WRAPPER
// ─────────────────────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final bool isDark;
  final bool glassMode;
  final ColorScheme cs;
  final IconData icon;
  final String title;
  final Widget child;

  const _SectionCard({
    required this.isDark,
    required this.glassMode,
    required this.cs,
    required this.icon,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(16);
    final sectionHeader = Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: AppColors.primary),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: cs.onSurface.withValues(alpha: isDark ? 0.82 : 0.72),
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );

    if (glassMode) {
      return ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: radius,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: isDark ? 0.10 : 0.62),
                  Colors.white.withValues(alpha: isDark ? 0.04 : 0.28),
                ],
              ),
              border: Border.all(
                color: Colors.white.withValues(alpha: isDark ? 0.14 : 0.55),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.28 : 0.08),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                sectionHeader,
                child,
                const SizedBox(height: 4),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: radius,
        border: Border.all(
          color: cs.outline.withValues(alpha: 0.15),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          sectionHeader,
          child,
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TOGGLE ROW
// ─────────────────────────────────────────────────────────────────────────────

class _ToggleRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ColorScheme cs;
  final ValueChanged<bool> onChanged;

  const _ToggleRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.cs,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 20, color: cs.onSurface.withValues(alpha: 0.7)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: cs.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ACTION ROW  (no switch — just tap)
// ─────────────────────────────────────────────────────────────────────────────

class _ActionRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final ColorScheme cs;
  final VoidCallback onTap;

  const _ActionRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.cs,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 20, color: cs.onSurface.withValues(alpha: 0.7)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: cs.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: cs.onSurface.withValues(alpha: 0.35),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SECTION DIVIDER
// ─────────────────────────────────────────────────────────────────────────────

class _SectionDivider extends StatelessWidget {
  final ColorScheme cs;
  const _SectionDivider({required this.cs});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Divider(
        height: 1,
        color: cs.outline.withValues(alpha: 0.12),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// WORKSPACE SECTION
// ─────────────────────────────────────────────────────────────────────────────

class _WorkspaceSection extends ConsumerWidget {
  final bool isDark;
  final bool glassMode;
  final ColorScheme cs;
  final void Function(List<Company>) onOpenSelector;

  const _WorkspaceSection({
    required this.isDark,
    required this.glassMode,
    required this.cs,
    required this.onOpenSelector,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedId = ref.watch(selectedCompanyIdProvider);
    final companiesAsync = ref.watch(companiesProvider);

    return _SectionCard(
      isDark: isDark,
      glassMode: glassMode,
      cs: cs,
      icon: Icons.business_rounded,
      title: 'Workspace',
      child: Column(
        children: [
          // Active company selector
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
            child: companiesAsync.when(
              loading: () => _CompanyPickerShimmer(cs: cs),
              error: (_, __) => _NoCompanyPlaceholder(cs: cs),
              data: (companies) {
                final selected = selectedId != null
                    ? companies.where((c) => c.id == selectedId).firstOrNull
                    : null;

                return _CompanySelectorTile(
                  company: selected,
                  isDark: isDark,
                  cs: cs,
                  onTap: () => onOpenSelector(companies),
                );
              },
            ),
          ),

          _SectionDivider(cs: cs),

          // Manage Companies button
          InkWell(
            onTap: () => context.go(AppRoutes.companies),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.settings_rounded,
                      size: 18,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Manage Companies',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: AppColors.primary.withValues(alpha: 0.7),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompanySelectorTile extends StatelessWidget {
  final Company? company;
  final bool isDark;
  final ColorScheme cs;
  final VoidCallback onTap;

  const _CompanySelectorTile({
    required this.company,
    required this.isDark,
    required this.cs,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.04)
              : AppColors.lightBg.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: cs.outline.withValues(alpha: 0.18),
          ),
        ),
        child: Row(
          children: [
            if (company != null) ...[
              _CompanyAvatar(company: company!, size: 40),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      company!.name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (company!.industry != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        company!.industry!,
                        style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurface.withValues(alpha: 0.5),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ] else ...[
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: cs.outline.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: cs.outline.withValues(alpha: 0.20),
                  ),
                ),
                child: Icon(
                  Icons.business_outlined,
                  size: 20,
                  color: cs.onSurface.withValues(alpha: 0.4),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'No company selected',
                  style: TextStyle(
                    fontSize: 14,
                    color: cs.onSurface.withValues(alpha: 0.5),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
            const SizedBox(width: 8),
            Icon(
              Icons.expand_more_rounded,
              size: 20,
              color: cs.onSurface.withValues(alpha: 0.45),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompanyPickerShimmer extends StatelessWidget {
  final ColorScheme cs;
  const _CompanyPickerShimmer({required this.cs});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: cs.outline.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}

class _NoCompanyPlaceholder extends StatelessWidget {
  final ColorScheme cs;
  const _NoCompanyPlaceholder({required this.cs});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        'Could not load companies',
        style: TextStyle(
          fontSize: 13,
          color: cs.onSurface.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// COMPANY AVATAR  (initials with gradient bg)
// ─────────────────────────────────────────────────────────────────────────────

class _CompanyAvatar extends StatelessWidget {
  final Company company;
  final double size;

  const _CompanyAvatar({required this.company, this.size = 40});

  @override
  Widget build(BuildContext context) {
    final initial =
        company.name.isNotEmpty ? company.name[0].toUpperCase() : '?';

    if (company.logo != null && company.logo!.isNotEmpty) {
      return AvatarWidget(
        imageUrl: company.logo,
        initials: initial,
        size: size,
        color: AppColors.primary,
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.accent],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.30),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            fontSize: size * 0.38,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// COMPANY SELECTOR – BOTTOM SHEET
// ─────────────────────────────────────────────────────────────────────────────

class _CompanySelectorSheet extends ConsumerWidget {
  final List<Company> companies;
  final void Function(Company) onSelect;

  const _CompanySelectorSheet({
    required this.companies,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final glassMode = ref.watch(glassModeProvider);
    final selectedId = ref.watch(selectedCompanyIdProvider);
    final cs = Theme.of(context).colorScheme;

    final bgColor = isDark ? AppColors.darkCard : AppColors.lightCard;

    Widget sheetContent = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Handle
        Center(
          child: Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: cs.outline.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        // Title row
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.business_rounded,
                  size: 18,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Select Company',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: Icon(Icons.close_rounded,
                    color: cs.onSurface.withValues(alpha: 0.5)),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
        if (companies.isEmpty)
          Padding(
            padding: const EdgeInsets.all(32),
            child: Text(
              'No companies available',
              style: TextStyle(
                fontSize: 14,
                color: cs.onSurface.withValues(alpha: 0.5),
              ),
            ),
          )
        else
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.5,
            ),
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              itemCount: companies.length,
              separatorBuilder: (_, __) => const SizedBox(height: 6),
              itemBuilder: (context, index) {
                final company = companies[index];
                final isActive = company.id == selectedId;
                return _CompanyListItem(
                  company: company,
                  isActive: isActive,
                  cs: cs,
                  isDark: isDark,
                  onTap: () {
                    onSelect(company);
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
      ],
    );

    if (glassMode) {
      return ClipRRect(
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(28)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: isDark ? 0.12 : 0.68),
                  Colors.white.withValues(alpha: isDark ? 0.05 : 0.32),
                ],
              ),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(28)),
              border: Border.all(
                color: Colors.white.withValues(alpha: isDark ? 0.16 : 0.55),
              ),
            ),
            child: sheetContent,
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.40 : 0.12),
            blurRadius: 32,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: sheetContent,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// COMPANY SELECTOR – DIALOG (large screens)
// ─────────────────────────────────────────────────────────────────────────────

class _CompanySelectorDialog extends ConsumerWidget {
  final List<Company> companies;
  final void Function(Company) onSelect;

  const _CompanySelectorDialog({
    required this.companies,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final glassMode = ref.watch(glassModeProvider);
    final selectedId = ref.watch(selectedCompanyIdProvider);
    final cs = Theme.of(context).colorScheme;

    final inner = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 22, 16, 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.business_rounded,
                  size: 18,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Select Active Company',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.close_rounded,
                    color: cs.onSurface.withValues(alpha: 0.5)),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
        Divider(height: 1, color: cs.outline.withValues(alpha: 0.15)),
        if (companies.isEmpty)
          Padding(
            padding: const EdgeInsets.all(32),
            child: Center(
              child: Text(
                'No companies available',
                style: TextStyle(
                  fontSize: 14,
                  color: cs.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ),
          )
        else
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.5,
            ),
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              itemCount: companies.length,
              separatorBuilder: (_, __) => const SizedBox(height: 6),
              itemBuilder: (context, index) {
                final company = companies[index];
                final isActive = company.id == selectedId;
                return _CompanyListItem(
                  company: company,
                  isActive: isActive,
                  cs: cs,
                  isDark: isDark,
                  onTap: () {
                    onSelect(company);
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
      ],
    );

    if (glassMode) {
      return Dialog(
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withValues(alpha: isDark ? 0.12 : 0.70),
                      Colors.white.withValues(alpha: isDark ? 0.05 : 0.34),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: isDark ? 0.18 : 0.60),
                  ),
                ),
                child: Material(type: MaterialType.transparency, child: inner),
              ),
            ),
          ),
        ),
      );
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: inner,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// COMPANY LIST ITEM
// ─────────────────────────────────────────────────────────────────────────────

class _CompanyListItem extends StatelessWidget {
  final Company company;
  final bool isActive;
  final ColorScheme cs;
  final bool isDark;
  final VoidCallback onTap;

  const _CompanyListItem({
    required this.company,
    required this.isActive,
    required this.cs,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      decoration: BoxDecoration(
        color: isActive
            ? AppColors.primary.withValues(alpha: isDark ? 0.16 : 0.08)
            : cs.surface.withValues(alpha: 0),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive
              ? AppColors.primary.withValues(alpha: 0.40)
              : cs.outline.withValues(alpha: 0.10),
          width: isActive ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              _CompanyAvatar(company: company, size: 42),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      company.name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isActive ? AppColors.primary : cs.onSurface,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (company.industry != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        company.industry!,
                        style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurface.withValues(alpha: 0.5),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              if (isActive)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    size: 12,
                    color: Colors.white,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// APPEARANCE SECTION
// ─────────────────────────────────────────────────────────────────────────────

class _AppearanceSection extends ConsumerWidget {
  final bool isDark;
  final bool glassMode;
  final ColorScheme cs;

  const _AppearanceSection({
    required this.isDark,
    required this.glassMode,
    required this.cs,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTheme = ref.watch(themeProvider);

    return _SectionCard(
      isDark: isDark,
      glassMode: glassMode,
      cs: cs,
      icon: Icons.palette_outlined,
      title: 'Appearance',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Theme picker
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Theme',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface.withValues(alpha: 0.5),
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _ThemeCard(
                        label: 'Light',
                        icon: Icons.wb_sunny_rounded,
                        mode: ThemeMode.light,
                        currentMode: currentTheme,
                        isDark: isDark,
                        cs: cs,
                        previewColors: const [
                          Color(0xFFFBFCFF),
                          Color(0xFFEEF1FF),
                        ],
                        onTap: () => ref
                            .read(themeProvider.notifier)
                            .setTheme(ThemeMode.light),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _ThemeCard(
                        label: 'Dark',
                        icon: Icons.nightlight_round,
                        mode: ThemeMode.dark,
                        currentMode: currentTheme,
                        isDark: isDark,
                        cs: cs,
                        previewColors: const [
                          Color(0xFF070C18),
                          Color(0xFF0F172A),
                        ],
                        onTap: () => ref
                            .read(themeProvider.notifier)
                            .setTheme(ThemeMode.dark),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _ThemeCard(
                        label: 'System',
                        icon: Icons.phone_android_rounded,
                        mode: ThemeMode.system,
                        currentMode: currentTheme,
                        isDark: isDark,
                        cs: cs,
                        previewColors: const [
                          AppColors.primary,
                          AppColors.accent,
                        ],
                        onTap: () => ref
                            .read(themeProvider.notifier)
                            .setTheme(ThemeMode.system),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          _SectionDivider(cs: cs),

          // Glass mode toggle
          _ToggleRow(
            icon: Icons.blur_on_rounded,
            title: 'Glass Effect',
            subtitle: 'Translucent surfaces with blur',
            value: glassMode,
            cs: cs,
            onChanged: (v) =>
                ref.read(glassModeProvider.notifier).setGlassMode(v),
          ),
        ],
      ),
    );
  }
}

class _ThemeCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final ThemeMode mode;
  final ThemeMode currentMode;
  final bool isDark;
  final ColorScheme cs;
  final List<Color> previewColors;
  final VoidCallback onTap;

  const _ThemeCard({
    required this.label,
    required this.icon,
    required this.mode,
    required this.currentMode,
    required this.isDark,
    required this.cs,
    required this.previewColors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = mode == currentMode;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : cs.outline.withValues(alpha: 0.20),
            width: isSelected ? 2 : 1,
          ),
          color: isDark
              ? Colors.white.withValues(alpha: 0.04)
              : AppColors.lightBg.withValues(alpha: 0.5),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.20),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 12, 10, 10),
          child: Column(
            children: [
              // Preview swatch
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    height: 36,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: previewColors,
                      ),
                      border: Border.all(
                        color: cs.outline.withValues(alpha: 0.12),
                      ),
                    ),
                    child: Center(
                      child: Icon(icon, size: 16, color: Colors.white),
                    ),
                  ),
                  if (isSelected)
                    PositionedDirectional(
                      top: -6,
                      end: -6,
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check,
                          size: 11,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight:
                      isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? AppColors.primary
                      : cs.onSurface.withValues(alpha: 0.65),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// LANGUAGE & REGION SECTION
// ─────────────────────────────────────────────────────────────────────────────

class _LanguageSection extends ConsumerWidget {
  final bool isDark;
  final bool glassMode;
  final ColorScheme cs;

  const _LanguageSection({
    required this.isDark,
    required this.glassMode,
    required this.cs,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLang = ref.watch(languageProvider);

    return _SectionCard(
      isDark: isDark,
      glassMode: glassMode,
      cs: cs,
      icon: Icons.language_rounded,
      title: 'Language & Region',
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: _LanguageCard(
                    code: 'EN',
                    label: 'English',
                    language: AppLanguage.english,
                    currentLanguage: currentLang,
                    isDark: isDark,
                    cs: cs,
                    onTap: () => ref
                        .read(languageProvider.notifier)
                        .setLanguage(AppLanguage.english),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _LanguageCard(
                    code: 'فا',
                    label: 'فارسی',
                    language: AppLanguage.persian,
                    currentLanguage: currentLang,
                    isDark: isDark,
                    cs: cs,
                    onTap: () => ref
                        .read(languageProvider.notifier)
                        .setLanguage(AppLanguage.persian),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.info.withValues(alpha: 0.20),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 14,
                    color: AppColors.info.withValues(alpha: 0.8),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'RTL layout is applied automatically for Persian',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.info.withValues(alpha: 0.85),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LanguageCard extends StatelessWidget {
  final String code;
  final String label;
  final AppLanguage language;
  final AppLanguage currentLanguage;
  final bool isDark;
  final ColorScheme cs;
  final VoidCallback onTap;

  const _LanguageCard({
    required this.code,
    required this.label,
    required this.language,
    required this.currentLanguage,
    required this.isDark,
    required this.cs,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = language == currentLanguage;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: isSelected
              ? AppColors.primary.withValues(alpha: isDark ? 0.18 : 0.10)
              : (isDark
                  ? Colors.white.withValues(alpha: 0.04)
                  : AppColors.lightBg.withValues(alpha: 0.5)),
          border: Border.all(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.50)
                : cs.outline.withValues(alpha: 0.18),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.16),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.15)
                    : cs.outline.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary.withValues(alpha: 0.30)
                      : cs.outline.withValues(alpha: 0.12),
                ),
              ),
              child: Center(
                child: Text(
                  code,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color:
                        isSelected ? AppColors.primary : cs.onSurface.withValues(alpha: 0.65),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight:
                      isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? AppColors.primary
                      : cs.onSurface.withValues(alpha: 0.75),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle_rounded,
                size: 18,
                color: AppColors.primary,
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ABOUT SECTION
// ─────────────────────────────────────────────────────────────────────────────

class _AboutSection extends StatelessWidget {
  final bool isDark;
  final bool glassMode;
  final ColorScheme cs;
  final void Function(String) onSnackBar;

  const _AboutSection({
    required this.isDark,
    required this.glassMode,
    required this.cs,
    required this.onSnackBar,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      isDark: isDark,
      glassMode: glassMode,
      cs: cs,
      icon: Icons.info_outline_rounded,
      title: 'About',
      child: Column(
        children: [
          // Info rows
          _AboutInfoRow(
            icon: Icons.info_outline_rounded,
            title: 'Version',
            value: '1.0.0',
            cs: cs,
          ),
          _SectionDivider(cs: cs),
          _AboutInfoRow(
            icon: Icons.code_rounded,
            title: 'Build',
            value: '2024.1',
            cs: cs,
          ),
          _SectionDivider(cs: cs),
          _AboutInfoRow(
            icon: Icons.gavel_rounded,
            title: 'License',
            value: 'MIT',
            cs: cs,
          ),
          _SectionDivider(cs: cs),

          // Action rows
          _ActionRow(
            icon: Icons.feedback_outlined,
            title: 'Send Feedback',
            subtitle: 'Share your thoughts with us',
            cs: cs,
            onTap: () => onSnackBar('Opening feedback...'),
          ),
          _SectionDivider(cs: cs),
          _ActionRow(
            icon: Icons.bug_report_outlined,
            title: 'Report a Bug',
            subtitle: 'Help us fix issues',
            cs: cs,
            onTap: () => onSnackBar('Opening issue tracker...'),
          ),
          _SectionDivider(cs: cs),
          _ActionRow(
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy Policy',
            subtitle: 'How we handle your data',
            cs: cs,
            onTap: () => onSnackBar('Opening privacy policy...'),
          ),

          // Branding footer
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
            child: Column(
              children: [
                Divider(
                  height: 1,
                  color: cs.outline.withValues(alpha: 0.10),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [AppColors.primary, AppColors.accent],
                        ),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.30),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.auto_awesome_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ShaderMask(
                          shaderCallback: (bounds) =>
                              const LinearGradient(
                            colors: [AppColors.primary, AppColors.accent],
                          ).createShader(bounds),
                          child: const Text(
                            'AutoCreat',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ),
                        Text(
                          'Version 1.0.0 · Build 2024.1',
                          style: TextStyle(
                            fontSize: 11,
                            color: cs.onSurface.withValues(alpha: 0.45),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AboutInfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final ColorScheme cs;

  const _AboutInfoRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      child: Row(
        children: [
          Icon(icon, size: 20, color: cs.onSurface.withValues(alpha: 0.55)),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: cs.onSurface,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

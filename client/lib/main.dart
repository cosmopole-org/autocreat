import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'providers/theme_provider.dart';
import 'providers/realtime_provider.dart';
import 'router/router.dart';
import 'theme/app_colors.dart';
import 'theme/app_theme.dart';
import 'data/mock_ui_text.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize SharedPreferences
  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const AutoCreatApp(),
    ),
  );
}

class AutoCreatApp extends ConsumerWidget {
  const AutoCreatApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(realtimeConnectionProvider); // keep global WS connected
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeProvider);
    final glassMode = ref.watch(glassModeProvider);

    return MaterialApp.router(
      title: MockUiText.autocreat,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(glassMode: glassMode),
      darkTheme: AppTheme.dark(glassMode: glassMode),
      themeMode: themeMode,
      routerConfig: router,
      builder: (context, child) {
        final brightness = Theme.of(context).brightness;

        return _AppBackground(
          brightness: brightness,
          glassMode: glassMode,
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}

class _AppBackground extends StatelessWidget {
  final Brightness brightness;
  final bool glassMode;
  final Widget child;

  const _AppBackground({
    required this.brightness,
    required this.glassMode,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: AppColors.backgroundGradient(brightness, glassMode: glassMode),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (glassMode) ..._buildAuroraOrbs(),
          child,
        ],
      ),
    );
  }

  List<Widget> _buildAuroraOrbs() {
    final dark = brightness == Brightness.dark;
    return [
      Positioned(
        top: -160,
        left: -120,
        child: _AuroraOrb(
          size: 360,
          color: (dark ? AppColors.primaryLight : AppColors.primary).withValues(alpha: dark ? 0.18 : 0.16),
        ),
      ),
      Positioned(
        right: -140,
        top: 120,
        child: _AuroraOrb(
          size: 300,
          color: AppColors.accent.withValues(alpha: dark ? 0.16 : 0.14),
        ),
      ),
      Positioned(
        left: 160,
        bottom: -190,
        child: _AuroraOrb(
          size: 420,
          color: const Color(0xFFEC4899).withValues(alpha: dark ? 0.10 : 0.11),
        ),
      ),
    ];
  }
}

class _AuroraOrb extends StatelessWidget {
  final double size;
  final Color color;

  const _AuroraOrb({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, color.withValues(alpha: 0)],
          ),
        ),
      ),
    );
  }
}

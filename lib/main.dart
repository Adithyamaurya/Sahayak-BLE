import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sahayak/theme.dart';
// Placeholders for screens
import 'package:sahayak/screens/splash_screen.dart';
import 'package:sahayak/screens/auth/login_screen.dart';
import 'package:sahayak/screens/auth/register_screen.dart';
import 'package:sahayak/screens/auth/otp_verify_screen.dart';
import 'package:sahayak/screens/main_wrapper.dart'; // Wrapper for BottomNav

import 'package:sahayak/screens/home/home_screen.dart';
import 'package:sahayak/screens/maps/maps_screen.dart';
import 'package:sahayak/screens/community/community_feed_screen.dart';
import 'package:sahayak/screens/tools/tools_screen.dart';
import 'package:sahayak/screens/settings/settings_screen.dart';
import 'package:sahayak/screens/permissions/permission_screen.dart';
import 'package:sahayak/screens/setup/setup_required_screen.dart';

import 'package:sahayak/services/firebase_bootstrap.dart';
import 'package:sahayak/services/notification_service.dart';
import 'package:sahayak/providers/theme_mode_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final bootstrap = await FirebaseBootstrap.init();
  if (bootstrap.isReady) {
    await NotificationService.init();
  }
  runApp(
    ProviderScope(
      overrides: [
        firebaseBootstrapProvider.overrideWithValue(bootstrap),
      ],
      child: const SahayakApp(),
    ),
  );
}

class SahayakApp extends ConsumerWidget {
  const SahayakApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    return MaterialApp.router(
      title: 'Sahayak',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: mode,
      debugShowCheckedModeBanner: false,
      routerConfig: _router,
    );
  }
}

// GoRouter configuration
final _router = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/setup-required',
      builder: (context, state) => const SetupRequiredScreen(),
    ),
    GoRoute(
      path: '/permissions',
      builder: (context, state) => const PermissionScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/verify',
      builder: (context, state) {
        final phone = (state.extra is String) ? state.extra! as String : '';
        return OtpVerifyScreen(phone: phone);
      },
    ),
    // StatefulShellRoute for Bottom Navigation
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return MainWrapper(navigationShell: navigationShell);
      },
      branches: [
        // Branch 0: Home
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/home',
              builder: (context, state) => const HomeScreen(),
            ),
          ],
        ),
        // Branch 1: Maps / Radar Center
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/maps',
              builder: (context, state) => const MapsScreen(),
            ),
          ],
        ),
        // Branch 2: Community
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/community',
              builder: (context, state) => const CommunityFeedScreen(),
            ),
          ],
        ),
        // Branch 3: Tools
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/tools',
              builder: (context, state) => const ToolsScreen(),
            ),
          ],
        ),
        // Branch 3: Settings
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/settings',
              builder: (context, state) => const SettingsScreen(),
            ),
          ],
        ),
      ],
    ),
  ],
);

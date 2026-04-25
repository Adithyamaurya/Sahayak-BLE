import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:sahayak/theme.dart';
import 'package:sahayak/services/firebase_bootstrap.dart';
import 'package:sahayak/services/permission_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.6, curve: Curves.easeOutQuart)),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.2, 0.8, curve: Curves.easeIn)),
    );

    _controller.forward();

    Future.delayed(const Duration(milliseconds: 2500), _decideNext);
  }

  Future<void> _decideNext() async {
    final bootstrap = ref.read(firebaseBootstrapProvider);
    if (!bootstrap.isReady) {
      if (mounted) context.go('/setup-required');
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) context.go('/login');
      return;
    }

    if (!user.emailVerified) {
      if (mounted) context.go('/verify');
      return;
    }

    final permissionOk = await PermissionService.areMandatoryGranted();
    if (!permissionOk) {
      if (mounted) context.go('/permissions');
      return;
    }

    if (mounted) context.go('/home');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.primary.withValues(alpha: 0.05),
              AppTheme.background,
              AppTheme.accent.withValues(alpha: 0.05),
            ],
          ),
        ),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Stack(
              children: [
                // Background subtle shapes
                Positioned(
                  top: -100,
                  right: -100,
                  child: Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.primary.withValues(alpha: 0.03),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -50,
                  left: -50,
                  child: Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.accent.withValues(alpha: 0.03),
                    ),
                  ),
                ),
                
                Center(
                  child: Opacity(
                    opacity: _opacityAnimation.value,
                    child: Transform.scale(
                      scale: _scaleAnimation.value,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              color: AppTheme.surface,
                              borderRadius: BorderRadius.circular(40),
                              boxShadow: AppTheme.softShadow,
                              border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 2),
                            ),
                            child: const Icon(
                              LucideIcons.heartPulse,
                              size: 72,
                              color: AppTheme.primary,
                            ),
                          ),
                          const SizedBox(height: 32),
                          Text(
                            'SAHAYAK',
                            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                              letterSpacing: 10,
                              color: AppTheme.textDark,
                              fontSize: 32,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Your Local Safety Companion',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: AppTheme.textMuted,
                              letterSpacing: 2,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          const SizedBox(height: 64),
                          const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

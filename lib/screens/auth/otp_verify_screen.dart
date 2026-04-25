import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:sahayak/services/auth_service.dart';
import 'package:sahayak/theme.dart';

class OtpVerifyScreen extends StatefulWidget {
  final String phone;
  const OtpVerifyScreen({super.key, required this.phone});

  @override
  State<OtpVerifyScreen> createState() => _OtpVerifyScreenState();
}

class _OtpVerifyScreenState extends State<OtpVerifyScreen> with SingleTickerProviderStateMixin {
  final _auth = AuthService();
  bool _sending = false;
  bool _checking = false;
  String? _error;
  
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
       vsync: this,
       duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _send(initial: true);
  }
  
  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _send({bool initial = false}) async {
    if (!initial) {
      setState(() {
        _sending = true;
        _error = null;
      });
    }
    try {
      await _auth.sendEmailVerification();
      if (!initial) {
        setState(() => _error = "Verification pulse sent to your email.");
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted && !initial) setState(() => _sending = false);
    }
  }

  Future<void> _check() async {
    setState(() {
      _checking = true;
      _error = null;
    });
    try {
      await _auth.reloadUser();
      final verified = _auth.currentUser?.emailVerified ?? false;
      if (!verified) {
        setState(() => _error = 'Authorization denied: Link not clicked. Check your inbox.');
        return;
      }
      if (!mounted) return;
      context.go('/permissions');
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        alignment: Alignment.center,
        children: [
          // Berserk Background
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Stack(
                children: [
                  Positioned(
                    top: -50,
                    right: -50,
                    child: ImageFiltered(
                      imageFilter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
                      child: Container(
                        width: 400,
                        height: 400,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.accent.withValues(alpha: 0.1 * _pulseController.value),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }
          ),
          
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Verification Shield
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                       return Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.accent.withValues(alpha: 0.05),
                          border: Border.all(color: AppTheme.accent.withValues(alpha: 0.2)),
                          boxShadow: [
                            BoxShadow(color: AppTheme.accent.withValues(alpha: 0.2 * _pulseController.value), blurRadius: 40, spreadRadius: 10),
                          ],
                        ),
                        child: const Icon(LucideIcons.mailCheck, size: 60, color: AppTheme.accent),
                      );
                    }
                  ),
                  
                  const SizedBox(height: 48),
                  
                  const Text(
                    'VERIFICATION',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'We have dispatched a secure authorization link to your email. Acknowledge it to Login.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white60, fontSize: 13, height: 1.5),
                  ),
                  
                  const SizedBox(height: 48),
                  
                  if (_error != null) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.danger.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.danger.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(LucideIcons.alertCircle, color: AppTheme.danger, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _error!,
                              style: const TextStyle(color: AppTheme.danger, fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                  
                  // Verification Button
                  GestureDetector(
                    onTap: (_sending || _checking) ? null : _check,
                    child: Container(
                      height: 60,
                      decoration: BoxDecoration(
                         borderRadius: BorderRadius.circular(20),
                         color: AppTheme.primary,
                         boxShadow: [
                           BoxShadow(color: AppTheme.primary.withValues(alpha: 0.4), blurRadius: 20, offset: const Offset(0, 8)),
                         ],
                      ),
                      child: Center(
                         child: _checking 
                           ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                           : const Text('VERIFY & LOGIN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 2)),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  TextButton(
                    onPressed: (_sending || _checking) ? null : () => _send(),
                    child: Text(
                      _sending ? 'Resending...' : 'Resend Verification Link', 
                      style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, letterSpacing: 1),
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      _auth.signOut();
                      context.go('/login');
                    },
                    child: const Text('Logout', style: TextStyle(color: AppTheme.textMuted)),
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

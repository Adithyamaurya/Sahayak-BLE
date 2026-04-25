import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sahayak/services/auth_service.dart';
import 'package:sahayak/services/firestore_service.dart';
import 'package:sahayak/theme.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> with SingleTickerProviderStateMixin {
  final _auth = AuthService();
  final _db = FirestoreService();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _loading = false;
  String? _error;
  
  late AnimationController _bgController;

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _bgController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final cred = await _auth.signUpEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      final user = cred.user;
      if (user == null) throw StateError('Registration pipeline failed.');

      await _db.upsertCurrentUserProfile(
        uid: user.uid,
        email: user.email ?? '',
        phone: _phoneController.text.trim(),
      );

      // Store name in user doc permanently
      await _db.users.doc(user.uid).set(
        {
          'displayName': _nameController.text.trim(),
        },
        SetOptions(merge: true),
      );

      await _auth.sendEmailVerification();

      if (!mounted) return;
      // After registration, they MUST verify. Route to verify natively.
      context.go('/verify', extra: _phoneController.text.trim());
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: Stack(
        children: [
           // Berserk Background
          AnimatedBuilder(
            animation: _bgController,
            builder: (context, child) {
              return Stack(
                children: [
                  Positioned(
                    top: -150 + (80 * _bgController.value),
                    right: -100 - (50 * _bgController.value),
                    child: ImageFiltered(
                      imageFilter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
                      child: Container(
                        width: 400,
                        height: 400,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.accent.withValues(alpha: 0.1),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'CREATE IDENTITY',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Secure your node on the community network.',
                    style: TextStyle(color: Colors.white54, fontSize: 13, letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 40),
                  
                  // Form Glassmorphism Container
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.02),
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                    ),
                    child: Column(
                      children: [
                        _buildGlassField(
                          controller: _nameController,
                          hint: 'Operative Name',
                          icon: LucideIcons.user,
                        ),
                        const SizedBox(height: 16),
                        _buildGlassField(
                          controller: _emailController,
                          hint: 'Encrypted Email',
                          icon: LucideIcons.mail,
                          type: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 16),
                        _buildGlassField(
                          controller: _phoneController,
                          hint: 'Contact Ping (Phone)',
                          icon: LucideIcons.phone,
                          type: TextInputType.phone,
                        ),
                        const SizedBox(height: 16),
                        _buildGlassField(
                          controller: _passwordController,
                          hint: 'Passphrase',
                          icon: LucideIcons.lock,
                          obscure: true,
                        ),
                        
                        if (_error != null) ...[
                          const SizedBox(height: 24),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.danger.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppTheme.danger.withValues(alpha: 0.2)),
                            ),
                            child: Row(
                              children: [
                                const Icon(LucideIcons.alertTriangle, color: AppTheme.danger, size: 20),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _error!,
                                    style: const TextStyle(color: AppTheme.danger, fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        
                        const SizedBox(height: 40),
                        
                        // Action Button
                        GestureDetector(
                            onTap: _loading ? null : _register,
                            child: Container(
                              height: 60,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                gradient: LinearGradient(
                                  colors: [AppTheme.primary, AppTheme.primary.withValues(alpha: 0.8)],
                                ),
                                boxShadow: [
                                  BoxShadow(color: AppTheme.primary.withValues(alpha: 0.4), blurRadius: 20, offset: const Offset(0, 8)),
                                ],
                              ),
                              child: Center(
                                child: _loading 
                                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                                  : const Text('ESTABLISH PROFILE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 2)),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    TextInputType? type,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.textDark.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.textMuted.withValues(alpha: 0.1)),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: type,
        style: const TextStyle(fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: AppTheme.textMuted.withValues(alpha: 0.7)),
          prefixIcon: Icon(icon, color: AppTheme.primary),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        ),
      ),
    );
  }
}

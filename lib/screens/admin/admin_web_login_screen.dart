import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:retro_vibes/provider/auth_provider.dart';
import 'package:retro_vibes/screens/admin/admin_web_dashboard_screen.dart';
import 'package:retro_vibes/theme/app_theme.dart';

class AdminWebLoginScreen extends StatefulWidget {
  const AdminWebLoginScreen({super.key});

  @override
  State<AdminWebLoginScreen> createState() => _AdminWebLoginScreenState();
}

class _AdminWebLoginScreenState extends State<AdminWebLoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  String? _authError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleAdminLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _authError = 'Please enter both email and password.';
      });
      return;
    }

    setState(() {
      _authError = null;
    });

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.login(email, password);

    if (success && mounted) {
      final user = authProvider.currentUser;

      // Strict Administrator Role Check
      if (user != null && user.isAdmin) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AdminWebDashboardScreen()),
        );
      } else {
        // Logout non-admin account and display restriction alert
        await authProvider.logout();
        setState(() {
          _authError = 'Access Denied: You do not have Administrator permissions.\nOnly authorized admin accounts can access this portal.';
        });
      }
    } else if (mounted) {
      setState(() {
        _authError = authProvider.errorMessage ?? 'Invalid email or password.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFF0F0B09),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            width: size.width > 600 ? 460 : size.width * 0.9,
            padding: const EdgeInsets.all(36),
            decoration: BoxDecoration(
              color: AppTheme.cardBackground.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppTheme.primaryAccent.withValues(alpha: 0.4), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryAccent.withValues(alpha: 0.15),
                  blurRadius: 30,
                  spreadRadius: 2,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.8),
                  blurRadius: 40,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Logo & Branding
                Center(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryAccent.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.primaryAccent, width: 2),
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/icons/retro_vibes_icon.png',
                            width: 54,
                            height: 54,
                            fit: BoxFit.cover,
                            errorBuilder: (c, e, s) => Icon(
                              Icons.admin_panel_settings,
                              color: AppTheme.primaryAccent,
                              size: 44,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Retro ',
                            style: TextStyle(
                              color: AppTheme.white,
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                          Text(
                            'Vibes',
                            style: TextStyle(
                              color: AppTheme.primaryAccent,
                              fontSize: 28,
                              fontFamily: 'Cursive',
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFD700).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFFFD700), width: 1),
                        ),
                        child: const Text(
                          'WEB ADMIN PORTAL',
                          style: TextStyle(
                            color: Color(0xFFFFD700),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Form Heading
                Text(
                  'Administrator Sign In',
                  style: TextStyle(
                    color: AppTheme.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Enter your credentials to access the central music catalog, live uploads, and analytics portal.',
                  style: TextStyle(color: AppTheme.white38, fontSize: 12, height: 1.4),
                ),

                const SizedBox(height: 24),

                // Error Banner
                if (_authError != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade900.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.redAccent.withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.error_outline, color: Colors.redAccent, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _authError!,
                            style: const TextStyle(color: Colors.redAccent, fontSize: 12, height: 1.3),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Email Field
                Text(
                  'ADMIN EMAIL',
                  style: TextStyle(color: AppTheme.white38, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _emailController,
                  style: TextStyle(color: AppTheme.white, fontSize: 14),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.black38,
                    hintText: 'Enter admin email',
                    hintStyle: TextStyle(color: AppTheme.white38),
                    prefixIcon: Icon(Icons.email_outlined, color: AppTheme.primaryAccent, size: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.white12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppTheme.primaryAccent, width: 1.5),
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                // Password Field
                Text(
                  'PASSWORD',
                  style: TextStyle(color: AppTheme.white38, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: TextStyle(color: AppTheme.white, fontSize: 14),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.black38,
                    hintText: 'Enter password',
                    hintStyle: TextStyle(color: AppTheme.white38),
                    prefixIcon: Icon(Icons.lock_outline, color: AppTheme.primaryAccent, size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        color: AppTheme.white38,
                        size: 18,
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.white12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppTheme.primaryAccent, width: 1.5),
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryAccent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 4,
                    ),
                    onPressed: authProvider.isLoading ? null : _handleAdminLogin,
                    child: authProvider.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'AUTHENTICATE AS ADMIN',
                                style: TextStyle(
                                  color: AppTheme.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(Icons.arrow_forward, color: AppTheme.white, size: 18),
                            ],
                          ),
                  ),
                ),

                const SizedBox(height: 20),

                // Hint Footer
                Center(
                  child: Text(
                    'Authorized Personnel Only • Secure Portal',
                    style: TextStyle(color: AppTheme.white38, fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

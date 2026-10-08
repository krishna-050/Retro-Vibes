import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:retro_vibes/provider/auth_provider.dart';
import 'package:retro_vibes/screens/bottom_navigation.dart';
import 'package:retro_vibes/screens/signup_screen.dart';
import 'package:retro_vibes/theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _rememberMe = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter email address')),
      );
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.login(
      email.isEmpty ? 'user@retrovibes.com' : email,
      password.isEmpty ? '123456' : password,
    );

    if (success && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const BottomNavigation()),
      );
    } else if (mounted && authProvider.errorMessage != null) {
      messenger.showSnackBar(
        SnackBar(content: Text(authProvider.errorMessage!)),
      );
    }
  }

  Future<void> _handleGoogleSignIn() async {
    final messenger = ScaffoldMessenger.of(context);
    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.signInWithGoogle();

    if (success && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const BottomNavigation()),
      );
    } else if (mounted && authProvider.errorMessage != null) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage!),
          backgroundColor: AppTheme.cardBackground,
        ),
      );
    }
  }

  Future<void> _handleGuestSignIn() async {
    final messenger = ScaffoldMessenger.of(context);
    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.signInAnonymously();

    if (success && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const BottomNavigation()),
      );
    } else if (mounted && authProvider.errorMessage != null) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage!),
          backgroundColor: AppTheme.cardBackground,
        ),
      );
    }
  }

  void _showForgotPasswordDialog(BuildContext context) {
    final TextEditingController resetEmailController = TextEditingController();
    if (_emailController.text.trim().isNotEmpty) {
      resetEmailController.text = _emailController.text.trim();
    }

    showDialog(
      context: context,
      builder: (dialogCtx) {
        bool isSending = false;
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              backgroundColor: AppTheme.cardBackground,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(
                'Forgot Password?',
                style: TextStyle(color: AppTheme.white, fontWeight: FontWeight.bold),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Enter your registered email address to receive a password reset link.',
                    style: TextStyle(color: AppTheme.white38, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: resetEmailController,
                    style: TextStyle(color: AppTheme.white),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white10,
                      hintText: 'Email address',
                      hintStyle: TextStyle(color: AppTheme.white38),
                      prefixIcon: Icon(Icons.email_outlined, color: AppTheme.primaryAccent),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isSending ? null : () => Navigator.pop(dialogCtx),
                  child: Text('Cancel', style: TextStyle(color: AppTheme.white38)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryAccent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: isSending
                      ? null
                      : () async {
                          final email = resetEmailController.text.trim();
                          if (email.isEmpty) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              const SnackBar(content: Text('Please enter email address')),
                            );
                            return;
                          }

                          setDialogState(() {
                            isSending = true;
                          });

                          final messenger = ScaffoldMessenger.of(context);
                          final authProvider = context.read<AuthProvider>();
                          final success = await authProvider.sendPasswordReset(email);

                          if (dialogCtx.mounted) {
                            Navigator.pop(dialogCtx);
                          }

                          if (success) {
                            if (context.mounted) {
                              showDialog(
                                context: context,
                                builder: (successCtx) => AlertDialog(
                                  backgroundColor: AppTheme.cardBackground,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  title: Row(
                                    children: [
                                      Icon(Icons.mark_email_read, color: AppTheme.primaryAccent, size: 24),
                                      const SizedBox(width: 8),
                                      Text('Reset Link Sent', style: TextStyle(color: AppTheme.white, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                  content: Text(
                                    'A password reset link has been sent to $email.\n\nPlease open your email inbox (or spam folder) and click the link to set a new password for your account.',
                                    style: TextStyle(color: AppTheme.white70, fontSize: 13, height: 1.4),
                                  ),
                                  actions: [
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryAccent),
                                      onPressed: () => Navigator.pop(successCtx),
                                      child: const Text('OK', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                              );
                            }
                          } else if (authProvider.errorMessage != null) {
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(authProvider.errorMessage!),
                                backgroundColor: Colors.redAccent,
                              ),
                            );
                          }
                        },
                  child: isSending
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Send Link', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    double mediaHeight = MediaQuery.of(context).size.height;
    double mediaWidth = MediaQuery.of(context).size.width;
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackground,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // Top Artwork Banner Header
            Stack(
              children: [
                Container(
                  height: mediaHeight * 0.32,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('assets/images/Sunset_retro.png'),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.scaffoldBackground,
                          AppTheme.scaffoldBackground.withValues(alpha: 0.5),
                          Colors.transparent,
                        ],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 12,
                  left: 0,
                  right: 0,
                  child: Column(
                    children: [
                      // Logo Text
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Retro ',
                            style: TextStyle(
                              color: AppTheme.white,
                              fontSize: mediaWidth * 0.075,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                          Text(
                            'Vibes',
                            style: TextStyle(
                              color: const Color(0xFFC85A32),
                              fontSize: mediaWidth * 0.08,
                              fontFamily: 'Cursive',
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'FEEL THE CLASSIC',
                        style: TextStyle(
                          color: AppTheme.white38,
                          fontSize: mediaWidth * 0.026,
                          letterSpacing: 2.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            Padding(
              padding: EdgeInsets.symmetric(horizontal: mediaWidth * 0.07),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: mediaHeight * 0.02),

                   // Welcome Back Heading
                  Text(
                    'Welcome Back!',
                    style: TextStyle(
                      color: AppTheme.white,
                      fontSize: mediaWidth * 0.065,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: mediaHeight * 0.006),
                  Text(
                    'Log in to continue your journey\nwith retro vibes.',
                    style: TextStyle(
                      color: AppTheme.white38,
                      fontSize: mediaWidth * 0.038,
                      height: 1.3,
                    ),
                  ),

                  SizedBox(height: mediaHeight * 0.03),

                  // Email Input
                  TextField(
                    controller: _emailController,
                    style: TextStyle(color: AppTheme.white),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppTheme.cardBackground.withValues(alpha: 0.6),
                      hintText: 'Email address',
                      hintStyle: TextStyle(color: AppTheme.white38),
                      prefixIcon: Icon(Icons.person_outline, color: AppTheme.primaryAccent),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  SizedBox(height: mediaHeight * 0.02),

                  // Password Input
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    style: TextStyle(color: AppTheme.white),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppTheme.cardBackground.withValues(alpha: 0.6),
                      hintText: 'Password',
                      hintStyle: TextStyle(color: AppTheme.white38),
                      prefixIcon: Icon(Icons.lock_outline, color: AppTheme.primaryAccent),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off : Icons.visibility,
                          color: AppTheme.white38,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  SizedBox(height: mediaHeight * 0.015),

                  // Remember Me & Forgot Password
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Checkbox(
                            value: _rememberMe,
                            activeColor: AppTheme.primaryAccent,
                            checkColor: AppTheme.white,
                            onChanged: (val) {
                              setState(() {
                                _rememberMe = val ?? false;
                              });
                            },
                          ),
                          Text(
                            'Remember me',
                            style: TextStyle(color: AppTheme.white38, fontSize: mediaWidth * 0.035),
                          ),
                        ],
                      ),
                      TextButton(
                        onPressed: () => _showForgotPasswordDialog(context),
                        child: Text(
                          'Forgot Password?',
                          style: TextStyle(
                            color: AppTheme.primaryAccent,
                            fontSize: mediaWidth * 0.035,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: mediaHeight * 0.025),

                  // Login Button
                  SizedBox(
                    width: double.infinity,
                    height: mediaHeight * 0.065,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 4,
                      ),
                      onPressed: authProvider.isLoading ? null : _handleLogin,
                      child: authProvider.isEmailLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : Text(
                              'Login',
                              style: TextStyle(
                                color: AppTheme.white,
                                fontSize: mediaWidth * 0.045,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),

                  SizedBox(height: mediaHeight * 0.02),

                  // Divider OR
                  Row(
                    children: [
                      const Expanded(child: Divider(color: Colors.white12)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'OR',
                          style: TextStyle(
                            color: AppTheme.white38,
                            fontSize: mediaWidth * 0.032,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Expanded(child: Divider(color: Colors.white12)),
                    ],
                  ),

                  SizedBox(height: mediaHeight * 0.02),

                  // Continue with Google Button
                  SizedBox(
                    width: double.infinity,
                    height: mediaHeight * 0.065,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: AppTheme.cardBackground.withValues(alpha: 0.8),
                        side: BorderSide(
                          color: AppTheme.primaryAccent.withValues(alpha: 0.6),
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: authProvider.isLoading ? null : _handleGoogleSignIn,
                      child: authProvider.isGoogleLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Image.asset(
                                    'assets/icons/google_logo.png',
                                    height: 20,
                                    width: 20,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Continue with Google',
                                  style: TextStyle(
                                    color: AppTheme.white,
                                    fontSize: mediaWidth * 0.04,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),

                  SizedBox(height: mediaHeight * 0.02),

                  // Guest Mode
                  Center(
                    child: TextButton(
                      onPressed: authProvider.isLoading ? null : _handleGuestSignIn,
                      child: authProvider.isGuestLoading
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : Text(
                              'Continue as Guest',
                              style: TextStyle(
                                color: AppTheme.white38,
                                fontSize: mediaWidth * 0.038,
                              ),
                            ),
                    ),
                  ),

                  SizedBox(height: mediaHeight * 0.02),

                  // Sign up redirect
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account? ",
                        style: TextStyle(color: AppTheme.white38, fontSize: mediaWidth * 0.038),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const SignUpScreen()),
                          );
                        },
                        child: Text(
                          'Sign Up',
                          style: TextStyle(
                            color: AppTheme.primaryAccent,
                            fontSize: mediaWidth * 0.038,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: mediaHeight * 0.04),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

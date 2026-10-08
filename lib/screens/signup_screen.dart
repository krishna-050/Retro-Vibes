import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:retro_vibes/provider/auth_provider.dart';
import 'package:retro_vibes/screens/bottom_navigation.dart';
import 'package:retro_vibes/screens/otp_verification_screen.dart';
import 'package:retro_vibes/services/otp_service.dart';
import 'package:retro_vibes/theme/app_theme.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isSendingOtp = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim().toLowerCase();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your full name.')),
      );
      return;
    }

    final emailError = OtpService.instance.validateEmail(email);
    if (emailError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(emailError), backgroundColor: Colors.orangeAccent),
      );
      return;
    }

    if (password.isEmpty || password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be at least 6 characters long.')),
      );
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match.')),
      );
      return;
    }

    setState(() => _isSendingOtp = true);

    try {
      // 1. Check if email is already registered in Firestore users
      final isAlreadyRegistered = await OtpService.instance.checkEmailRegistered(email);
      if (isAlreadyRegistered) {
        if (mounted) {
          setState(() => _isSendingOtp = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('An account with this email already exists. Please log in instead.'),
              backgroundColor: Colors.orangeAccent,
            ),
          );
        }
        return;
      }

      // 2. Generate and Send 4-Digit OTP to Email via EmailJS (BEFORE creating Firebase account)
      await OtpService.instance.sendOtpToEmail(email, userName: name);

      if (mounted) {
        setState(() => _isSendingOtp = false);
        final role = email.toLowerCase().contains('admin') ? 'admin' : 'user';

        // 3. Navigate to OTP Verification Screen WITHOUT creating account yet
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OtpVerificationScreen(
              email: email,
              name: name,
              password: password,
              role: role,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSendingOtp = false);
        final errText = e.toString().replaceAll('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errText),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.signInWithGoogle();

    if (success && mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const BottomNavigation()),
        (route) => false,
      );
    } else if (mounted && authProvider.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage!),
          backgroundColor: AppTheme.cardBackground,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    double mediaHeight = MediaQuery.of(context).size.height;
    double mediaWidth = MediaQuery.of(context).size.width;
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.scaffoldBackground,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: AppTheme.white, size: mediaWidth * 0.055),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: mediaWidth * 0.07),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Logo Header
              Center(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Retro ',
                          style: TextStyle(
                            color: AppTheme.white,
                            fontSize: mediaWidth * 0.08,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                        Text(
                          'Vibes',
                          style: TextStyle(
                            color: const Color(0xFFC85A32),
                            fontSize: mediaWidth * 0.085,
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

              SizedBox(height: mediaHeight * 0.03),

              // Create Your Account Heading
              Text(
                'Create Your Account',
                style: TextStyle(
                  color: AppTheme.white,
                  fontSize: mediaWidth * 0.065,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: mediaHeight * 0.006),
              Text(
                'Join the Retro Vibes community and\nkeep the good music going.',
                style: TextStyle(
                  color: AppTheme.white38,
                  fontSize: mediaWidth * 0.038,
                  height: 1.3,
                ),
              ),

              SizedBox(height: mediaHeight * 0.03),

              // Full Name Field
              _buildTextField(
                controller: _nameController,
                hintText: 'Full Name',
                prefixIcon: Icons.person_outline,
                mediaWidth: mediaWidth,
              ),

              SizedBox(height: mediaHeight * 0.02),

              // Email Address Field
              _buildTextField(
                controller: _emailController,
                hintText: 'Email Address',
                prefixIcon: Icons.email_outlined,
                mediaWidth: mediaWidth,
              ),

              SizedBox(height: mediaHeight * 0.02),

              // Password Field
              _buildTextField(
                controller: _passwordController,
                hintText: 'Password',
                prefixIcon: Icons.lock_outlined,
                obscureText: _obscurePassword,
                mediaWidth: mediaWidth,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: AppTheme.white38,
                    size: mediaWidth * 0.05,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
              ),

              SizedBox(height: mediaHeight * 0.02),

              // Confirm Password Field
              _buildTextField(
                controller: _confirmPasswordController,
                hintText: 'Confirm Password',
                prefixIcon: Icons.lock_outlined,
                obscureText: _obscureConfirmPassword,
                mediaWidth: mediaWidth,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: AppTheme.white38,
                    size: mediaWidth * 0.05,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureConfirmPassword = !_obscureConfirmPassword;
                    });
                  },
                ),
              ),

              SizedBox(height: mediaHeight * 0.03),

              // Main Sign Up Button
              SizedBox(
                width: double.infinity,
                height: mediaHeight * 0.06,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFC85A32),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 4,
                  ),
                  onPressed: (_isSendingOtp || authProvider.isLoading) ? null : _handleSignUp,
                  child: (_isSendingOtp || authProvider.isLoading)
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Sign Up',
                              style: TextStyle(
                                color: AppTheme.white,
                                fontSize: mediaWidth * 0.045,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.arrow_forward,
                              color: AppTheme.white,
                              size: mediaWidth * 0.05,
                            ),
                          ],
                        ),
                ),
              ),

              SizedBox(height: mediaHeight * 0.025),

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

              SizedBox(height: mediaHeight * 0.025),

              // Google Sign-In Outlined Button
              SizedBox(
                width: double.infinity,
                height: mediaHeight * 0.06,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppTheme.primaryAccent.withValues(alpha: 0.6), width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
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

              SizedBox(height: mediaHeight * 0.03),

              // Bottom Login Link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Already have an account? ',
                    style: TextStyle(
                      color: AppTheme.white38,
                      fontSize: mediaWidth * 0.035,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: Text(
                      'Login',
                      style: TextStyle(
                        color: const Color(0xFFC85A32),
                        fontSize: mediaWidth * 0.035,
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
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData prefixIcon,
    required double mediaWidth,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBackground.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white12, width: 1),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        style: TextStyle(color: AppTheme.white, fontSize: mediaWidth * 0.04),
        textAlignVertical: TextAlignVertical.center,
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 16, right: 12),
            child: Icon(prefixIcon, color: AppTheme.white38, size: mediaWidth * 0.055),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
          hintText: hintText,
          hintStyle: TextStyle(color: AppTheme.white38, fontSize: mediaWidth * 0.038),
          suffixIcon: suffixIcon,
        ),
      ),
    );
  }
}

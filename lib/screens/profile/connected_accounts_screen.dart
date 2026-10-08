import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:retro_vibes/provider/auth_provider.dart';
import 'package:retro_vibes/screens/signup_screen.dart';
import 'package:retro_vibes/theme/app_theme.dart';

class ConnectedAccountsScreen extends StatelessWidget {
  const ConnectedAccountsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    double mediaWidth = MediaQuery.of(context).size.width;
    final authProvider = context.watch<AuthProvider>();
    final currentUser = authProvider.currentUser;

    final isGoogle = currentUser?.provider == 'google';
    final isEmail = currentUser?.provider == 'email';
    final isGuest = currentUser?.isGuest == true || currentUser?.provider == 'anonymous';

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.scaffoldBackground,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: AppTheme.white, size: mediaWidth * 0.055),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Connected Accounts', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('AUTHENTICATION PROVIDERS', style: TextStyle(color: AppTheme.white38, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
            const SizedBox(height: 12),

            // Google Account Card
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: AppTheme.cardBackground.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white12),
              ),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  child: Image.asset(
                    'assets/icons/google_logo.png',
                    height: 20,
                    width: 20,
                    fit: BoxFit.contain,
                  ),
                ),
                title: Text('Google Sign-In', style: TextStyle(color: AppTheme.white, fontWeight: FontWeight.w600)),
                subtitle: Text(
                  isGoogle ? 'Connected (${currentUser?.email})' : (isGuest ? 'Tap to link Google account' : 'Not linked'),
                  style: TextStyle(color: AppTheme.white38, fontSize: 12),
                ),
                trailing: isGoogle
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Connected', style: TextStyle(color: AppTheme.primaryAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                          const SizedBox(width: 4),
                          Icon(Icons.check_circle, color: AppTheme.primaryAccent, size: 18),
                        ],
                      )
                    : OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: AppTheme.primaryAccent),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                        onPressed: () async {
                          final messenger = ScaffoldMessenger.of(context);
                          final success = await authProvider.signInWithGoogle();
                          if (success) {
                            messenger.showSnackBar(
                              const SnackBar(content: Text('Connected to Google Account!')),
                            );
                          }
                        },
                        child: Text('Connect', style: TextStyle(color: AppTheme.primaryAccent, fontSize: 12)),
                      ),
              ),
            ),

            // Email & Password Card
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: AppTheme.cardBackground.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white12),
              ),
              child: ListTile(
                leading: Icon(Icons.email_outlined, color: AppTheme.primaryAccent, size: 28),
                title: Text('Email & Password', style: TextStyle(color: AppTheme.white, fontWeight: FontWeight.w600)),
                subtitle: Text(
                  isEmail ? 'Connected (${currentUser?.email})' : (isGuest ? 'Tap to create permanent email account' : 'Not linked'),
                  style: TextStyle(color: AppTheme.white38, fontSize: 12),
                ),
                trailing: isEmail
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Connected', style: TextStyle(color: AppTheme.primaryAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                          const SizedBox(width: 4),
                          Icon(Icons.check_circle, color: AppTheme.primaryAccent, size: 18),
                        ],
                      )
                    : OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: AppTheme.primaryAccent),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const SignUpScreen()),
                          );
                        },
                        child: Text(isGuest ? 'Upgrade' : 'Link', style: TextStyle(color: AppTheme.primaryAccent, fontSize: 12)),
                      ),
              ),
            ),

            if (isGuest) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primaryAccent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.primaryAccent.withValues(alpha: 0.4)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: AppTheme.primaryAccent, size: 20),
                        const SizedBox(width: 8),
                        Text('Guest Account Upgrade', style: TextStyle(color: AppTheme.white, fontWeight: FontWeight.bold, fontSize: 14)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Connecting Google or Email to your Guest account will preserve your saved playlists and favorites while securing your account.',
                      style: TextStyle(color: AppTheme.white70, fontSize: 12, height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

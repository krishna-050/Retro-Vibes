import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:retro_vibes/provider/auth_provider.dart';
import 'package:retro_vibes/provider/music_provider.dart';
import 'package:retro_vibes/screens/login_screen.dart';
import 'package:retro_vibes/theme/app_theme.dart';

class SecurityLoginScreen extends StatefulWidget {
  const SecurityLoginScreen({super.key});

  @override
  State<SecurityLoginScreen> createState() => _SecurityLoginScreenState();
}

class _SecurityLoginScreenState extends State<SecurityLoginScreen> {
  void _showChangePasswordDialog(BuildContext context) {
    final TextEditingController currentPasswordController = TextEditingController();
    final TextEditingController newPasswordController = TextEditingController();
    final TextEditingController confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        bool isUpdating = false;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppTheme.cardBackground,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text('Change Password', style: TextStyle(color: AppTheme.white, fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: currentPasswordController,
                    obscureText: true,
                    style: TextStyle(color: AppTheme.white),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white10,
                      hintText: 'Current Password',
                      hintStyle: TextStyle(color: AppTheme.white38),
                      prefixIcon: Icon(Icons.lock_outline, color: AppTheme.primaryAccent),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: newPasswordController,
                    obscureText: true,
                    style: TextStyle(color: AppTheme.white),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white10,
                      hintText: 'New Password (min 6 chars)',
                      hintStyle: TextStyle(color: AppTheme.white38),
                      prefixIcon: Icon(Icons.key, color: AppTheme.primaryAccent),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: confirmPasswordController,
                    obscureText: true,
                    style: TextStyle(color: AppTheme.white),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white10,
                      hintText: 'Confirm New Password',
                      hintStyle: TextStyle(color: AppTheme.white38),
                      prefixIcon: Icon(Icons.key_outlined, color: AppTheme.primaryAccent),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isUpdating ? null : () => Navigator.pop(ctx),
                  child: Text('Cancel', style: TextStyle(color: AppTheme.white38)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryAccent),
                  onPressed: isUpdating
                      ? null
                      : () async {
                          final currentPass = currentPasswordController.text.trim();
                          final newPass = newPasswordController.text.trim();
                          final confirmPass = confirmPasswordController.text.trim();

                          if (currentPass.isEmpty || newPass.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please enter all password fields')),
                            );
                            return;
                          }

                          if (newPass.length < 6) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('New password must be at least 6 characters')),
                            );
                            return;
                          }

                          if (newPass != confirmPass) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('New passwords do not match')),
                            );
                            return;
                          }

                          setDialogState(() {
                            isUpdating = true;
                          });

                          final messenger = ScaffoldMessenger.of(context);
                          try {
                            final user = FirebaseAuth.instance.currentUser;
                            if (user != null && user.email != null) {
                              final credential = EmailAuthProvider.credential(
                                email: user.email!,
                                password: currentPass,
                              );
                              await user.reauthenticateWithCredential(credential);
                              await user.updatePassword(newPass);

                              if (ctx.mounted) {
                                Navigator.pop(ctx);
                              }
                              messenger.showSnackBar(
                                const SnackBar(content: Text('Password updated successfully!')),
                              );
                            }
                          } on FirebaseAuthException catch (e) {
                            setDialogState(() {
                              isUpdating = false;
                            });
                            String errorMsg = e.message ?? 'Failed to update password';
                            if (e.code == 'wrong-password') {
                              errorMsg = 'Current password is incorrect';
                            }
                            messenger.showSnackBar(
                              SnackBar(content: Text(errorMsg), backgroundColor: Colors.redAccent),
                            );
                          } catch (e) {
                            setDialogState(() {
                              isUpdating = false;
                            });
                            messenger.showSnackBar(
                              SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent),
                            );
                          }
                        },
                  child: isUpdating
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Update Password', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDeleteAccount(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        title: Text('Delete Account Permanently?', style: TextStyle(color: AppTheme.white)),
        content: Text(
          'This action is irreversible. All your profile data, custom playlists, and favorites will be deleted.',
          style: TextStyle(color: AppTheme.white70, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text('Cancel', style: TextStyle(color: AppTheme.white38)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              Navigator.pop(dialogCtx);
              context.read<MusicProvider>().resetPlaybackOnLogout();
              final messenger = ScaffoldMessenger.of(context);
              final success = await authProvider.deleteAccount();
              if (success && context.mounted) {
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Your account and user data have been permanently deleted.'),
                    backgroundColor: Colors.redAccent,
                  ),
                );
                Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              } else if (context.mounted && authProvider.errorMessage != null) {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(authProvider.errorMessage!),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              }
            },
            child: const Text('Delete Permanently', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double mediaWidth = MediaQuery.of(context).size.width;
    final authProvider = context.watch<AuthProvider>();
    final currentUser = authProvider.currentUser;

    final bool isEmailUser = currentUser?.provider == 'email';

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.scaffoldBackground,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: AppTheme.white, size: mediaWidth * 0.055),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Security & Login', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Password Section
            Text('PASSWORD MANAGEMENT', style: TextStyle(color: AppTheme.white38, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: AppTheme.cardBackground.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white12),
              ),
              child: ListTile(
                leading: Icon(Icons.lock_reset, color: AppTheme.primaryAccent),
                title: Text('Change Password', style: TextStyle(color: AppTheme.white, fontWeight: FontWeight.w600)),
                subtitle: Text(
                  isEmailUser ? 'Update your account password securely' : 'Password managed by ${currentUser?.provider.toUpperCase() ?? 'OAuth'}',
                  style: TextStyle(color: AppTheme.white38, fontSize: 12),
                ),
                trailing: isEmailUser
                    ? Icon(Icons.arrow_forward_ios, color: AppTheme.white38, size: 16)
                    : Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(6)),
                        child: const Text('OAuth', style: TextStyle(color: Colors.white70, fontSize: 11)),
                      ),
                onTap: isEmailUser ? () => _showChangePasswordDialog(context) : null,
              ),
            ),

            const SizedBox(height: 24),

            // Active Sessions
            Text('ACTIVE SESSIONS', style: TextStyle(color: AppTheme.white38, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: AppTheme.cardBackground.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white12),
              ),
              child: ListTile(
                leading: Icon(Icons.phone_android, color: AppTheme.primaryAccent),
                title: Text('This Mobile Device', style: TextStyle(color: AppTheme.white, fontWeight: FontWeight.w600)),
                subtitle: Text('Android Session • Currently Active', style: TextStyle(color: AppTheme.white38, fontSize: 12)),
                trailing: const Icon(Icons.check_circle, color: Colors.greenAccent, size: 20),
              ),
            ),

            const SizedBox(height: 32),

            // Danger Zone: Delete Account
            Text('DANGER ZONE', style: TextStyle(color: Colors.redAccent.shade100, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: Colors.red.shade900.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.red.shade800.withValues(alpha: 0.5)),
              ),
              child: ListTile(
                leading: const Icon(Icons.delete_forever, color: Colors.redAccent),
                title: const Text('Delete Account', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                subtitle: Text('Permanently remove your profile and all saved preferences', style: TextStyle(color: AppTheme.white38, fontSize: 12)),
                onTap: () => _confirmDeleteAccount(context, authProvider),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

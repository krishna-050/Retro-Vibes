import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:retro_vibes/provider/auth_provider.dart';
import 'package:retro_vibes/provider/library_provider.dart';
import 'package:retro_vibes/provider/music_provider.dart';
import 'package:retro_vibes/screens/library_screen.dart';
import 'package:retro_vibes/screens/login_screen.dart';
import 'package:retro_vibes/screens/playlist_detail_screen.dart';
import 'package:retro_vibes/screens/profile/about_screen.dart';
import 'package:retro_vibes/screens/profile/appearance_screen.dart';
import 'package:retro_vibes/screens/profile/connected_accounts_screen.dart';
import 'package:retro_vibes/screens/profile/edit_profile_screen.dart';
import 'package:retro_vibes/screens/profile/help_support_screen.dart';
import 'package:retro_vibes/screens/profile/notification_settings_screen.dart';
import 'package:retro_vibes/screens/profile/personal_info_screen.dart';
import 'package:retro_vibes/screens/profile/playback_settings_screen.dart';
import 'package:retro_vibes/screens/profile/recently_played_screen.dart';
import 'package:retro_vibes/screens/profile/security_login_screen.dart';
import 'package:retro_vibes/screens/signup_screen.dart';
import 'package:retro_vibes/theme/app_theme.dart';
import 'package:retro_vibes/widgets/profile/profile_avatar.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _showLogoutDialog(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Log Out?', style: TextStyle(color: AppTheme.white, fontWeight: FontWeight.bold)),
        content: Text(
          'Are you sure you want to log out of Retro Vibes?',
          style: TextStyle(color: AppTheme.white70, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: AppTheme.white38)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryAccent),
            onPressed: () async {
              Navigator.pop(ctx);
              // Safely stop current audio playback immediately on logout
              context.read<MusicProvider>().resetPlaybackOnLogout();
              await authProvider.logout();
              if (context.mounted) {
                Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            child: const Text('Log Out', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showTermsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Terms of Service', style: TextStyle(color: AppTheme.white, fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Text(
            'Welcome to Retro Vibes! By using our app, you agree to enjoy our music streaming services respectfully and comply with copyright terms. User account data is securely stored and managed via Firebase Authentication.',
            style: TextStyle(color: AppTheme.white70, fontSize: 13, height: 1.4),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Close', style: TextStyle(color: AppTheme.primaryAccent)),
          ),
        ],
      ),
    );
  }

  void _showPrivacyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Privacy Policy', style: TextStyle(color: AppTheme.white, fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Text(
            'Retro Vibes respects your privacy. All user profile data, playlists, and preferences are securely encrypted and stored on Cloud Firestore. We do not sell or share personal information.',
            style: TextStyle(color: AppTheme.white70, fontSize: 13, height: 1.4),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Close', style: TextStyle(color: AppTheme.primaryAccent)),
          ),
        ],
      ),
    );
  }

  void _showGuestUpgradeBottomSheet(BuildContext context, AuthProvider authProvider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Upgrade Your Account',
                style: TextStyle(color: AppTheme.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                'Link your guest account to Google or Email to save your music forever.',
                style: TextStyle(color: AppTheme.white38, fontSize: 13),
              ),
              const SizedBox(height: 20),
              // Option 1: Continue with Google
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppTheme.primaryAccent),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    Navigator.pop(ctx);
                    final messenger = ScaffoldMessenger.of(context);
                    final success = await authProvider.signInWithGoogle();
                    if (success) {
                      messenger.showSnackBar(
                        const SnackBar(content: Text('Account successfully upgraded with Google!')),
                      );
                    }
                  },
                  icon: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Image.asset(
                      'assets/icons/google_logo.png',
                      height: 18,
                      width: 18,
                      fit: BoxFit.contain,
                    ),
                  ),
                  label: Text('Continue with Google', style: TextStyle(color: AppTheme.white, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 12),
              // Option 2: Create Email Account
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryAccent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SignUpScreen()),
                    );
                  },
                  icon: const Icon(Icons.email_outlined, color: Colors.white, size: 20),
                  label: const Text('Create with Email & Password', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    double mediaHeight = MediaQuery.of(context).size.height;
    double mediaWidth = MediaQuery.of(context).size.width;

    final authProvider = context.watch<AuthProvider>();
    final currentUser = authProvider.currentUser;

    final bool isGuest = currentUser?.isGuest == true || currentUser?.provider == 'anonymous';

    if (isGuest) {
      return _buildMinimalGuestProfile(context, authProvider, mediaHeight, mediaWidth);
    }

    return _buildFullRegisteredProfile(context, authProvider, currentUser, mediaHeight, mediaWidth);
  }

  /// Minimal Guest Profile UI
  Widget _buildMinimalGuestProfile(
    BuildContext context,
    AuthProvider authProvider,
    double mediaHeight,
    double mediaWidth,
  ) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackground,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: mediaWidth * 0.06),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(),

              // Guest Avatar Icon
              Container(
                width: mediaWidth * 0.3,
                height: mediaWidth * 0.3,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.cardBackground,
                  border: Border.all(color: AppTheme.primaryAccent, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryAccent.withValues(alpha: 0.25),
                      blurRadius: 16,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    Icons.person_outline,
                    color: AppTheme.primaryAccent,
                    size: mediaWidth * 0.16,
                  ),
                ),
              ),

              SizedBox(height: mediaHeight * 0.025),

              // Title
              Text(
                'Guest',
                style: TextStyle(
                  color: AppTheme.white,
                  fontSize: mediaWidth * 0.07,
                  fontWeight: FontWeight.bold,
                ),
              ),

              SizedBox(height: mediaHeight * 0.008),

              // Subtitle
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.cardBackground,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.primaryAccent.withValues(alpha: 0.4)),
                ),
                child: Text(
                  'Temporary Account',
                  style: TextStyle(
                    color: AppTheme.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              SizedBox(height: mediaHeight * 0.03),

              // Notice Banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.cardBackground.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white12),
                ),
                child: Text(
                  'You are using a guest account. Upgrade to a permanent account to save your music preferences across devices.',
                  style: TextStyle(
                    color: AppTheme.white38,
                    fontSize: 13,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              const Spacer(),

              // Create Account Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryAccent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 4,
                  ),
                  onPressed: () {
                    _showGuestUpgradeBottomSheet(context, authProvider);
                  },
                  icon: const Icon(Icons.person_add_alt_1, color: Colors.white, size: 20),
                  label: const Text(
                    'Create Account',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),

              SizedBox(height: mediaHeight * 0.015),

              // Exit Guest Session Button
              TextButton.icon(
                onPressed: () {
                  _showLogoutDialog(context, authProvider);
                },
                icon: const Icon(Icons.exit_to_app, color: AppTheme.white38, size: 18),
                label: Text(
                  'Exit Guest Session',
                  style: TextStyle(color: AppTheme.white38, fontSize: 14),
                ),
              ),

              SizedBox(height: mediaHeight * 0.04),
            ],
          ),
        ),
      ),
    );
  }

  /// Full Registered Profile UI for Non-Guest Users
  Widget _buildFullRegisteredProfile(
    BuildContext context,
    AuthProvider authProvider,
    dynamic currentUser,
    double mediaHeight,
    double mediaWidth,
  ) {
    String providerLabel = 'Email Account';
    IconData providerIcon = Icons.email_outlined;

    if (currentUser?.provider == 'google') {
      providerLabel = 'Google Account';
      providerIcon = Icons.g_mobiledata;
    }

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: mediaWidth * 0.05),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: mediaHeight * 0.03),

              // PROFILE HEADER
              Center(
                child: Column(
                  children: [
                    ProfileAvatar(
                      user: currentUser,
                      radius: (mediaWidth * 0.16).clamp(44.0, 72.0),
                      borderWidth: 3,
                    ),
                    SizedBox(height: mediaHeight * 0.015),
                    Text(
                      currentUser?.name.isNotEmpty == true ? currentUser!.name : 'Retro Listener',
                      style: TextStyle(
                        color: AppTheme.white,
                        fontSize: (mediaWidth * 0.06).clamp(20.0, 26.0),
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: mediaHeight * 0.004),
                    Text(
                      currentUser?.email.isNotEmpty == true ? currentUser!.email : 'user@retrovibes.com',
                      style: TextStyle(
                        color: AppTheme.white38,
                        fontSize: (mediaWidth * 0.035).clamp(12.0, 15.0),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: mediaHeight * 0.008),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.cardBackground,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.primaryAccent.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(providerIcon, color: AppTheme.primaryAccent, size: 14),
                          const SizedBox(width: 6),
                          Text(
                            providerLabel,
                            style: TextStyle(
                              color: AppTheme.white70,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: mediaHeight * 0.02),

                    SizedBox(
                      height: 38,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: AppTheme.primaryAccent.withValues(alpha: 0.6)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                          );
                        },
                        icon: Icon(Icons.edit, size: 16, color: AppTheme.primaryAccent),
                        label: Text('Edit Profile', style: TextStyle(color: AppTheme.primaryAccent, fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: mediaHeight * 0.03),

              // SECTION 1: YOUR MUSIC
              _buildSectionHeader('YOUR MUSIC'),
              Consumer2<MusicProvider, LibraryProvider>(
                builder: (context, musicProvider, libraryProvider, child) {
                  final favoritesCount = musicProvider.likedSongs.length;
                  final playlistsCount = musicProvider.customPlaylists.length;
                  final recentCount = libraryProvider.recentlyPlayed.length;

                  return Column(
                    children: [
                      _buildListTile(
                        icon: Icons.favorite_border,
                        title: 'Favorites',
                        trailingText: '$favoritesCount songs',
                        mediaWidth: mediaWidth,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PlaylistDetailScreen(
                                title: 'Favorites',
                                image: 'assets/images/Retro_Favourites.png',
                                description: 'Your collection of loved retro hits.',
                                songs: musicProvider.likedSongs,
                              ),
                            ),
                          );
                        },
                      ),
                      _buildListTile(
                        icon: Icons.playlist_play,
                        title: 'My Playlists',
                        trailingText: '$playlistsCount playlists',
                        mediaWidth: mediaWidth,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const LibraryScreen()),
                          );
                        },
                      ),
                      _buildListTile(
                        icon: Icons.history,
                        title: 'Recently Played',
                        trailingText: recentCount > 0 ? '$recentCount tracks' : 'View History',
                        mediaWidth: mediaWidth,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const RecentlyPlayedScreen()),
                          );
                        },
                      ),
                    ],
                  );
                },
              ),

              SizedBox(height: mediaHeight * 0.025),

              // SECTION 2: ACCOUNT
              _buildSectionHeader('ACCOUNT'),
              _buildListTile(
                icon: Icons.person_outline,
                title: 'Personal Information',
                mediaWidth: mediaWidth,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PersonalInformationScreen()),
                  );
                },
              ),
              _buildListTile(
                icon: Icons.security_outlined,
                title: 'Security & Login',
                mediaWidth: mediaWidth,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SecurityLoginScreen()),
                  );
                },
              ),
              _buildListTile(
                icon: Icons.link_outlined,
                title: 'Connected Accounts',
                mediaWidth: mediaWidth,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ConnectedAccountsScreen()),
                  );
                },
              ),

              SizedBox(height: mediaHeight * 0.025),

              // SECTION 3: PREFERENCES
              _buildSectionHeader('PREFERENCES'),
              _buildListTile(
                icon: Icons.notifications_outlined,
                title: 'Notifications',
                mediaWidth: mediaWidth,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const NotificationSettingsScreen()),
                  );
                },
              ),
              _buildListTile(
                icon: Icons.palette_outlined,
                title: 'Appearance',
                mediaWidth: mediaWidth,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AppearanceScreen()),
                  );
                },
              ),
              _buildListTile(
                icon: Icons.play_circle_outline,
                title: 'Playback',
                mediaWidth: mediaWidth,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PlaybackSettingsScreen()),
                  );
                },
              ),

              SizedBox(height: mediaHeight * 0.025),

              // SECTION 4: SUPPORT
              _buildSectionHeader('SUPPORT'),
              _buildListTile(
                icon: Icons.help_outline,
                title: 'Help & Support',
                mediaWidth: mediaWidth,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const HelpSupportScreen()),
                  );
                },
              ),
              _buildListTile(
                icon: Icons.info_outline,
                title: 'About Retro Vibes',
                mediaWidth: mediaWidth,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AboutScreen()),
                  );
                },
              ),
              _buildListTile(
                icon: Icons.lock_outline,
                title: 'Privacy Policy',
                mediaWidth: mediaWidth,
                onTap: () => _showPrivacyDialog(context),
              ),
              _buildListTile(
                icon: Icons.article_outlined,
                title: 'Terms of Service',
                mediaWidth: mediaWidth,
                onTap: () => _showTermsDialog(context),
              ),

              SizedBox(height: mediaHeight * 0.03),

              // LOG OUT BUTTON
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade900.withValues(alpha: 0.35),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    side: BorderSide(color: Colors.red.shade800.withValues(alpha: 0.5)),
                  ),
                  onPressed: () => _showLogoutDialog(context, authProvider),
                  icon: const Icon(Icons.logout, color: Colors.redAccent, size: 20),
                  label: const Text(
                    'Log Out',
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              SizedBox(height: mediaHeight * 0.05),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8),
        child: Text(
          title,
          style: TextStyle(
            color: AppTheme.white38,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    required double mediaWidth,
    required VoidCallback onTap,
    String? trailingText,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
       child: Material(
        color: Colors.transparent,
        child: ListTile(
          dense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          leading: Icon(icon, color: AppTheme.primaryAccent, size: (mediaWidth * 0.06).clamp(20.0, 24.0)),
          title: Text(
            title,
            style: TextStyle(
              color: AppTheme.white,
              fontSize: (mediaWidth * 0.038).clamp(13.0, 16.0),
              fontWeight: FontWeight.w600,
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (trailingText != null)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text(trailingText, style: TextStyle(color: AppTheme.white38, fontSize: 12)),
                ),
              Icon(
                Icons.arrow_forward_ios_sharp,
                color: AppTheme.white38,
                size: (mediaWidth * 0.035).clamp(12.0, 16.0),
              ),
            ],
          ),
          onTap: onTap,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:retro_vibes/provider/song_provider.dart';
import 'package:retro_vibes/screens/admin/add_song_screen.dart';
import 'package:retro_vibes/screens/admin/manage_songs_screen.dart';
import 'package:retro_vibes/screens/admin/manage_users_screen.dart';
import 'package:retro_vibes/theme/app_theme.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final songProvider = context.watch<SongProvider>();
    final publishedSongs = songProvider.publishedSongs;
    final featuredSongs = songProvider.featuredSongs;
    final totalPlays = publishedSongs.fold<int>(0, (sum, s) => sum + s.playCount);

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.cardBackground,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: AppTheme.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Image.asset(
              'assets/icons/retro_vibes_icon.png',
              width: 26,
              height: 26,
              errorBuilder: (c, e, s) => Icon(Icons.admin_panel_settings, color: AppTheme.primaryAccent, size: 24),
            ),
            const SizedBox(width: 10),
            Text(
              'ADMIN DASHBOARD',
              style: TextStyle(
                color: AppTheme.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryAccent,
                    AppTheme.primaryAccent.withValues(alpha: 0.7),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Image.asset(
                        'assets/icons/retro_vibes_icon.png',
                        width: 32,
                        height: 32,
                        errorBuilder: (c, e, s) => Icon(Icons.admin_panel_settings, color: AppTheme.white, size: 28),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Admin Portal',
                        style: TextStyle(
                          color: AppTheme.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Upload licensed audio tracks, manage catalog metadata, and monitor platform metrics.',
                    style: TextStyle(color: AppTheme.white70, fontSize: 13, height: 1.3),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            // Platform Overview Metrics
            Text(
              'PLATFORM OVERVIEW',
              style: TextStyle(
                color: AppTheme.white38,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    title: 'Total Songs',
                    value: publishedSongs.length.toString(),
                    icon: Icons.music_note,
                    color: const Color(0xFFC85A32),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    title: 'Featured',
                    value: featuredSongs.length.toString(),
                    icon: Icons.star,
                    color: const Color(0xFFFFD700),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    title: 'Total Plays',
                    value: totalPlays.toString(),
                    icon: Icons.play_arrow,
                    color: const Color(0xFF4CAF50),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),

            // Management Actions
            Text(
              'MANAGEMENT MODULES',
              style: TextStyle(
                color: AppTheme.white38,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 12),

            _buildActionTile(
              context,
              title: 'Add New Song',
              subtitle: 'Upload MP3 audio & cover art to Storage & Firestore',
              icon: Icons.cloud_upload_outlined,
              iconColor: const Color(0xFFC85A32),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddSongScreen()),
                );
              },
            ),

            const SizedBox(height: 12),

            _buildActionTile(
              context,
              title: 'Manage Song Catalog',
              subtitle: 'Publish, unpublish, feature, edit, or delete tracks',
              icon: Icons.library_music_outlined,
              iconColor: const Color(0xFF64B5F6),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ManageSongsScreen()),
                );
              },
            ),

            const SizedBox(height: 12),

            _buildActionTile(
              context,
              title: 'Users & Roles',
              subtitle: 'View user activity, status, and admin authorization',
              icon: Icons.people_outline,
              iconColor: const Color(0xFF81C784),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ManageUsersScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: AppTheme.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(color: AppTheme.white38, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 24),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: AppTheme.white,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: AppTheme.white38, fontSize: 12),
        ),
        trailing: Icon(Icons.arrow_forward_ios, color: AppTheme.white38, size: 16),
      ),
    );
  }
}

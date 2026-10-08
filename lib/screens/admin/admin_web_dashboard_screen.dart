import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:retro_vibes/model/song.dart';
import 'package:retro_vibes/provider/auth_provider.dart';
import 'package:retro_vibes/provider/song_provider.dart';
import 'package:retro_vibes/screens/admin/add_song_screen.dart';
import 'package:retro_vibes/screens/admin/edit_song_dialog.dart';
import 'package:retro_vibes/screens/admin/manage_songs_screen.dart';
import 'package:retro_vibes/screens/admin/manage_users_screen.dart';
import 'package:retro_vibes/theme/app_theme.dart';

class AdminWebDashboardScreen extends StatefulWidget {
  const AdminWebDashboardScreen({super.key});

  @override
  State<AdminWebDashboardScreen> createState() => _AdminWebDashboardScreenState();
}

class _AdminWebDashboardScreenState extends State<AdminWebDashboardScreen> {
  int _selectedTabIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  String _catalogQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width >= 900;
    final authProvider = context.watch<AuthProvider>();
    final currentUser = authProvider.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFF0F0B09),
      body: Row(
        children: [
          // 1. Sidebar Navigation (Left Panel for Desktop)
          if (isDesktop) _buildDesktopSidebar(context, currentUser?.name, currentUser?.email),

          // 2. Main Content Area
          Expanded(
            child: Column(
              children: [
                // Top Header Bar
                _buildTopAppBar(context, isDesktop, currentUser?.name),

                // Selected Tab Body
                Expanded(
                  child: IndexedStack(
                    index: _selectedTabIndex,
                    children: [
                      _buildOverviewTab(context, size.width),
                      const ManageSongsScreen(),
                      const AddSongScreen(),
                      const ManageUsersScreen(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      drawer: isDesktop ? null : Drawer(child: _buildDesktopSidebar(context, currentUser?.name, currentUser?.email)),
    );
  }

  Widget _buildDesktopSidebar(BuildContext context, String? name, String? email) {
    return Container(
      width: 280,
      color: AppTheme.cardBackground,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Web Portal Branding with Retro Vibes Logo
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryAccent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.primaryAccent, width: 1.5),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    'assets/icons/retro_vibes_icon.png',
                    width: 32,
                    height: 32,
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, s) => const Icon(Icons.music_note, color: Colors.white, size: 24),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Retro ',
                          style: TextStyle(color: AppTheme.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Vibes',
                          style: TextStyle(color: AppTheme.primaryAccent, fontSize: 18, fontFamily: 'Cursive', fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const Text(
                      'ADMIN WEB PORTAL',
                      style: TextStyle(color: Color(0xFFFFD700), fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),

          Text(
            'NAVIGATION',
            style: TextStyle(color: AppTheme.white38, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2),
          ),
          const SizedBox(height: 12),

          // Sidebar Navigation Tiles
          _buildSidebarNavItem(0, Icons.dashboard_outlined, Icons.dashboard, 'Overview'),
          _buildSidebarNavItem(1, Icons.library_music_outlined, Icons.library_music, 'Song Catalog'),
          _buildSidebarNavItem(2, Icons.cloud_upload_outlined, Icons.cloud_upload, 'Upload Track'),
          _buildSidebarNavItem(3, Icons.people_outline, Icons.people, 'User Management'),

          const Spacer(),

          const Divider(color: Colors.white12),
          const SizedBox(height: 12),

          // Admin User Footer Profile
          Row(
            children: [
              CircleAvatar(
                backgroundColor: const Color(0xFFFFD700),
                radius: 18,
                child: Text(
                  name != null && name.isNotEmpty ? name[0].toUpperCase() : 'A',
                  style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name ?? 'Administrator',
                      style: TextStyle(color: AppTheme.white, fontSize: 13, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      email ?? 'admin@retrovibes.com',
                      style: TextStyle(color: AppTheme.white38, fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.logout, color: Colors.redAccent, size: 20),
                tooltip: 'Log Out',
                onPressed: () async {
                  await context.read<AuthProvider>().logout();
                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarNavItem(int index, IconData unselectedIcon, IconData selectedIcon, String label) {
    final isSelected = _selectedTabIndex == index;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? AppTheme.primaryAccent.withValues(alpha: 0.2) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: isSelected ? Border.all(color: AppTheme.primaryAccent, width: 1) : null,
      ),
      child: ListTile(
        onTap: () {
          setState(() {
            _selectedTabIndex = index;
          });
          if (Scaffold.of(context).isDrawerOpen) {
            Navigator.pop(context);
          }
        },
        leading: Icon(
          isSelected ? selectedIcon : unselectedIcon,
          color: isSelected ? AppTheme.primaryAccent : AppTheme.white38,
          size: 20,
        ),
        title: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppTheme.white : AppTheme.white70,
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
        dense: true,
      ),
    );
  }

  Widget _buildTopAppBar(BuildContext context, bool isDesktop, String? name) {
    final titles = ['Overview & Analytics', 'Manage Song Catalog', 'Upload New Track', 'Users & Authorization'];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        color: Color(0xFF14100D),
        border: Border(bottom: BorderSide(color: Colors.white12)),
      ),
      child: Row(
        children: [
          if (!isDesktop)
            IconButton(
              icon: Icon(Icons.menu, color: AppTheme.white),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          Row(
            children: [
              Image.asset(
                'assets/icons/retro_vibes_icon.png',
                width: 24,
                height: 24,
                errorBuilder: (c, e, s) => const SizedBox.shrink(),
              ),
              const SizedBox(width: 10),
              Text(
                titles[_selectedTabIndex],
                style: TextStyle(
                  color: AppTheme.white,
                  fontSize: isDesktop ? 20 : 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Spacer(),
          // Live Sync Indicator Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF4CAF50).withValues(alpha: 0.5)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(color: Color(0xFF4CAF50), shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
                const Text(
                  'LIVE FIRESTORE SYNC',
                  style: TextStyle(color: Color(0xFF4CAF50), fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(BuildContext context, double screenWidth) {
    final songProvider = context.watch<SongProvider>();

    return StreamBuilder<List<Song>>(
      stream: songProvider.getAllSongsStream(),
      builder: (context, snapshot) {
        final allSongs = snapshot.data ?? songProvider.publishedSongs;
        final publishedCount = allSongs.where((s) => s.isPublished).length;
        final featuredCount = allSongs.where((s) => s.isFeatured).length;

        final filteredSongs = allSongs.where((song) {
          final query = _catalogQuery.toLowerCase().trim();
          return song.title.toLowerCase().contains(query) ||
              song.artist.toLowerCase().contains(query) ||
              song.genre.toLowerCase().contains(query);
        }).toList();

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance.collection('users').snapshots(),
          builder: (context, userSnapshot) {
            final registeredUsersCount = userSnapshot.data?.docs.length ?? 1;

            return SingleChildScrollView(
              padding: EdgeInsets.all(screenWidth > 600 ? 24 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome Banner
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primaryAccent,
                          const Color(0xFF9E3E1B),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryAccent.withValues(alpha: 0.25),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
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
                              errorBuilder: (c, e, s) => const SizedBox.shrink(),
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'Central Music Administration',
                              style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Track uploads, metadata edits, visibilities, and real-time catalog changes sync instantly across all connected mobile clients worldwide.',
                          style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Metrics Responsive Grid
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final cols = constraints.maxWidth > 900 ? 4 : (constraints.maxWidth > 600 ? 2 : 1);
                      return Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        children: [
                          _buildMetricCardBox('Total Catalog Songs', allSongs.length.toString(), Icons.library_music, AppTheme.primaryAccent, cols, constraints.maxWidth),
                          _buildMetricCardBox('Published Tracks', publishedCount.toString(), Icons.check_circle_outline, const Color(0xFF4CAF50), cols, constraints.maxWidth),
                          _buildMetricCardBox('Featured Songs', featuredCount.toString(), Icons.star, const Color(0xFFFFD700), cols, constraints.maxWidth),
                          _buildMetricCardBox('Registered Users', registeredUsersCount.toString(), Icons.people_outline, const Color(0xFF64B5F6), cols, constraints.maxWidth),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 32),

                  // Live Catalog Table Controls Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'LIVE CATALOG CONTROL',
                        style: TextStyle(color: AppTheme.white38, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 2),
                      ),

                      // Search input
                      SizedBox(
                        width: screenWidth > 600 ? 280 : 180,
                        height: 40,
                        child: TextField(
                          controller: _searchController,
                          onChanged: (val) => setState(() => _catalogQuery = val),
                          style: TextStyle(color: AppTheme.white, fontSize: 13),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: AppTheme.cardBackground,
                            hintText: 'Filter tracks or artists...',
                            hintStyle: TextStyle(color: AppTheme.white38, fontSize: 12),
                            prefixIcon: Icon(Icons.search, color: AppTheme.white38, size: 18),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Catalog Table View
                  if (filteredSongs.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(36),
                      decoration: BoxDecoration(
                        color: AppTheme.cardBackground,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.library_music, color: AppTheme.white38, size: 40),
                          const SizedBox(height: 12),
                          Text('No songs match your query in Firestore catalog', style: TextStyle(color: AppTheme.white38, fontSize: 13)),
                        ],
                      ),
                    )
                  else
                    Container(
                      decoration: BoxDecoration(
                        color: AppTheme.cardBackground,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filteredSongs.length,
                        separatorBuilder: (c, i) => const Divider(color: Colors.white12, height: 1),
                        itemBuilder: (context, index) {
                          final song = filteredSongs[index];
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: song.image.startsWith('http')
                                  ? Image.network(song.image, width: 48, height: 48, fit: BoxFit.cover, errorBuilder: (c, e, s) => _buildPlaceholder())
                                  : Image.asset(song.image.isNotEmpty ? song.image : 'assets/images/80s_hit.png', width: 48, height: 48, fit: BoxFit.cover, errorBuilder: (c, e, s) => _buildPlaceholder()),
                            ),
                            title: Text(song.title, style: TextStyle(color: AppTheme.white, fontSize: 15, fontWeight: FontWeight.bold)),
                            subtitle: Text('${song.artist} • ${song.album} • ${song.genre} • ${song.duration}', style: TextStyle(color: AppTheme.white38, fontSize: 12)),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // EDIT BUTTON
                                IconButton(
                                  icon: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryAccent.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(Icons.edit, color: AppTheme.primaryAccent, size: 18),
                                  ),
                                  tooltip: 'Edit Song Metadata',
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (ctx) => EditSongDialog(song: song),
                                    );
                                  },
                                ),

                                // Featured Toggle
                                IconButton(
                                  icon: Icon(
                                    song.isFeatured ? Icons.star : Icons.star_border,
                                    color: song.isFeatured ? const Color(0xFFFFD700) : AppTheme.white38,
                                    size: 20,
                                  ),
                                  tooltip: song.isFeatured ? 'Featured Song' : 'Mark as Featured',
                                  onPressed: () => context.read<SongProvider>().toggleFeatured(song.songId, !song.isFeatured),
                                ),

                                // Publish Toggle
                                IconButton(
                                  icon: Icon(
                                    song.isPublished ? Icons.visibility : Icons.visibility_off,
                                    color: song.isPublished ? const Color(0xFF4CAF50) : AppTheme.white38,
                                    size: 20,
                                  ),
                                  tooltip: song.isPublished ? 'Published' : 'Draft',
                                  onPressed: () => context.read<SongProvider>().togglePublish(song.songId, !song.isPublished),
                                ),

                                // REAL-TIME DELETE BUTTON
                                IconButton(
                                  icon: const Icon(Icons.delete_forever, color: Colors.redAccent, size: 20),
                                  tooltip: 'Delete Song from Cloud',
                                  onPressed: () => _confirmDeleteSong(context, song),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),

                  const SizedBox(height: 40),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMetricCardBox(String title, String value, IconData icon, Color color, int cols, double parentWidth) {
    final cardWidth = (parentWidth - (16 * (cols - 1))) / cols;

    return Container(
      width: cardWidth,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: TextStyle(color: AppTheme.white38, fontSize: 12)),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.15), shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(value, style: TextStyle(color: AppTheme.white, fontSize: 26, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(width: 48, height: 48, color: Colors.white12, child: const Icon(Icons.music_note, color: Colors.white38));
  }

  void _confirmDeleteSong(BuildContext context, Song song) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete "${song.title}"?', style: TextStyle(color: AppTheme.white)),
        content: Text(
          'This track will be permanently removed from Cloud Firestore.\nIt will immediately disappear in real-time from all connected mobile app users.',
          style: TextStyle(color: AppTheme.white70, fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text('Cancel', style: TextStyle(color: AppTheme.white38)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              await context.read<SongProvider>().deleteSong(song.songId);
              if (dialogCtx.mounted) {
                Navigator.pop(dialogCtx);
              }
            },
            child: const Text('Delete Instantly', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

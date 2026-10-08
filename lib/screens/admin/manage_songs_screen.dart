import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:retro_vibes/model/song.dart';
import 'package:retro_vibes/provider/song_provider.dart';
import 'package:retro_vibes/screens/admin/edit_song_dialog.dart';
import 'package:retro_vibes/theme/app_theme.dart';

class ManageSongsScreen extends StatefulWidget {
  const ManageSongsScreen({super.key});

  @override
  State<ManageSongsScreen> createState() => _ManageSongsScreenState();
}

class _ManageSongsScreenState extends State<ManageSongsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _filterQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final songProvider = context.watch<SongProvider>();

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
              errorBuilder: (c, e, s) => Icon(Icons.library_music, color: AppTheme.primaryAccent, size: 24),
            ),
            const SizedBox(width: 10),
            Text(
              'SONG CATALOG & MANAGEMENT',
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
      body: StreamBuilder<List<Song>>(
        stream: songProvider.getAllSongsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFFC85A32)));
          }

          final allSongs = snapshot.data ?? songProvider.publishedSongs;

          final filteredSongs = allSongs.where((song) {
            final query = _filterQuery.toLowerCase().trim();
            if (query.isEmpty) return true;
            return song.title.toLowerCase().contains(query) ||
                song.artist.toLowerCase().contains(query) ||
                song.album.toLowerCase().contains(query) ||
                song.genre.toLowerCase().contains(query);
          }).toList();

          return Column(
            children: [
              // Search & Filter Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppTheme.cardBackground,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: (val) => setState(() => _filterQuery = val),
                          style: TextStyle(color: AppTheme.white, fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'Search by title, artist, album, genre...',
                            hintStyle: TextStyle(color: AppTheme.white38, fontSize: 13),
                            prefixIcon: Icon(Icons.search, color: AppTheme.white38, size: 20),
                            suffixIcon: _filterQuery.isNotEmpty
                                ? IconButton(
                                    icon: Icon(Icons.clear, color: AppTheme.white38, size: 18),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() => _filterQuery = '');
                                    },
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryAccent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.primaryAccent.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        '${filteredSongs.length} Tracks',
                        style: TextStyle(color: AppTheme.primaryAccent, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: filteredSongs.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.library_music_outlined, color: AppTheme.white38, size: 48),
                            const SizedBox(height: 12),
                            Text(
                              _filterQuery.isNotEmpty ? 'No tracks match "$_filterQuery"' : 'No songs found in catalog.',
                              style: TextStyle(color: AppTheme.white38, fontSize: 14),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredSongs.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final song = filteredSongs[index];

                          return Container(
                            decoration: BoxDecoration(
                              color: AppTheme.cardBackground,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.white12),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: song.image.startsWith('http')
                                    ? Image.network(
                                        song.image,
                                        width: 50,
                                        height: 50,
                                        fit: BoxFit.cover,
                                        errorBuilder: (c, e, s) => _buildPlaceholder(),
                                      )
                                    : Image.asset(
                                        song.image.isNotEmpty ? song.image : 'assets/images/80s_hit.png',
                                        width: 50,
                                        height: 50,
                                        fit: BoxFit.cover,
                                        errorBuilder: (c, e, s) => _buildPlaceholder(),
                                      ),
                              ),
                              title: Text(
                                song.title,
                                style: TextStyle(
                                  color: AppTheme.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Wrap(
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  spacing: 6,
                                  runSpacing: 4,
                                  children: [
                                    Text(
                                      '${song.artist} • ${song.album} • ${song.duration}',
                                      style: TextStyle(color: AppTheme.white38, fontSize: 12),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryAccent.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        song.genre,
                                        style: TextStyle(color: AppTheme.primaryAccent, fontSize: 10, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: song.isPublished
                                            ? const Color(0xFF4CAF50).withValues(alpha: 0.2)
                                            : Colors.amber.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        song.isPublished ? 'Published' : 'Draft',
                                        style: TextStyle(
                                          color: song.isPublished ? const Color(0xFF4CAF50) : Colors.amber,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Edit Action Button
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

                                  // Retro Radio Toggle Button
                                  IconButton(
                                    icon: Icon(
                                      song.isRetroRadio ? Icons.radio : Icons.radio_outlined,
                                      color: song.isRetroRadio ? AppTheme.deepOrangeAccent : AppTheme.white38,
                                      size: 20,
                                    ),
                                    tooltip: song.isRetroRadio ? 'In Retro Radio' : 'Add to Retro Radio',
                                    onPressed: () {
                                      context.read<SongProvider>().toggleRetroRadio(song.songId, !song.isRetroRadio);
                                    },
                                  ),

                                  // Featured Toggle Star
                                  IconButton(
                                    icon: Icon(
                                      song.isFeatured ? Icons.star : Icons.star_border,
                                      color: song.isFeatured ? const Color(0xFFFFD700) : AppTheme.white38,
                                      size: 20,
                                    ),
                                    tooltip: song.isFeatured ? 'Featured Song' : 'Mark Featured',
                                    onPressed: () {
                                      context.read<SongProvider>().toggleFeatured(song.songId, !song.isFeatured);
                                    },
                                  ),

                                  // Publish Toggle Button
                                  IconButton(
                                    icon: Icon(
                                      song.isPublished ? Icons.visibility : Icons.visibility_off,
                                      color: song.isPublished ? const Color(0xFF4CAF50) : AppTheme.white38,
                                      size: 20,
                                    ),
                                    tooltip: song.isPublished ? 'Published' : 'Draft',
                                    onPressed: () {
                                      context.read<SongProvider>().togglePublish(song.songId, !song.isPublished);
                                    },
                                  ),

                                  // Delete Button
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                                    tooltip: 'Delete Track',
                                    onPressed: () {
                                      _confirmDelete(context, song);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: 50,
      height: 50,
      color: Colors.white12,
      child: const Icon(Icons.music_note, color: Colors.white38),
    );
  }

  void _confirmDelete(BuildContext context, Song song) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete "${song.title}"?', style: TextStyle(color: AppTheme.white)),
        content: Text(
          'This action will permanently delete this track from Cloud Firestore catalog.',
          style: TextStyle(color: AppTheme.white70, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text('Cancel', style: TextStyle(color: AppTheme.white38)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              context.read<SongProvider>().deleteSong(song.songId);
              Navigator.pop(dialogCtx);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

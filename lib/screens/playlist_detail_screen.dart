import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:retro_vibes/model/song.dart';
import 'package:retro_vibes/provider/music_provider.dart';
import 'package:retro_vibes/theme/app_theme.dart';

class PlaylistDetailScreen extends StatelessWidget {
  final String title;
  final String image;
  final String description;
  final List<Song> songs;

  const PlaylistDetailScreen({
    super.key,
    required this.title,
    required this.image,
    required this.description,
    required this.songs,
  });

  @override
  Widget build(BuildContext context) {
    double mediaHeight = MediaQuery.of(context).size.height;
    double mediaWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.scaffoldBackground,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.keyboard_arrow_down, color: AppTheme.white, size: mediaWidth * 0.08),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: AppTheme.white,
            fontSize: mediaWidth * 0.045,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.more_vert, color: AppTheme.white, size: mediaWidth * 0.065),
            onPressed: () {},
          ),
        ],
      ),
      body: Consumer<MusicProvider>(
        builder: (context, musicProvider, child) {
          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: mediaWidth * 0.05),
              child: Column(
                children: [
                  SizedBox(height: mediaHeight * 0.015),

                  // Category Large Album Artwork Banner
                  Center(
                    child: Container(
                      height: mediaWidth * 0.68,
                      width: mediaWidth * 0.68,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.5),
                            blurRadius: 20,
                            spreadRadius: 2,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.asset(
                          image,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: mediaHeight * 0.02),

                  // Playlist Title
                  Text(
                    title,
                    style: TextStyle(
                      color: AppTheme.white,
                      fontSize: mediaWidth * 0.065,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  SizedBox(height: mediaHeight * 0.004),

                  Text(
                    'by Krishna',
                    style: TextStyle(
                      color: AppTheme.white38,
                      fontSize: mediaWidth * 0.035,
                    ),
                  ),

                  SizedBox(height: mediaHeight * 0.008),

                  // Playlist Description
                  Text(
                    description.isNotEmpty
                        ? description
                        : 'A collection of timeless classics that never get old. ✨',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppTheme.white38,
                      fontSize: mediaWidth * 0.035,
                    ),
                  ),

                  SizedBox(height: mediaHeight * 0.006),

                  // Song Count & Total Time Meta
                  Text(
                    '${songs.length} songs • 3h 45m',
                    style: TextStyle(
                      color: AppTheme.white38,
                      fontSize: mediaWidth * 0.032,
                    ),
                  ),

                  SizedBox(height: mediaHeight * 0.025),

                  // Play All & Shuffle Buttons Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: mediaWidth * 0.58,
                        height: mediaHeight * 0.055,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFC85A32), // Retro Orange
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            elevation: 4,
                          ),
                          onPressed: () {
                            if (songs.isNotEmpty) {
                              musicProvider.playSong(songs.first, playlist: songs);
                            }
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.play_arrow, color: AppTheme.white, size: mediaWidth * 0.065),
                              const SizedBox(width: 6),
                              Text(
                                'Play All',
                                style: TextStyle(
                                  color: AppTheme.white,
                                  fontSize: mediaWidth * 0.042,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        height: mediaHeight * 0.055,
                        width: mediaHeight * 0.055,
                        decoration: BoxDecoration(
                          color: AppTheme.cardBackground,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: Icon(
                            Icons.shuffle,
                            color: musicProvider.isShuffle ? AppTheme.primaryAccent : AppTheme.white,
                            size: mediaWidth * 0.055,
                          ),
                          onPressed: () => musicProvider.toggleShuffle(),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: mediaHeight * 0.015),

                  SizedBox(height: mediaHeight * 0.025),

                  // Songs List Items
                  songs.isEmpty
                      ? Container(
                          padding: const EdgeInsets.all(24),
                          margin: const EdgeInsets.symmetric(vertical: 20),
                          decoration: BoxDecoration(
                            color: AppTheme.cardBackground,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.music_off_outlined, color: AppTheme.white38, size: 48),
                              const SizedBox(height: 12),
                              Text(
                                'No $title tracks available yet.',
                                style: TextStyle(
                                  color: AppTheme.white,
                                  fontSize: mediaWidth * 0.04,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Songs added by admin for this release era will appear here.',
                                style: TextStyle(
                                  color: AppTheme.white38,
                                  fontSize: mediaWidth * 0.032,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: songs.length,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemBuilder: (context, index) {
                            final song = songs[index];
                            final isCurrent = musicProvider.currentSong?.title == song.title;

                            return Container(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              child: ListTile(
                                onTap: () {
                                  musicProvider.playSong(song, playlist: songs);
                                },
                                contentPadding: EdgeInsets.zero,
                                leading: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(
                                      width: mediaWidth * 0.05,
                                      child: Center(
                                        child: isCurrent
                                            ? Icon(
                                                Icons.equalizer,
                                                color: AppTheme.primaryAccent,
                                                size: mediaWidth * 0.05,
                                              )
                                            : Text(
                                                '${index + 1}',
                                                style: TextStyle(
                                                  color: AppTheme.white38,
                                                  fontSize: mediaWidth * 0.035,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: song.image.startsWith('http')
                                          ? Image.network(
                                              song.image,
                                              width: mediaWidth * 0.11,
                                              height: mediaWidth * 0.11,
                                              fit: BoxFit.cover,
                                              errorBuilder: (c, e, s) => _buildImagePlaceholder(mediaWidth),
                                            )
                                          : Image.asset(
                                              song.image.isNotEmpty ? song.image : 'assets/images/80s_hit.png',
                                              width: mediaWidth * 0.11,
                                              height: mediaWidth * 0.11,
                                              fit: BoxFit.cover,
                                              errorBuilder: (c, e, s) => _buildImagePlaceholder(mediaWidth),
                                            ),
                                    ),
                                  ],
                                ),
                                title: Text(
                                  song.title,
                                  style: TextStyle(
                                    color: isCurrent ? AppTheme.primaryAccent : AppTheme.white,
                                    fontSize: mediaWidth * 0.038,
                                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Text(
                                  song.artist,
                                  style: TextStyle(
                                    color: AppTheme.white38,
                                    fontSize: mediaWidth * 0.032,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      song.duration,
                                      style: TextStyle(
                                        color: AppTheme.white38,
                                        fontSize: mediaWidth * 0.032,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(
                                      Icons.more_vert,
                                      color: AppTheme.white38,
                                      size: mediaWidth * 0.05,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),

                  SizedBox(height: mediaHeight * 0.04),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildImagePlaceholder(double mediaWidth) {
    return Container(
      width: mediaWidth * 0.11,
      height: mediaWidth * 0.11,
      color: Colors.white12,
      child: const Icon(Icons.music_note, color: Colors.white38, size: 20),
    );
  }
}

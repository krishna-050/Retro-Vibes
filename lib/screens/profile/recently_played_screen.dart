import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:retro_vibes/provider/library_provider.dart';
import 'package:retro_vibes/provider/music_provider.dart';
import 'package:retro_vibes/theme/app_theme.dart';

class RecentlyPlayedScreen extends StatelessWidget {
  const RecentlyPlayedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    double mediaWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.scaffoldBackground,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: AppTheme.white, size: mediaWidth * 0.055),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Recently Played', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Consumer2<LibraryProvider, MusicProvider>(
        builder: (context, libraryProvider, musicProvider, child) {
          final recentSongs = libraryProvider.recentlyPlayed.isNotEmpty
              ? libraryProvider.recentlyPlayed
              : musicProvider.playlist.take(5).toList();

          if (recentSongs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 64, color: AppTheme.white38),
                  const SizedBox(height: 16),
                  Text(
                    'No Recently Played Songs',
                    style: TextStyle(color: AppTheme.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Play some songs to build your listening history',
                    style: TextStyle(color: AppTheme.white38, fontSize: 13),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: recentSongs.length,
            itemBuilder: (context, index) {
              final song = recentSongs[index];
              final isCurrent = musicProvider.currentSong?.title == song.title;

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: AppTheme.cardBackground.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: song.image.startsWith('http')
                        ? Image.network(song.image, width: 48, height: 48, fit: BoxFit.cover, errorBuilder: (c, e, s) => Image.asset('assets/images/80s_hit.png', width: 48, height: 48, fit: BoxFit.cover))
                        : Image.asset(song.image.isNotEmpty ? song.image : 'assets/images/80s_hit.png', width: 48, height: 48, fit: BoxFit.cover, errorBuilder: (c, e, s) => Image.asset('assets/images/80s_hit.png', width: 48, height: 48, fit: BoxFit.cover)),
                  ),
                  title: Text(
                    song.title,
                    style: TextStyle(
                      color: isCurrent ? AppTheme.primaryAccent : AppTheme.white,
                      fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    song.artist,
                    style: TextStyle(color: AppTheme.white38, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: IconButton(
                    icon: Icon(
                      isCurrent && musicProvider.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
                      color: AppTheme.primaryAccent,
                      size: 32,
                    ),
                    onPressed: () {
                      if (isCurrent) {
                        musicProvider.togglePlayPause();
                      } else {
                        musicProvider.playSong(song, playlist: recentSongs);
                      }
                    },
                  ),
                  onTap: () {
                    musicProvider.playSong(song, playlist: recentSongs);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

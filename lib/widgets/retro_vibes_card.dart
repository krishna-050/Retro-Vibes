import 'package:flutter/material.dart';
import 'package:retro_vibes/data/dummy_songs.dart';
import 'package:retro_vibes/model/song.dart';
import 'package:retro_vibes/screens/playlist_detail_screen.dart';
import 'package:retro_vibes/theme/app_theme.dart';

class RetroVibesCard extends StatelessWidget {
  final String image;
  final String title;
  final String? subtitle;
  final List<Song>? songs;

  const RetroVibesCard({
    super.key,
    required this.image,
    required this.title,
    this.subtitle,
    this.songs,
  });

  String _getEraTag(String title) {
    if (title.contains('70s')) return '1970s';
    if (title.contains('80s')) return '1980s';
    if (title.contains('90s')) return '1990s';
    if (title.contains('2000s')) return '2000s';
    if (title.contains('2010s')) return '2010s';
    if (title.contains('2020s')) return '2020s';
    return 'RETRO';
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    double mediaWidth = size.width;

    final categorySongs = (songs != null && songs!.isNotEmpty)
        ? songs!
        : (categorySongsMap[title] ?? roadTripSongs);
    final eraTag = _getEraTag(title);

    return Padding(
      padding: const EdgeInsets.only(right: 12, top: 4, bottom: 4),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PlaylistDetailScreen(
                title: title,
                image: image,
                description: 'Classic retro collection for $title',
                songs: categorySongs,
              ),
            ),
          );
        },
        child: Container(
          width: mediaWidth * 0.36,
          decoration: BoxDecoration(
            color: AppTheme.cardBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppTheme.primaryAccent.withValues(alpha: 0.25),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Container with Badge and Gradient
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                        child: Image.asset(
                          image,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: AppTheme.cardBackground,
                              child: Icon(Icons.music_note, color: AppTheme.white38, size: mediaWidth * 0.1),
                            );
                          },
                        ),
                      ),
                    ),

                    // Dark Bottom Gradient
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.6),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Era Badge Tag (Top Right)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.75),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppTheme.yellow300.withValues(alpha: 0.6),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          eraTag,
                          style: TextStyle(
                            color: AppTheme.yellow300,
                            fontSize: mediaWidth * 0.026,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),

                    // Play Icon Indicator (Bottom Right)
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryAccent,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryAccent.withValues(alpha: 0.4),
                              blurRadius: 6,
                            )
                          ],
                        ),
                        child: const Icon(
                          Icons.play_arrow,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Title & Subtitle Meta
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: mediaWidth * 0.035,
                        color: AppTheme.white,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle ?? '${categorySongs.length} Tracks',
                      style: TextStyle(
                        fontSize: mediaWidth * 0.028,
                        color: AppTheme.white38,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

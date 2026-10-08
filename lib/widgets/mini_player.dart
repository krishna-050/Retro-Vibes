import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:retro_vibes/provider/music_provider.dart';
import 'package:retro_vibes/provider/theme_provider.dart';
import 'package:retro_vibes/theme/app_theme.dart';

class MiniPlayer extends StatelessWidget {
  final String image;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const MiniPlayer({
    super.key,
    required this.image,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    double mediaHeight = size.height;
    double mediaWidth = size.width;

    return Consumer2<MusicProvider, ThemeProvider>(
      builder: (context, musicProvider, themeProvider, child) {
        final isPlaying = musicProvider.isPlaying;
        final song = musicProvider.currentSong;

        final displayTitle = song?.title ?? title;
        final displaySubtitle = song?.artist ?? subtitle;
        final displayImage = song?.image ?? image;

        return GestureDetector(
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: mediaWidth * 0.02),
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.cardBackground,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: AppTheme.primaryAccent.withValues(alpha: 0.3)),
              ),
              height: mediaHeight * 0.085,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: mediaWidth * 0.02),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: displayImage.startsWith('http')
                          ? Image.network(
                              displayImage,
                              fit: BoxFit.cover,
                              height: mediaHeight * 0.07,
                              width: mediaHeight * 0.07,
                              errorBuilder: (c, e, s) => Image.asset('assets/images/80s_hit.png', fit: BoxFit.cover, height: mediaHeight * 0.07, width: mediaHeight * 0.07),
                            )
                          : Image.asset(
                              displayImage.isNotEmpty ? displayImage : 'assets/images/80s_hit.png',
                              fit: BoxFit.cover,
                              height: mediaHeight * 0.07,
                              width: mediaHeight * 0.07,
                              errorBuilder: (c, e, s) => Image.asset('assets/images/80s_hit.png', fit: BoxFit.cover, height: mediaHeight * 0.07, width: mediaHeight * 0.07),
                            ),
                    ),
                    SizedBox(width: mediaWidth * 0.03),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayTitle,
                            style: TextStyle(
                              fontSize: mediaWidth * 0.045,
                              color: AppTheme.white,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            displaySubtitle,
                            style: TextStyle(
                              fontSize: mediaWidth * 0.035,
                              color: AppTheme.white70,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        musicProvider.nextSong();
                      },
                      icon: Icon(
                        Icons.skip_next,
                        color: AppTheme.primaryAccent,
                        size: mediaWidth * 0.07,
                      ),
                    ),
                    SizedBox(width: mediaWidth * 0.01),
                    Container(
                      width: mediaHeight * 0.048,
                      height: mediaHeight * 0.048,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryAccent,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        onPressed: () {
                          musicProvider.togglePlayPause();
                        },
                        padding: EdgeInsets.zero,
                        icon: Icon(
                          isPlaying ? Icons.pause : Icons.play_arrow,
                          color: AppTheme.white,
                          size: mediaWidth * 0.06,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

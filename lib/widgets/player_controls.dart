import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:retro_vibes/provider/music_provider.dart';
import 'package:retro_vibes/theme/app_theme.dart';

class PlayerControls extends StatelessWidget {
  final VoidCallback? onShuffle;
  final VoidCallback? onPrevious;
  final VoidCallback? onPlayPause;
  final VoidCallback? onNext;
  final VoidCallback? onRepeat;

  const PlayerControls({
    super.key,
    this.onShuffle,
    this.onNext,
    this.onPlayPause,
    this.onPrevious,
    this.onRepeat,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    double mediaWidth = size.width;

    return Consumer<MusicProvider>(
      builder: (context, musicProvider, child) {
        final isPlaying = musicProvider.isPlaying;
        final isShuffle = musicProvider.isShuffle;
        final isRepeat = musicProvider.isRepeat;

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              onPressed: onShuffle ?? () => musicProvider.toggleShuffle(),
              icon: Icon(
                Icons.shuffle,
                size: mediaWidth * 0.06,
                color: isShuffle ? AppTheme.primaryAccent : AppTheme.white,
              ),
            ),
            IconButton(
              onPressed: onPrevious ?? () => musicProvider.previousSong(),
              icon: Icon(
                Icons.skip_previous,
                color: AppTheme.white,
                size: mediaWidth * 0.09,
              ),
            ),
            Container(
              height: mediaWidth * 0.16,
              width: mediaWidth * 0.16,
              decoration: BoxDecoration(
                color: AppTheme.playerAccent,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: onPlayPause ?? () => musicProvider.togglePlayPause(),
                icon: Icon(
                  isPlaying ? Icons.pause : Icons.play_arrow,
                  color: AppTheme.white,
                  size: mediaWidth * 0.09,
                ),
              ),
            ),
            IconButton(
              onPressed: onNext ?? () => musicProvider.nextSong(),
              icon: Icon(
                Icons.skip_next,
                size: mediaWidth * 0.09,
                color: AppTheme.white,
              ),
            ),
            IconButton(
              onPressed: onRepeat ?? () => musicProvider.toggleRepeat(),
              icon: Icon(
                Icons.repeat,
                size: mediaWidth * 0.06,
                color: isRepeat ? AppTheme.primaryAccent : AppTheme.white,
              ),
            ),
          ],
        );
      },
    );
  }
}

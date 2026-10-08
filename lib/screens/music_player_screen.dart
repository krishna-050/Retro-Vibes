import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:retro_vibes/games/snake/retro_snake_screen.dart';
import 'package:retro_vibes/model/song.dart';
import 'package:retro_vibes/provider/music_provider.dart';
import 'package:retro_vibes/widgets/player_controls.dart';
import 'package:retro_vibes/theme/app_theme.dart';

class MusicPlayerScreen extends StatefulWidget {
  final String image;
  final String title;
  final String subtitle;

  const MusicPlayerScreen({
    super.key,
    required this.image,
    required this.title,
    required this.subtitle,
  });

  @override
  State<MusicPlayerScreen> createState() => _MusicPlayerScreenState();
}

class _MusicPlayerScreenState extends State<MusicPlayerScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;
  late ScrollController _mainScrollController;
  String _activeOutputDevice = 'Phone Speaker';

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    );
    _mainScrollController = ScrollController();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _mainScrollController.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  void _showPlaylistBottomSheet(BuildContext context, Song song) {
    final TextEditingController playlistNameController = TextEditingController();

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Consumer<MusicProvider>(
          builder: (context, musicProvider, child) {
            final playlists = musicProvider.customPlaylists;

            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Add to Playlist',
                        style: TextStyle(
                          color: AppTheme.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: AppTheme.white38),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Create New Playlist Option
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryAccent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.add, color: AppTheme.white),
                    ),
                    title: Text(
                      'Create New Playlist',
                      style: TextStyle(
                        color: AppTheme.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (dialogCtx) => AlertDialog(
                          backgroundColor: AppTheme.cardBackground,
                          title: Text(
                            'New Playlist',
                            style: TextStyle(color: AppTheme.white),
                          ),
                          content: TextField(
                            controller: playlistNameController,
                            style: TextStyle(color: AppTheme.white),
                            decoration: InputDecoration(
                              hintText: 'Enter playlist name',
                              hintStyle: TextStyle(color: AppTheme.white38),
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(dialogCtx),
                              child: Text('Cancel', style: TextStyle(color: AppTheme.white38)),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryAccent,
                              ),
                              onPressed: () {
                                if (playlistNameController.text.trim().isNotEmpty) {
                                  musicProvider.createPlaylist(playlistNameController.text.trim());
                                  musicProvider.addToPlaylist(playlistNameController.text.trim(), song);
                                  Navigator.pop(dialogCtx);
                                  Navigator.pop(ctx);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Added to ${playlistNameController.text.trim()}'),
                                      backgroundColor: AppTheme.primaryAccent,
                                    ),
                                  );
                                }
                              },
                              child: Text('Create', style: TextStyle(color: AppTheme.white)),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const Divider(color: Colors.white12),
                  // Existing Playlists
                  Expanded(
                    child: ListView(
                      children: playlists.keys.map((playlistName) {
                        return ListTile(
                          leading: Icon(Icons.playlist_play, color: AppTheme.primaryAccent),
                          title: Text(
                            playlistName,
                            style: TextStyle(color: AppTheme.white),
                          ),
                          subtitle: Text(
                            '${playlists[playlistName]!.length} songs',
                            style: TextStyle(color: AppTheme.white38),
                          ),
                          onTap: () {
                            musicProvider.addToPlaylist(playlistName, song);
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Added to $playlistName'),
                                backgroundColor: AppTheme.primaryAccent,
                              ),
                            );
                          },
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showDevicesBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final devices = [
              {'name': 'Phone Speaker', 'icon': Icons.phone_android, 'type': 'Internal Speaker'},
              {'name': 'Bluetooth Headphones', 'icon': Icons.headphones, 'type': 'Bluetooth Output'},
              {'name': 'Retro Hi-Fi Cast', 'icon': Icons.cast, 'type': 'Wireless Speaker'},
            ];

            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.devices, color: AppTheme.yellow300, size: 22),
                          const SizedBox(width: 8),
                          Text(
                            'Audio Output Device',
                            style: TextStyle(
                              color: AppTheme.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: AppTheme.white38),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(color: Colors.white12),
                  const SizedBox(height: 8),
                  Column(
                    children: devices.map((dev) {
                      final isSelected = dev['name'] == _activeOutputDevice;

                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        decoration: BoxDecoration(
                          color: isSelected ? AppTheme.yellow300.withValues(alpha: 0.15) : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? AppTheme.yellow300 : Colors.white12,
                          ),
                        ),
                        child: ListTile(
                          leading: Icon(
                            dev['icon'] as IconData,
                            color: isSelected ? AppTheme.yellow300 : AppTheme.white70,
                          ),
                          title: Text(
                            dev['name'] as String,
                            style: TextStyle(
                              color: isSelected ? AppTheme.yellow300 : AppTheme.white,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          subtitle: Text(
                            dev['type'] as String,
                            style: TextStyle(color: AppTheme.white38, fontSize: 12),
                          ),
                          trailing: isSelected
                              ? Icon(Icons.check_circle, color: AppTheme.yellow300, size: 20)
                              : null,
                          onTap: () {
                            setState(() {
                              _activeOutputDevice = dev['name'] as String;
                            });
                            setSheetState(() {});
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Audio output switched to ${dev['name']}'),
                                backgroundColor: AppTheme.cardBackground,
                              ),
                            );
                          },
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    double mediaHeight = size.height;
    double mediaWidth = size.width;

    final vinylDimension = (mediaWidth * 0.72).clamp(180.0, 320.0);

    return Consumer<MusicProvider>(
      builder: (context, musicProvider, child) {
        final currentSong = musicProvider.currentSong;
        final displayTitle = currentSong?.title ?? widget.title;
        final displaySubtitle = currentSong?.artist ?? widget.subtitle;
        final displayImage = currentSong?.image ?? widget.image;

        final position = musicProvider.position;
        final totalDuration = musicProvider.duration;
        final maxSeconds = totalDuration.inSeconds.toDouble() > 0
            ? totalDuration.inSeconds.toDouble()
            : 1.0;
        final currentSeconds = position.inSeconds.toDouble().clamp(0.0, maxSeconds);

        final activeSong = currentSong ?? Song(
          title: widget.title,
          artist: widget.subtitle,
          image: widget.image,
          duration: '',
          audio: '',
        );
        final isLiked = musicProvider.isLiked(activeSong);

        // Manage Vinyl Rotation Animation based on isPlaying state
        if (musicProvider.isPlaying) {
          if (!_rotationController.isAnimating) {
            _rotationController.repeat();
          }
        } else {
          if (_rotationController.isAnimating) {
            _rotationController.stop();
          }
        }

        return Scaffold(
          backgroundColor: AppTheme.scaffoldBackground,
          appBar: AppBar(
            toolbarHeight: mediaHeight * 0.08,
            centerTitle: true,
            backgroundColor: AppTheme.scaffoldBackground,
            leading: IconButton(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: Icon(Icons.arrow_back_ios, color: AppTheme.white, size: (mediaWidth * 0.055).clamp(18.0, 24.0)),
            ),
            title: const Text('NOW PLAYING'),
            titleTextStyle: TextStyle(
              color: AppTheme.deepOrangeAccent,
              fontSize: (mediaWidth * 0.045).clamp(16.0, 20.0),
              fontWeight: FontWeight.bold,
            ),
            actions: [
              IconButton(
                onPressed: () => _showPlaylistBottomSheet(context, activeSong),
                icon: Icon(Icons.more_vert, color: AppTheme.white, size: (mediaWidth * 0.065).clamp(20.0, 26.0)),
              ),
            ],
          ),

          body: SingleChildScrollView(
            controller: _mainScrollController,
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: (mediaWidth * 0.08).clamp(16.0, 48.0)),
              child: Column(
                children: [
                  SizedBox(height: mediaHeight * 0.02),

                  // Animated Vinyl Record Album Art
                  RotationTransition(
                    turns: _rotationController,
                    child: Container(
                      height: vinylDimension,
                      width: vinylDimension,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryAccent.withValues(alpha: 0.3),
                            blurRadius: 20,
                            spreadRadius: 2,
                          )
                        ],
                      ),
                      child: ClipOval(
                        child: displayImage.startsWith('http')
                            ? Image.network(
                                displayImage,
                                fit: BoxFit.cover,
                                errorBuilder: (c, e, s) => Image.asset('assets/images/80s_hit.png', fit: BoxFit.cover),
                              )
                            : Image.asset(
                                displayImage.isNotEmpty ? displayImage : 'assets/images/80s_hit.png',
                                fit: BoxFit.cover,
                                errorBuilder: (c, e, s) => Image.asset('assets/images/80s_hit.png', fit: BoxFit.cover),
                              ),
                      ),
                    ),
                  ),

                  SizedBox(height: mediaHeight * 0.03),

                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      displayTitle,
                      style: TextStyle(
                        color: AppTheme.white,
                        fontSize: (mediaWidth * 0.055).clamp(18.0, 24.0),
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: IconButton(
                      onPressed: () {
                        musicProvider.toggleLike(activeSong);
                      },
                      icon: Icon(
                        isLiked ? Icons.favorite : Icons.favorite_border,
                        color: AppTheme.deepOrangeAccent,
                        size: (mediaWidth * 0.07).clamp(22.0, 30.0),
                      ),
                    ),
                    subtitle: Text(
                      displaySubtitle,
                      style: TextStyle(
                        color: AppTheme.deepOrangeAccent,
                        fontSize: (mediaWidth * 0.042).clamp(14.0, 18.0),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  SizedBox(height: mediaHeight * 0.015),

                  Column(
                    children: [
                      Slider(
                        value: currentSeconds,
                        min: 0,
                        max: maxSeconds,
                        activeColor: AppTheme.playerAccent,
                        inactiveColor: AppTheme.sliderInactive,
                        onChanged: (value) {
                          musicProvider.seek(Duration(seconds: value.toInt()));
                        },
                      ),

                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: mediaWidth * 0.02),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatDuration(position),
                              style: TextStyle(color: AppTheme.white, fontSize: (mediaWidth * 0.035).clamp(12.0, 15.0)),
                            ),
                            Text(
                              _formatDuration(totalDuration),
                              style: TextStyle(color: AppTheme.white, fontSize: (mediaWidth * 0.035).clamp(12.0, 15.0)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: mediaHeight * 0.025),

                  PlayerControls(
                    onPrevious: () => musicProvider.previousSong(),
                    onPlayPause: () => musicProvider.togglePlayPause(),
                    onNext: () => musicProvider.nextSong(),
                  ),

                  SizedBox(height: mediaHeight * 0.03),

                  // Bottom Action Toolbar (Snake Game & Output Devices)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Snake Game Quick Launcher
                      IconButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const RetroSnakeScreen()),
                          );
                        },
                        icon: Icon(
                          Icons.sports_esports,
                          color: AppTheme.white70,
                          size: (mediaWidth * 0.068).clamp(22.0, 28.0),
                        ),
                        tooltip: 'Play Snake Game',
                      ),
                      // Working Devices Switcher
                      IconButton(
                        onPressed: () => _showDevicesBottomSheet(context),
                        icon: Icon(
                          Icons.devices,
                          color: AppTheme.white70,
                          size: (mediaWidth * 0.068).clamp(22.0, 28.0),
                        ),
                        tooltip: 'Audio Output Device',
                      ),
                    ],
                  ),

                  SizedBox(height: mediaHeight * 0.04),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

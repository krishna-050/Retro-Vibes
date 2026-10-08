import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:retro_vibes/data/dummy_songs.dart';
import 'package:retro_vibes/games/snake/retro_snake_screen.dart';
import 'package:retro_vibes/model/song.dart';
import 'package:retro_vibes/provider/auth_provider.dart';
import 'package:retro_vibes/provider/library_provider.dart';
import 'package:retro_vibes/provider/song_provider.dart';
import 'package:retro_vibes/theme/app_theme.dart';
import 'package:retro_vibes/widgets/retro_vibes_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.onSongTap});
  final Function(Song, [List<Song>?]) onSongTap;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _logoTapCount = 0;
  DateTime? _lastTapTime;

  void _handleLogoTap(BuildContext context) {
    final now = DateTime.now();
    if (_lastTapTime == null || now.difference(_lastTapTime!) > const Duration(seconds: 2)) {
      _logoTapCount = 1;
    } else {
      _logoTapCount++;
    }
    _lastTapTime = now;

    if (_logoTapCount >= 2) {
      _logoTapCount = 0;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('🎮 RETRO EASTER EGG UNLOCKED!'),
          backgroundColor: AppTheme.yellow300,
          duration: const Duration(seconds: 2),
        ),
      );
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const RetroSnakeScreen()),
      );
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  List<Song> _getSongsForDecade(String title, List<Song> allPublishedSongs) {
    int minYear = 0;
    int maxYear = 9999;

    if (title.contains('70s')) {
      minYear = 1970; maxYear = 1979;
    } else if (title.contains('80s')) {
      minYear = 1980; maxYear = 1989;
    } else if (title.contains('90s')) {
      minYear = 1990; maxYear = 1999;
    } else if (title.contains('2000s')) {
      minYear = 2000; maxYear = 2009;
    } else if (title.contains('2010s')) {
      minYear = 2010; maxYear = 2019;
    } else if (title.contains('2020s')) {
      minYear = 2020; maxYear = 2029;
    }

    final filtered = allPublishedSongs.where((song) {
      int year = int.tryParse(song.releaseYear.trim()) ?? 2024;
      return year >= minYear && year <= maxYear;
    }).toList();

    if (filtered.isNotEmpty) {
      return filtered;
    }

    final dummy = categorySongsMap[title];
    if (dummy != null && dummy.isNotEmpty) {
      return dummy;
    }

    return allPublishedSongs;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    double mediaHeight = size.height;
    double mediaWidth = size.width;

    final authProvider = context.watch<AuthProvider>();
    final songProvider = context.watch<SongProvider>();
    final libraryProvider = context.watch<LibraryProvider>();

    final userName = authProvider.currentUser?.name ?? 'Retro Listener';
    final publishedSongs = songProvider.publishedSongs;
    final recentlyPlayed = libraryProvider.recentlyPlayed;

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: mediaWidth * 0.04),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: mediaHeight * 0.04),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => _handleLogoTap(context),
                      child: Text(
                        _getGreeting(),
                        style: TextStyle(
                          color: AppTheme.yellow300,
                          fontSize: mediaWidth * 0.050,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  userName,
                  style: TextStyle(
                    fontSize: mediaWidth * 0.08,
                    color: AppTheme.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: mediaHeight * 0.02),

                // Retro Collections Section
                Text(
                  "Retro Collections",
                  style: TextStyle(
                    color: AppTheme.white,
                    fontSize: mediaWidth * 0.045,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: mediaHeight * 0.008),
                SizedBox(
                  height: mediaHeight * 0.22,
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    scrollDirection: Axis.horizontal,
                    children: [
                      RetroVibesCard(
                        image: 'assets/images/70s.png',
                        title: '70s Road Trip',
                        subtitle: 'Golden Disco',
                        songs: _getSongsForDecade('70s Road Trip', publishedSongs),
                      ),
                      RetroVibesCard(
                        image: 'assets/images/80s_hit.png',
                        title: '80s Hits',
                        subtitle: 'Synthwave & Pop',
                        songs: _getSongsForDecade('80s Hits', publishedSongs),
                      ),
                      RetroVibesCard(
                        image: 'assets/images/90s.png',
                        title: '90s Nostalgia',
                        subtitle: 'Cassette Beats',
                        songs: _getSongsForDecade('90s Nostalgia', publishedSongs),
                      ),
                      RetroVibesCard(
                        image: 'assets/images/2000s_hits.png',
                        title: '2000s Hits',
                        subtitle: 'Melody Pop',
                        songs: _getSongsForDecade('2000s Hits', publishedSongs),
                      ),
                      RetroVibesCard(
                        image: 'assets/images/2010s_chill_Vibe.png',
                        title: '2010s Chill Vibes',
                        subtitle: 'Lo-Fi Vibe',
                        songs: _getSongsForDecade('2010s Chill Vibes', publishedSongs),
                      ),
                      RetroVibesCard(
                        image: 'assets/images/2020s_hit.png',
                        title: '2020s Hits',
                        subtitle: 'Modern Retro',
                        songs: _getSongsForDecade('2020s Hits', publishedSongs),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: mediaHeight * 0.03),

                // Retro Radio Section
                _buildRetroRadioSection(mediaWidth, mediaHeight, songProvider.retroRadioSongs),

                // Recently Played / Continue Listening Section
                if (recentlyPlayed.isNotEmpty) ...[
                  SizedBox(height: mediaHeight * 0.025),
                  Text(
                    'Continue Listening',
                    style: TextStyle(
                      color: AppTheme.white,
                      fontSize: mediaWidth * 0.045,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: mediaHeight * 0.01),
                  SizedBox(
                    height: mediaHeight * 0.14,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: recentlyPlayed.length,
                      itemBuilder: (context, index) {
                        final song = recentlyPlayed[index];
                        return GestureDetector(
                          onTap: () => widget.onSongTap(song, recentlyPlayed),
                          child: Container(
                            width: mediaWidth * 0.28,
                            margin: const EdgeInsets.only(right: 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: song.image.startsWith('http')
                                      ? Image.network(song.image, height: mediaWidth * 0.22, width: mediaWidth * 0.28, fit: BoxFit.cover, errorBuilder: (c, e, s) => _buildPlaceholder(mediaWidth))
                                      : Image.asset(song.image.isNotEmpty ? song.image : 'assets/images/80s_hit.png', height: mediaWidth * 0.22, width: mediaWidth * 0.28, fit: BoxFit.cover, errorBuilder: (c, e, s) => _buildPlaceholder(mediaWidth)),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  song.title,
                                  style: TextStyle(color: AppTheme.white, fontSize: mediaWidth * 0.032, fontWeight: FontWeight.bold),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],

                SizedBox(height: mediaHeight * 0.03),

                // Catalog Songs Feed
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Featured Tracks',
                      style: TextStyle(
                        color: AppTheme.white,
                        fontSize: mediaWidth * 0.045,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'See all (${publishedSongs.length})',
                      style: TextStyle(
                        color: AppTheme.primaryAccent,
                        fontSize: mediaWidth * 0.038,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: mediaHeight * 0.01),

                if (songProvider.isLoading)
                  _buildSkeletonList(mediaWidth)
                else if (publishedSongs.isEmpty)
                  _buildEmptyState(mediaWidth)
                else
                  ListView.builder(
                    itemCount: publishedSongs.length,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemBuilder: (context, index) {
                      final song = publishedSongs[index];
                      return ListTile(
                        onTap: () {
                          libraryProvider.addRecentlyPlayed(song);
                          widget.onSongTap(song, publishedSongs);
                        },
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          song.title,
                          style: TextStyle(
                            color: AppTheme.white,
                            fontSize: mediaWidth * 0.04,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          '${song.artist} • ${song.duration}',
                          style: TextStyle(fontSize: mediaWidth * 0.035, color: AppTheme.white38),
                        ),
                        trailing: Icon(
                          Icons.play_circle_fill,
                          color: AppTheme.primaryAccent,
                          size: mediaWidth * 0.08,
                        ),
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: song.image.startsWith('http')
                              ? Image.network(
                                  song.image,
                                  height: mediaWidth * 0.13,
                                  width: mediaWidth * 0.13,
                                  fit: BoxFit.cover,
                                  errorBuilder: (c, e, s) => _buildPlaceholder(mediaWidth),
                                )
                              : Image.asset(
                                  song.image.isNotEmpty ? song.image : 'assets/images/80s_hit.png',
                                  height: mediaWidth * 0.13,
                                  width: mediaWidth * 0.13,
                                  fit: BoxFit.cover,
                                  errorBuilder: (c, e, s) => _buildPlaceholder(mediaWidth),
                                ),
                        ),
                      );
                    },
                  ),

                SizedBox(height: mediaHeight * 0.04),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSkeletonList(double mediaWidth) {
    return Column(
      children: List.generate(
        4,
        (index) => Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          height: 56,
          decoration: BoxDecoration(
            color: AppTheme.cardBackground.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(double mediaWidth) {
    return Container(
      padding: const EdgeInsets.all(24),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(Icons.music_off_outlined, color: AppTheme.white38, size: 48),
          const SizedBox(height: 8),
          Text(
            'No songs in catalog yet',
            style: TextStyle(color: AppTheme.white38, fontSize: mediaWidth * 0.038),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder(double mediaWidth) {
    return Container(
      height: mediaWidth * 0.13,
      width: mediaWidth * 0.13,
      color: Colors.white12,
      child: const Icon(Icons.music_note, color: Colors.white38),
    );
  }

  Widget _buildRetroRadioSection(double mediaWidth, double mediaHeight, List<Song> retroRadioSongs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Retro Radio',
              style: TextStyle(
                color: AppTheme.white,
                fontSize: mediaWidth * 0.045,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (retroRadioSongs.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.redAccent.withValues(alpha: 0.5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [

                  ],
                ),
              ),
          ],
        ),
        SizedBox(height: mediaHeight * 0.015),
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Container(
            width: double.infinity,
            height: mediaHeight * 0.22,
            decoration: BoxDecoration(
              color: AppTheme.cardBackground,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: AppTheme.primaryAccent.withValues(alpha: 0.4),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryAccent.withValues(alpha: 0.15),
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Stack(
              children: [
                // 1. Radio Asset Image Background
                Positioned.fill(
                  child: Image.asset(
                    'assets/images/radio.jpg',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Image.asset(
                        'assets/images/radio.png',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: AppTheme.cardBackground,
                            child: Icon(Icons.radio, color: AppTheme.white38, size: mediaWidth * 0.15),
                          );
                        },
                      );
                    },
                  ),
                ),

                // 2. Dark Gradient Overlay for Perfect Text Legibility
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.65),
                          Colors.black.withValues(alpha: 0.85),
                        ],
                      ),
                    ),
                  ),
                ),

                // 3. Card Content & Controls
                Padding(
                  padding: EdgeInsets.all(mediaWidth * 0.045),
                  child: retroRadioSongs.isEmpty
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.radio, color: AppTheme.white38, size: mediaWidth * 0.1),
                            const SizedBox(height: 8),
                            Text(
                              'No radio tracks available yet.',
                              style: TextStyle(
                                color: AppTheme.white70,
                                fontSize: mediaWidth * 0.038,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Check back soon for non-stop retro vibes.',
                              style: TextStyle(
                                color: AppTheme.white38,
                                fontSize: mediaWidth * 0.032,
                              ),
                            ),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.radio,
                                      color: AppTheme.yellow300,
                                      size: mediaWidth * 0.06,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'RETRO RADIO',
                                      style: TextStyle(
                                        color: AppTheme.yellow300,
                                        fontSize: mediaWidth * 0.048,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 2,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${retroRadioSongs.length} classic tracks • Endless Station',
                                  style: TextStyle(
                                    color: AppTheme.white70,
                                    fontSize: mediaWidth * 0.033,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),

                            // Play Radio Button
                            SizedBox(
                              width: double.infinity,
                              height: mediaHeight * 0.055,
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.play_arrow, color: Colors.black, size: 24),
                                label: const Text(
                                  'PLAY RADIO',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    letterSpacing: 1.5,
                                    color: Colors.black,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.yellow300,
                                  foregroundColor: Colors.black,
                                  elevation: 4,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: () {
                                  final shuffledRadio = List<Song>.from(retroRadioSongs)..shuffle();
                                  final startSong = shuffledRadio.first;
                                  widget.onSongTap(startSong, shuffledRadio);
                                },
                              ),
                            ),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: mediaHeight * 0.025),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:retro_vibes/model/song.dart';
import 'package:retro_vibes/provider/music_provider.dart';
import 'package:retro_vibes/provider/song_provider.dart';
import 'package:retro_vibes/screens/music_player_screen.dart';
import 'package:retro_vibes/theme/app_theme.dart';

class CategoryDetailScreen extends StatefulWidget {
  final String categoryTitle;

  const CategoryDetailScreen({super.key, required this.categoryTitle});

  @override
  State<CategoryDetailScreen> createState() => _CategoryDetailScreenState();
}

class _CategoryDetailScreenState extends State<CategoryDetailScreen> {
  String _selectedGenreChip = 'All';

  final List<String> _genreChips = const [
    'All',
    'Classic Rock',
    'Retro Pop',
    'Romantic',
    'Ghazal',
    'Synthwave',
    'Indie Retro',
  ];

  List<Song> _getRealSongsForCategory(List<Song> publishedSongs, String categoryTitle) {
    final titleClean = categoryTitle.toLowerCase().trim();

    // Check exact category / album / genre match
    final directCategoryMatches = publishedSongs.where((s) {
      final alb = s.album.toLowerCase().trim();
      final gnr = s.genre.toLowerCase().trim();
      return alb == titleClean || gnr == titleClean;
    }).toList();

    if (directCategoryMatches.isNotEmpty && !titleClean.contains('genre') && !titleClean.contains('chart')) {
      return directCategoryMatches;
    }

    if (titleClean.contains('podcast')) {
      return publishedSongs.where((s) {
        final g = s.genre.toLowerCase();
        final a = s.album.toLowerCase();
        final t = s.title.toLowerCase();
        return g.contains('podcast') || g.contains('talk') || g.contains('show') || a.contains('podcast') || t.contains('podcast') || t.contains('episode');
      }).toList();
    }

    if (titleClean.contains('genre')) {
      if (_selectedGenreChip == 'All') return publishedSongs;
      return publishedSongs.where((s) {
        return s.genre.toLowerCase().contains(_selectedGenreChip.toLowerCase());
      }).toList();
    }

    if (titleClean.contains('70s')) {
      return publishedSongs.where((s) {
        final year = int.tryParse(s.releaseYear) ?? 0;
        return year >= 1970 && year <= 1979;
      }).toList();
    }

    if (titleClean.contains('80s')) {
      return publishedSongs.where((s) {
        final year = int.tryParse(s.releaseYear) ?? 0;
        return year >= 1980 && year <= 1989 || s.album.toLowerCase().contains('80s');
      }).toList();
    }

    if (titleClean.contains('90s')) {
      return publishedSongs.where((s) {
        final year = int.tryParse(s.releaseYear) ?? 0;
        return year >= 1990 && year <= 1999;
      }).toList();
    }

    if (titleClean.contains('2000s')) {
      return publishedSongs.where((s) {
        final year = int.tryParse(s.releaseYear) ?? 0;
        return year >= 2000 && year <= 2009;
      }).toList();
    }

    if (titleClean.contains('chart') || titleClean.contains('top')) {
      final sortedList = List<Song>.from(publishedSongs);
      sortedList.sort((a, b) => b.playCount.compareTo(a.playCount));
      return sortedList;
    }

    if (titleClean.contains('all') || titleClean.contains('catalog')) {
      return publishedSongs;
    }

    // Default search by title/genre/artist
    return publishedSongs.where((s) {
      return s.genre.toLowerCase().contains(titleClean) ||
          s.artist.toLowerCase().contains(titleClean) ||
          s.album.toLowerCase().contains(titleClean) ||
          s.title.toLowerCase().contains(titleClean);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    double mediaHeight = MediaQuery.of(context).size.height;
    double mediaWidth = MediaQuery.of(context).size.width;
    final songProvider = context.watch<SongProvider>();
    final publishedSongs = songProvider.publishedSongs;

    final categorySongs = _getRealSongsForCategory(publishedSongs, widget.categoryTitle);
    final isPodcastCategory = widget.categoryTitle.toLowerCase().contains('podcast');
    final isGenreCategory = widget.categoryTitle.toLowerCase().contains('genre');

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.scaffoldBackground,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: AppTheme.white, size: mediaWidth * 0.05),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.categoryTitle.toUpperCase(),
          style: TextStyle(
            color: AppTheme.white,
            fontSize: mediaWidth * 0.045,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: mediaWidth * 0.04,
          vertical: mediaHeight * 0.015,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category Hero Banner Card
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(mediaWidth * 0.05),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryAccent,
                    AppTheme.primaryAccent.withValues(alpha: 0.6),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryAccent.withValues(alpha: 0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(mediaWidth * 0.035),
                    decoration: const BoxDecoration(
                      color: Colors.white12,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isPodcastCategory ? Icons.podcasts : isGenreCategory ? Icons.category : Icons.album,
                      color: AppTheme.white,
                      size: mediaWidth * 0.08,
                    ),
                  ),
                  SizedBox(width: mediaWidth * 0.04),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.categoryTitle,
                          style: TextStyle(
                            color: AppTheme.white,
                            fontSize: mediaWidth * 0.05,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: mediaHeight * 0.005),
                        Text(
                          isPodcastCategory
                              ? 'Listen to Retro Audio Podcasts & Shows'
                              : isGenreCategory
                                  ? 'Filter & Explore Live Retro Vibes By Genre'
                                  : 'Explore Curated Retro Tracks',
                          style: TextStyle(
                            color: AppTheme.white70,
                            fontSize: mediaWidth * 0.03,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: mediaHeight * 0.025),

            // If Genre Category, render interactive Genre Chips
            if (isGenreCategory) ...[
              Text(
                'Select Genre Vibe',
                style: TextStyle(
                  color: AppTheme.white,
                  fontSize: mediaWidth * 0.04,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: mediaHeight * 0.012),
              SizedBox(
                height: 38,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _genreChips.length,
                  itemBuilder: (context, index) {
                    final chip = _genreChips[index];
                    final isSel = _selectedGenreChip == chip;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedGenreChip = chip),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSel ? AppTheme.primaryAccent : AppTheme.cardBackground,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSel ? AppTheme.primaryAccent : Colors.white12,
                          ),
                        ),
                        child: Text(
                          chip,
                          style: TextStyle(
                            color: isSel ? AppTheme.white : AppTheme.white70,
                            fontSize: 12,
                            fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height: mediaHeight * 0.02),
            ],

            // Section Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'AVAILABLE TRACKS (${categorySongs.length})',
                  style: TextStyle(
                    color: AppTheme.white38,
                    fontSize: mediaWidth * 0.032,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),

            SizedBox(height: mediaHeight * 0.015),

            // Tracks List View
            categorySongs.isEmpty
                ? Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(mediaWidth * 0.08),
                    decoration: BoxDecoration(
                      color: AppTheme.cardBackground,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          isPodcastCategory ? Icons.podcasts_outlined : Icons.music_off_outlined,
                          color: AppTheme.white38,
                          size: 52,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          isPodcastCategory
                              ? 'No Retro Podcasts available yet.'
                              : 'No tracks found for "${isGenreCategory ? _selectedGenreChip : widget.categoryTitle}" yet.',
                          style: TextStyle(
                            color: AppTheme.white,
                            fontSize: mediaWidth * 0.038,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Explore available retro tracks or search for your favorite melodies.',
                          style: TextStyle(color: AppTheme.white38, fontSize: mediaWidth * 0.032),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : Consumer<MusicProvider>(
                    builder: (context, musicProvider, child) {
                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: categorySongs.length,
                        itemBuilder: (context, index) {
                          final song = categorySongs[index];
                          final isCurrent = musicProvider.currentSong?.title == song.title;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: isCurrent
                                  ? AppTheme.primaryAccent.withValues(alpha: 0.15)
                                  : AppTheme.cardBackground,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isCurrent ? AppTheme.primaryAccent : Colors.white12,
                                width: isCurrent ? 1.5 : 1,
                              ),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              leading: Stack(
                                alignment: Alignment.center,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: song.image.startsWith('http')
                                        ? Image.network(
                                            song.image,
                                            width: 48,
                                            height: 48,
                                            fit: BoxFit.cover,
                                            errorBuilder: (c, e, s) => _buildPlaceholder(),
                                          )
                                        : Image.asset(
                                            song.image.isNotEmpty ? song.image : 'assets/images/80s_hit.png',
                                            width: 48,
                                            height: 48,
                                            fit: BoxFit.cover,
                                            errorBuilder: (c, e, s) => _buildPlaceholder(),
                                          ),
                                  ),
                                  if (isCurrent && musicProvider.isPlaying)
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: Colors.black45,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(
                                        Icons.equalizer,
                                        color: Colors.white,
                                        size: 24,
                                      ),
                                    ),
                                ],
                              ),
                              title: Text(
                                song.title,
                                style: TextStyle(
                                  color: isCurrent ? AppTheme.primaryAccent : AppTheme.white,
                                  fontSize: mediaWidth * 0.038,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                '${song.artist} • ${song.releaseYear} • ${song.genre}',
                                style: TextStyle(
                                  color: AppTheme.white38,
                                  fontSize: mediaWidth * 0.03,
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
                                      fontSize: mediaWidth * 0.03,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(
                                    isCurrent && musicProvider.isPlaying
                                        ? Icons.pause_circle_filled
                                        : Icons.play_circle_fill,
                                    color: AppTheme.primaryAccent,
                                    size: mediaWidth * 0.08,
                                  ),
                                ],
                              ),
                              onTap: () {
                                musicProvider.playSong(song, playlist: categorySongs);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => MusicPlayerScreen(
                                      image: song.image,
                                      title: song.title,
                                      subtitle: song.artist,
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      );
                    },
                  ),
            SizedBox(height: mediaHeight * 0.05),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: 48,
      height: 48,
      color: Colors.white12,
      child: const Icon(Icons.music_note, color: Colors.white38),
    );
  }
}

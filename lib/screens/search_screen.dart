import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:retro_vibes/model/song.dart';
import 'package:retro_vibes/provider/music_provider.dart';
import 'package:retro_vibes/provider/song_provider.dart';
import 'package:retro_vibes/screens/category_detail_screen.dart';
import 'package:retro_vibes/screens/music_player_screen.dart';
import 'package:retro_vibes/theme/app_theme.dart';

class SearchScreen extends StatefulWidget {
  final Function(Song, [List<Song>?])? onSongTap;

  const SearchScreen({super.key, this.onSongTap});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'All';
  List<String> _recentSearches = [];

  final List<String> _filterOptions = const ['All', 'Songs', 'Artists', 'Genres'];

  final List<Map<String, dynamic>> categories = const [
    {"title": 'Retro Playlist', 'icon': Icons.library_music, 'image': 'assets/images/70s.png', 'color1': Color(0xFF984818), 'color2': Color(0xFF582008)},
    {"title": '80s Albums', 'icon': Icons.album, 'image': 'assets/images/80s_hit.png', 'color1': Color(0xFFB08860), 'color2': Color(0xFF604028)},
    {"title": 'Classic Artists', 'icon': Icons.person, 'image': 'assets/images/90s.png', 'color1': Color(0xFF405040), 'color2': Color(0xFF182818)},
    {"title": 'Podcasts', 'icon': Icons.podcasts, 'image': 'assets/images/2000s_hits.png', 'color1': Color(0xFF782818), 'color2': Color(0xFF380800)},
    {"title": 'Nostalgia Genres', 'icon': Icons.music_note, 'image': 'assets/images/2010s_chill_Vibe.png', 'color1': Color(0xFF402028), 'color2': Color(0xFF180810)},
    {"title": 'Top Charts', 'icon': Icons.bar_chart, 'image': 'assets/images/2020s_hit.png', 'color1': Color(0xFF303838), 'color2': Color(0xFF101818)},
  ];

  final List<Map<String, String>> trendingArtists = const [
    {'name': 'Mukesh', 'genre': 'Rock'},
    {'name': 'Kishore Kumar', 'genre': 'Bollywood Retro'},
    {'name': 'Elvis Presley', 'genre': 'Rock & Roll'},
    {'name': 'A.R. Rahman', 'genre': '90s Melodies'},
    {'name': 'Anuv Jain', 'genre': 'Indie Retro'},
  ];

  @override
  void initState() {
    super.initState();
    _loadRecentSearches();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRecentSearches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _recentSearches = prefs.getStringList('recent_search_history') ?? ['Queen', '80s Hits', 'Kishore Kumar'];
      });
    } catch (_) {}
  }

  Future<void> _addRecentSearch(String query) async {
    if (query.trim().isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> current = prefs.getStringList('recent_search_history') ?? [];
      current.removeWhere((item) => item.toLowerCase() == query.trim().toLowerCase());
      current.insert(0, query.trim());
      if (current.length > 6) current = current.sublist(0, 6);
      await prefs.setStringList('recent_search_history', current);
      setState(() {
        _recentSearches = current;
      });
    } catch (_) {}
  }

  Future<void> _removeRecentSearch(String term) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> current = prefs.getStringList('recent_search_history') ?? [];
      current.removeWhere((item) => item.toLowerCase() == term.toLowerCase());
      await prefs.setStringList('recent_search_history', current);
      setState(() {
        _recentSearches = current;
      });
    } catch (_) {}
  }

  Future<void> _clearRecentSearches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('recent_search_history');
      setState(() {
        _recentSearches = [];
      });
    } catch (_) {}
  }

  void _triggerSearch(String term) {
    _searchController.text = term;
    setState(() {
      _searchQuery = term;
    });
    _addRecentSearch(term);
  }

  @override
  Widget build(BuildContext context) {
    double mediaHeight = MediaQuery.of(context).size.height;
    double mediaWidth = MediaQuery.of(context).size.width;

    final songProvider = context.watch<SongProvider>();
    final publishedSongs = songProvider.publishedSongs;

    final filteredSongs = publishedSongs.where((song) {
      final query = _searchQuery.toLowerCase().trim();
      if (query.isEmpty) return false;

      final titleMatch = song.title.toLowerCase().contains(query);
      final artistMatch = song.artist.toLowerCase().contains(query);
      final genreMatch = song.genre.toLowerCase().contains(query);

      switch (_selectedFilter) {
        case 'Songs':
          return titleMatch;
        case 'Artists':
          return artistMatch;
        case 'Genres':
          return genreMatch;
        default:
          return titleMatch || artistMatch || genreMatch;
      }
    }).toList();

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackground,
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: mediaWidth * 0.04),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: mediaHeight * 0.02),

                // Header Title
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Search',
                      style: TextStyle(
                        color: AppTheme.white,
                        fontSize: mediaWidth * 0.06,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),

                // Search Input Box
                Container(
                  margin: EdgeInsets.symmetric(vertical: mediaHeight * 0.015),
                  decoration: BoxDecoration(
                    color: AppTheme.cardBackground,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppTheme.primaryAccent.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryAccent.withValues(alpha: 0.08),
                        blurRadius: 10,
                      )
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                    onSubmitted: (value) {
                      if (value.trim().isNotEmpty) {
                        _addRecentSearch(value.trim());
                      }
                    },
                    textAlignVertical: TextAlignVertical.center,
                    style: TextStyle(color: AppTheme.white, fontSize: mediaWidth * 0.04),
                    decoration: InputDecoration(
                      prefixIcon: Icon(
                        Icons.search,
                        color: AppTheme.yellow300,
                        size: mediaWidth * 0.06,
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: AppTheme.white38),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = '';
                                });
                              },
                            )
                          : const Icon(Icons.tune, color: AppTheme.white38),
                      border: InputBorder.none,
                      hintText: "Search songs, artists, genres...",
                      hintStyle: TextStyle(
                        color: AppTheme.white38,
                        fontSize: mediaWidth * 0.035,
                      ),
                    ),
                  ),
                ),

                // Quick Filter Chips Row (Songs, Artists, Genres)
                SizedBox(
                  height: 38,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: _filterOptions.length,
                    itemBuilder: (context, index) {
                      final option = _filterOptions[index];
                      final isSelected = _selectedFilter == option;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedFilter = option;
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? AppTheme.yellow300 : AppTheme.cardBackground,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected ? AppTheme.yellow300 : Colors.white12,
                            ),
                          ),
                          child: Text(
                            option,
                            style: TextStyle(
                              color: isSelected ? Colors.black : AppTheme.white70,
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                SizedBox(height: mediaHeight * 0.02),

                // SEARCH ACTIVE RESULTS VIEW
                if (_searchQuery.isNotEmpty) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Results (${filteredSongs.length})',
                        style: TextStyle(
                          color: AppTheme.white,
                          fontSize: mediaWidth * 0.045,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Filter: $_selectedFilter',
                        style: TextStyle(color: AppTheme.yellow300, fontSize: 12),
                      ),
                    ],
                  ),
                  SizedBox(height: mediaHeight * 0.015),
                  if (filteredSongs.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(28),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppTheme.cardBackground,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.search_off_outlined, color: AppTheme.white38, size: 48),
                          const SizedBox(height: 12),
                          Text(
                            'No matches found for "$_searchQuery"',
                            style: TextStyle(
                              color: AppTheme.white,
                              fontSize: mediaWidth * 0.038,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Try searching another track, artist, or genre.',
                            style: TextStyle(color: AppTheme.white38, fontSize: mediaWidth * 0.032),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  else
                    ListView.builder(
                      itemCount: filteredSongs.length,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemBuilder: (context, index) {
                        final song = filteredSongs[index];
                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.cardBackground.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            onTap: () {
                              _addRecentSearch(song.title);
                              if (widget.onSongTap != null) {
                                widget.onSongTap!(song, filteredSongs);
                              } else {
                                final musicProvider = context.read<MusicProvider>();
                                musicProvider.playSong(song, playlist: filteredSongs);
                                musicProvider.setMusicPlayerOpen(true);
                                Navigator.of(context, rootNavigator: true).push(
                                  MaterialPageRoute(
                                    builder: (context) => MusicPlayerScreen(
                                      image: song.image,
                                      title: song.title,
                                      subtitle: song.artist,
                                    ),
                                  ),
                                ).then((_) {
                                  musicProvider.setMusicPlayerOpen(false);
                                });
                              }
                            },
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                            title: Text(
                              song.title,
                              style: TextStyle(
                                color: AppTheme.white,
                                fontSize: mediaWidth * 0.038,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              '${song.artist} • ${song.genre} • ${song.duration}',
                              style: TextStyle(
                                color: AppTheme.white38,
                                fontSize: mediaWidth * 0.032,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: song.image.startsWith('http')
                                  ? Image.network(
                                      song.image,
                                      height: mediaWidth * 0.11,
                                      width: mediaWidth * 0.11,
                                      fit: BoxFit.cover,
                                      errorBuilder: (c, e, s) => _buildPlaceholder(mediaWidth),
                                    )
                                  : Image.asset(
                                      song.image.isNotEmpty ? song.image : 'assets/images/80s_hit.png',
                                      height: mediaWidth * 0.11,
                                      width: mediaWidth * 0.11,
                                      fit: BoxFit.cover,
                                      errorBuilder: (c, e, s) => _buildPlaceholder(mediaWidth),
                                    ),
                            ),
                            trailing: Icon(
                              Icons.play_circle_fill,
                              color: AppTheme.primaryAccent,
                              size: mediaWidth * 0.07,
                            ),
                          ),
                        );
                      },
                    ),
                ] else ...[
                  // RECENT SEARCHES SECTION
                  if (_recentSearches.isNotEmpty) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Recent Searches',
                          style: TextStyle(
                            color: AppTheme.white,
                            fontSize: mediaWidth * 0.042,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        GestureDetector(
                          onTap: _clearRecentSearches,
                          child: Text(
                            'Clear All',
                            style: TextStyle(
                              color: AppTheme.primaryAccent,
                              fontSize: mediaWidth * 0.035,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: mediaHeight * 0.012),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _recentSearches.map((term) {
                        return Container(
                          decoration: BoxDecoration(
                            color: AppTheme.cardBackground,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: () => _triggerSearch(term),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.history, color: AppTheme.white38, size: 14),
                                    const SizedBox(width: 6),
                                    Text(
                                      term,
                                      style: TextStyle(color: AppTheme.white70, fontSize: 13),
                                    ),
                                    const SizedBox(width: 6),
                                    GestureDetector(
                                      onTap: () => _removeRecentSearch(term),
                                      child: Icon(Icons.close, color: AppTheme.white38, size: 14),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    SizedBox(height: mediaHeight * 0.025),
                  ],

                  // TRENDING ARTISTS CAROUSEL SECTION
                  Text(
                    'Trending Artists',
                    style: TextStyle(
                      color: AppTheme.white,
                      fontSize: mediaWidth * 0.045,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: mediaHeight * 0.012),
                  SizedBox(
                    height: mediaHeight * 0.13,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: trendingArtists.length,
                      itemBuilder: (context, index) {
                        final artistData = trendingArtists[index];
                        return GestureDetector(
                          onTap: () => _triggerSearch(artistData['name']!),
                          child: Container(
                            margin: const EdgeInsets.only(right: 14),
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: AppTheme.yellow300, width: 1.5),
                                  ),
                                  child: CircleAvatar(
                                    radius: mediaWidth * 0.08,
                                    backgroundColor: AppTheme.cardBackground,
                                    child: Text(
                                      artistData['name']![0],
                                      style: TextStyle(
                                        color: AppTheme.white,
                                        fontSize: mediaWidth * 0.05,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  artistData['name']!,
                                  style: TextStyle(
                                    color: AppTheme.white,
                                    fontSize: mediaWidth * 0.032,
                                    fontWeight: FontWeight.bold,
                                  ),
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

                  SizedBox(height: mediaHeight * 0.02),

                  // BROWSE ALL CATEGORIES GRID SECTION
                  Text(
                    'Browse All Categories',
                    style: TextStyle(
                      color: AppTheme.white,
                      fontSize: mediaWidth * 0.045,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: mediaHeight * 0.015),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: categories.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.6,
                    ),
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      final catTitle = category['title'] as String;

                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CategoryDetailScreen(
                                categoryTitle: catTitle,
                              ),
                            ),
                          );
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                category['color1'] as Color,
                                category['color2'] as Color,
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: (category['color1'] as Color).withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(12),
                          child: Stack(
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        catTitle,
                                        style: TextStyle(
                                          color: AppTheme.white,
                                          fontSize: mediaWidth * 0.038,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        category['subtitle'] as String? ?? '',
                                        style: TextStyle(
                                          color: AppTheme.white70,
                                          fontSize: mediaWidth * 0.028,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Icon(
                                        category['icon'] as IconData,
                                        color: AppTheme.white.withValues(alpha: 0.8),
                                        size: mediaWidth * 0.075,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  SizedBox(height: mediaHeight * 0.03),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder(double mediaWidth) {
    return Container(
      height: mediaWidth * 0.11,
      width: mediaWidth * 0.11,
      color: Colors.white12,
      child: const Icon(Icons.music_note, color: Colors.white38),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:retro_vibes/data/dummy_songs.dart';
import 'package:retro_vibes/model/song.dart';
import 'package:retro_vibes/provider/auth_provider.dart';
import 'package:retro_vibes/provider/music_provider.dart';
import 'package:retro_vibes/provider/song_provider.dart';
import 'package:retro_vibes/screens/music_player_screen.dart';
import 'package:retro_vibes/screens/playlist_detail_screen.dart';
import 'package:retro_vibes/theme/app_theme.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  // final List<Map<String, String>> defaultPlaylists = const [
  //   {
  //     'title': '70s Road Trip',
  //     'subtitle': 'Golden Era Hits',
  //     'image': 'assets/images/70s.png',
  //   },
  //   {
  //     'title': '80s Hits',
  //     'subtitle': 'Synthwave & Pop',
  //     'image': 'assets/images/80s_hit.png',
  //   },
  //   {
  //     'title': '90s Nostalgia',
  //     'subtitle': 'Cassette Beats',
  //     'image': 'assets/images/90s.png',
  //   },
  //   {
  //     'title': '2000s Hits',
  //     'subtitle': 'Melody Pop',
  //     'image': 'assets/images/2000s_hits.png',
  //   },
  // ];

  void _showCreatePlaylistDialog(BuildContext context, String? userId) {
    final TextEditingController nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Create New Playlist',
          style: TextStyle(color: AppTheme.white, fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: nameController,
          style: TextStyle(color: AppTheme.white),
          decoration: InputDecoration(
            hintText: 'Enter playlist title...',
            hintStyle: TextStyle(color: AppTheme.white38),
            enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.yellow300)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text('Cancel', style: TextStyle(color: AppTheme.white38)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.yellow300, foregroundColor: Colors.black),
            onPressed: () {
              final text = nameController.text.trim();
              if (text.isNotEmpty) {
                context.read<MusicProvider>().createPlaylist(text, userId: userId);
                Navigator.pop(dialogCtx);
              }
            },
            child: const Text('Create', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double mediaHeight = MediaQuery.of(context).size.height;
    double mediaWidth = MediaQuery.of(context).size.width;

    final authProvider = context.watch<AuthProvider>();
    final musicProvider = context.watch<MusicProvider>();
    final songProvider = context.watch<SongProvider>();

    final userId = authProvider.currentUser?.uid;
    if (userId != null && userId.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<MusicProvider>().syncUserLibrary(userId);
      });
    }

    final publishedSongs = songProvider.publishedSongs;

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: AppTheme.scaffoldBackground,
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: AppTheme.playerAccent,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add, size: 20),
          label: const Text('New Playlist', style: TextStyle(fontWeight: FontWeight.bold)),
          onPressed: () => _showCreatePlaylistDialog(context, userId),
        ),
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: mediaWidth * 0.04),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: mediaHeight * 0.02),

                // Header Top Bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Your Library',
                      style: TextStyle(
                        color: AppTheme.white,
                        fontSize: mediaWidth * 0.06,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    IconButton(
                      onPressed: () => _showCreatePlaylistDialog(context, userId),
                      icon: Icon(Icons.playlist_add, color: AppTheme.playerAccent, size: mediaWidth * 0.07),
                    )
                  ],
                ),

                // Tab Bar
                Container(
                  margin: EdgeInsets.symmetric(vertical: mediaHeight * 0.015),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: TabBar(
                    indicator: BoxDecoration(
                      color: AppTheme.playerAccent,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelStyle: TextStyle(fontSize: mediaWidth * 0.032, fontWeight: FontWeight.bold),
                    labelColor: Colors.white,
                    unselectedLabelColor: AppTheme.white70,
                    dividerColor: Colors.transparent,
                    tabs: const [
                      Tab(text: 'Playlists'),
                      Tab(text: 'Songs'),
                      Tab(text: 'Albums'),
                      Tab(text: 'Artists'),
                    ],
                  ),
                ),

                // Tab Views
                Expanded(
                  child: TabBarView(
                    children: [
                      // TAB 1: PLAYLISTS
                      _buildPlaylistsTab(context, mediaWidth, mediaHeight, musicProvider, userId),

                      // TAB 2: SONGS
                      _buildSongsTab(context, mediaWidth, musicProvider, publishedSongs, userId),

                      // TAB 3: ALBUMS
                      _buildAlbumsTab(context, mediaWidth, musicProvider, publishedSongs),

                      // TAB 4: ARTISTS
                      _buildArtistsTab(context, mediaWidth, musicProvider, publishedSongs),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaylistsTab(
    BuildContext context,
    double mediaWidth,
    double mediaHeight,
    MusicProvider musicProvider,
    String? userId,
  ) {
    final likedCount = musicProvider.likedSongs.length;
    final customPlaylists = musicProvider.customPlaylists;

    return ListView(
      physics: const BouncingScrollPhysics(),
      children: [
        // 1. Liked Songs Tile
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PlaylistDetailScreen(
                  title: 'Liked Songs',
                  image: 'assets/images/liked.png',
                  description: 'Your favorite saved tracks synced to Cloud Firestore',
                  songs: musicProvider.likedSongs,
                ),
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.cardBackground,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: AppTheme.deepOrangeAccent.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Container(
                  width: mediaWidth * 0.14,
                  height: mediaWidth * 0.14,
                  decoration: BoxDecoration(
                    color: AppTheme.deepOrangeAccent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.favorite,
                    color: AppTheme.white,
                    size: mediaWidth * 0.07,
                  ),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Liked Songs',
                      style: TextStyle(
                        color: AppTheme.white,
                        fontSize: mediaWidth * 0.04,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$likedCount ${likedCount == 1 ? "song" : "songs"} • Synced to account',
                      style: TextStyle(
                        color: AppTheme.white38,
                        fontSize: mediaWidth * 0.032,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Icon(Icons.arrow_forward_ios, size: 14, color: AppTheme.white38),
              ],
            ),
          ),
        ),

        // 2. Custom User Playlists (Created via app and saved in Firestore)
        if (customPlaylists.isNotEmpty)
          ...customPlaylists.keys.map((pName) {
            final pSongs = customPlaylists[pName]!;
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PlaylistDetailScreen(
                      title: pName,
                      image: 'assets/images/70s.png',
                      description: 'Custom Playlist • $pName',
                      songs: pSongs,
                    ),
                  ),
                );
              },
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 6),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.cardBackground,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.white12),
                ),
                child: Row(
                  children: [
                    Container(
                      width: mediaWidth * 0.14,
                      height: mediaWidth * 0.14,
                      decoration: BoxDecoration(
                        color: AppTheme.cardBackground,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.yellow300, width: 1),
                      ),
                      child: Icon(
                        Icons.queue_music,
                        color: AppTheme.yellow300,
                        size: mediaWidth * 0.07,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pName,
                          style: TextStyle(
                            color: AppTheme.white,
                            fontSize: mediaWidth * 0.04,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${pSongs.length} songs • Custom Playlist',
                          style: TextStyle(
                            color: AppTheme.white38,
                            fontSize: mediaWidth * 0.032,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                      onPressed: () {
                        musicProvider.deletePlaylist(pName, userId: userId);
                      },
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildSongsTab(
    BuildContext context,
    double mediaWidth,
    MusicProvider musicProvider,
    List<Song> publishedSongs,
    String? userId,
  ) {
    final songsToDisplay = publishedSongs.isNotEmpty ? publishedSongs : musicProvider.likedSongs;

    if (songsToDisplay.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.music_note, color: AppTheme.white38, size: 48),
            const SizedBox(height: 12),
            Text('No songs available in Library', style: TextStyle(color: AppTheme.white, fontSize: 16)),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: songsToDisplay.length,
      physics: const BouncingScrollPhysics(),
      itemBuilder: (context, index) {
        final song = songsToDisplay[index];
        final isLiked = musicProvider.isLiked(song);

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.cardBackground.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            onTap: () {
              musicProvider.playSong(song, playlist: songsToDisplay);
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
            },
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
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
              '${song.artist} • ${song.duration}',
              style: TextStyle(
                color: AppTheme.white38,
                fontSize: mediaWidth * 0.032,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: IconButton(
              icon: Icon(
                isLiked ? Icons.favorite : Icons.favorite_border,
                color: AppTheme.deepOrangeAccent,
                size: 22,
              ),
              onPressed: () {
                musicProvider.toggleLike(song, userId: userId);
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildAlbumsTab(
    BuildContext context,
    double mediaWidth,
    MusicProvider musicProvider,
    List<Song> publishedSongs,
  ) {
    final Map<String, List<Song>> albumsMap = {};
    for (final song in publishedSongs) {
      final albumName = song.album.isNotEmpty ? song.album : 'Retro Single';
      albumsMap.putIfAbsent(albumName, () => []).add(song);
    }

    if (albumsMap.isEmpty) {
      return Center(
        child: Text('No Albums found', style: TextStyle(color: AppTheme.white38, fontSize: 14)),
      );
    }

    return ListView.builder(
      itemCount: albumsMap.keys.length,
      physics: const BouncingScrollPhysics(),
      itemBuilder: (context, index) {
        final albumName = albumsMap.keys.elementAt(index);
        final albumSongs = albumsMap[albumName]!;
        final sampleSong = albumSongs.first;

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.cardBackground.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PlaylistDetailScreen(
                    title: albumName,
                    image: sampleSong.image,
                    description: 'Album by ${sampleSong.artist}',
                    songs: albumSongs,
                  ),
                ),
              );
            },
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: sampleSong.image.startsWith('http')
                  ? Image.network(sampleSong.image, width: 48, height: 48, fit: BoxFit.cover, errorBuilder: (c, e, s) => _buildPlaceholder(mediaWidth))
                  : Image.asset(sampleSong.image.isNotEmpty ? sampleSong.image : 'assets/images/80s_hit.png', width: 48, height: 48, fit: BoxFit.cover, errorBuilder: (c, e, s) => _buildPlaceholder(mediaWidth)),
            ),
            title: Text(
              albumName,
              style: TextStyle(
                color: AppTheme.white,
                fontSize: mediaWidth * 0.038,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              '${albumSongs.length} tracks • ${sampleSong.artist}',
              style: TextStyle(
                color: AppTheme.white38,
                fontSize: mediaWidth * 0.032,
              ),
            ),
            trailing: Icon(Icons.arrow_forward_ios, color: AppTheme.white38, size: 14),
          ),
        );
      },
    );
  }

  Widget _buildArtistsTab(
    BuildContext context,
    double mediaWidth,
    MusicProvider musicProvider,
    List<Song> publishedSongs,
  ) {
    final Map<String, List<Song>> artistsMap = {};
    for (final song in publishedSongs) {
      final artistName = song.artist.isNotEmpty ? song.artist : 'Retro Artist';
      artistsMap.putIfAbsent(artistName, () => []).add(song);
    }

    if (artistsMap.isEmpty) {
      return Center(
        child: Text('No Artists found', style: TextStyle(color: AppTheme.white38, fontSize: 14)),
      );
    }

    return ListView.builder(
      itemCount: artistsMap.keys.length,
      physics: const BouncingScrollPhysics(),
      itemBuilder: (context, index) {
        final artistName = artistsMap.keys.elementAt(index);
        final artistSongs = artistsMap[artistName]!;
        final sampleSong = artistSongs.first;

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.cardBackground.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PlaylistDetailScreen(
                    title: artistName,
                    image: sampleSong.image,
                    description: 'Popular tracks by $artistName',
                    songs: artistSongs,
                  ),
                ),
              );
            },
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            leading: CircleAvatar(
              radius: 22,
              backgroundColor: AppTheme.cardBackground,
              child: Text(
                artistName[0],
                style: TextStyle(color: AppTheme.yellow300, fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
            title: Text(
              artistName,
              style: TextStyle(
                color: AppTheme.white,
                fontSize: mediaWidth * 0.038,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              '${artistSongs.length} tracks • Artist',
              style: TextStyle(
                color: AppTheme.white38,
                fontSize: mediaWidth * 0.032,
              ),
            ),
            trailing: Icon(Icons.arrow_forward_ios, color: AppTheme.white38, size: 14),
          ),
        );
      },
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

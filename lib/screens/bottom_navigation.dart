import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:retro_vibes/model/song.dart';
import 'package:retro_vibes/provider/music_provider.dart';
import 'package:retro_vibes/screens/home_screen.dart';
import 'package:retro_vibes/screens/library_screen.dart';
import 'package:retro_vibes/screens/music_player_screen.dart';
import 'package:retro_vibes/screens/profile_screen.dart';
import 'package:retro_vibes/screens/search_screen.dart';
import 'package:retro_vibes/theme/app_theme.dart';
import 'package:retro_vibes/widgets/mini_player.dart';

class BottomNavigation extends StatefulWidget {
  const BottomNavigation({super.key});

  @override
  State<BottomNavigation> createState() => _BottomNavigationState();
}

class _BottomNavigationState extends State<BottomNavigation> {
  int currentIndex = 0;

  final List<GlobalKey<NavigatorState>> navigatorKey = [
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
  ];

  late final List<Widget> pages = [
    HomeScreen(
      onSongTap: (song, [playlist]) {
        openMusicPlayer(song, playlist);
      },
    ),
    SearchScreen(
      onSongTap: (song, [playlist]) {
        openMusicPlayer(song, playlist);
      },
    ),
    const LibraryScreen(),
    const ProfileScreen(),
  ];

  void openMusicPlayer(Song song, [List<Song>? playlist]) {
    final musicProvider = context.read<MusicProvider>();
    
    // Only call playSong if it's a different song OR if a specific playlist context is explicitly provided
    if (musicProvider.currentSong?.title != song.title || playlist != null) {
      musicProvider.playSong(song, playlist: playlist);
    }
    
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
      if (mounted) {
        context.read<MusicProvider>().setMusicPlayerOpen(false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final musicProvider = context.watch<MusicProvider>();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        // 1. Check if current tab's nested navigator can go back (e.g. CategoryDetailScreen -> SearchScreen)
        final currentNavigator = navigatorKey[currentIndex].currentState;
        if (currentNavigator != null && currentNavigator.canPop()) {
          currentNavigator.pop();
          return;
        }

        // 2. If nested navigator cannot go back and user is not on Home tab, switch to Home tab
        if (currentIndex != 0) {
          setState(() {
            currentIndex = 0;
          });
          return;
        }

        // 3. If on Home tab root, exit app
        SystemNavigator.pop();
      },
      child: Scaffold(
        backgroundColor: AppTheme.scaffoldBackground,
        bottomNavigationBar: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (musicProvider.currentSong != null && !musicProvider.isMusicPlayerOpen)
              MiniPlayer(
                image: musicProvider.currentSong!.image,
                title: musicProvider.currentSong!.title,
                subtitle: musicProvider.currentSong!.artist,
                onTap: () {
                  if (musicProvider.currentSong != null) {
                    openMusicPlayer(musicProvider.currentSong!);
                  }
                },
              ),
            Container(
              color: AppTheme.cardBackground,
              child: SafeArea(
                top: false,
                child: Theme(
                  data: Theme.of(context).copyWith(
                    splashColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    hoverColor: Colors.transparent,
                  ),
                  child: BottomNavigationBar(
                    onTap: (index) {
                      if (index == currentIndex) {
                        navigatorKey[index].currentState!.popUntil(
                          (route) => route.isFirst,
                        );
                      }
                      setState(() {
                        currentIndex = index;
                      });
                    },
                    items: [
                      BottomNavigationBarItem(
                        icon: Icon(Icons.home_outlined, color: AppTheme.yellow100),
                        label: 'Home',
                        activeIcon: Icon(Icons.home),
                      ),
                      BottomNavigationBarItem(
                        icon: Icon(
                          Icons.search_outlined,
                          color: AppTheme.yellow100,
                        ),
                        label: 'Search',
                        activeIcon: Icon(Icons.search),
                      ),
                      BottomNavigationBarItem(
                        icon: Icon(
                          Icons.library_music_outlined,
                          color: AppTheme.yellow100,
                        ),
                        label: 'Library',
                        activeIcon: Icon(Icons.library_music),
                      ),
                      BottomNavigationBarItem(
                        icon: Icon(
                          Icons.person_outline,
                          color: AppTheme.yellow100,
                        ),
                        label: 'Profile',
                        activeIcon: Icon(Icons.person),
                      ),
                    ],
                    currentIndex: currentIndex,
                    backgroundColor: AppTheme.cardBackground,
                    selectedItemColor: AppTheme.primaryAccent,
                    unselectedItemColor: AppTheme.unselectedItem,
                    type: BottomNavigationBarType.fixed,
                    elevation: 0,
                    selectedFontSize: 11,
                    unselectedFontSize: 11,
                    selectedLabelStyle: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.normal,
                    ),
                    iconSize: 22,
                  ),
                ),
              ),
            ),
          ],
        ),
        body: IndexedStack(
          index: currentIndex,
          children: List.generate(pages.length, (index) {
            return Navigator(
              key: navigatorKey[index],
              onGenerateRoute: (settings) {
                return MaterialPageRoute(builder: (context) => pages[index]);
              },
            );
          }),
        ),
      ),
    );
  }
}

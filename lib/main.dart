import 'package:audio_session/audio_session.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:provider/provider.dart';
import 'package:retro_vibes/firebase_options.dart';
import 'package:retro_vibes/provider/auth_provider.dart';
import 'package:retro_vibes/provider/library_provider.dart';
import 'package:retro_vibes/provider/music_provider.dart';
import 'package:retro_vibes/provider/song_provider.dart';
import 'package:retro_vibes/provider/theme_provider.dart';
import 'package:retro_vibes/screens/splash_screen.dart';
import 'package:retro_vibes/services/app_audio_service.dart';
import 'package:retro_vibes/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configure AudioSession for Android audio focus and playback management
  try {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());
    debugPrint("[RETRO_AUDIO] AudioSession configured successfully.");
  } catch (e) {
    debugPrint("[RETRO_AUDIO_ERROR] AudioSession configuration error: $e");
  }

  // 1. Starting background audio initialization
  debugPrint("[RETRO_AUDIO_INIT] Starting background audio initialization");
  debugPrint("[RETRO_AUDIO_BG] Starting AudioService initialization");

  try {
    debugPrint("[RETRO_AUDIO_BG] Calling JustAudioBackground.init");
    await JustAudioBackground.init(
      androidNotificationChannelId: 'com.ktech.retro_vibes.channel.audio',
      androidNotificationChannelName: 'Retro Vibes Playback',
      androidNotificationOngoing: true,
    );
    debugPrint("[RETRO_AUDIO_BG] AudioService initialization SUCCESS");
    debugPrint("[RETRO_AUDIO_INIT] Background audio initialization completed");
  } catch (e, st) {
    debugPrint("[RETRO_AUDIO_BG] AudioService initialization FAILED: $e");
    debugPrint("[RETRO_AUDIO_BG] StackTrace: $st");
  }

  // 2. Creating AudioPlayer & AudioPlayer ready (AFTER JustAudioBackground.init completes)
  AppAudioService.instance.initPlayer();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint("Firebase initializeApp note: $e");
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => SongProvider()),
        ChangeNotifierProvider(create: (_) => LibraryProvider()),
        ChangeNotifierProvider(create: (_) => MusicProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          key: ValueKey(themeProvider.currentTheme),
          debugShowCheckedModeBanner: false,
          theme: AppTheme.themeData,
          home: const SplashScreen(),
        );
      },
    );
  }
}

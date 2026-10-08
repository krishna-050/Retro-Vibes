import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:retro_vibes/firebase_options.dart';
import 'package:retro_vibes/provider/auth_provider.dart';
import 'package:retro_vibes/provider/library_provider.dart';
import 'package:retro_vibes/provider/music_provider.dart';
import 'package:retro_vibes/provider/song_provider.dart';
import 'package:retro_vibes/provider/theme_provider.dart';
import 'package:retro_vibes/screens/admin/admin_web_login_screen.dart';
import 'package:retro_vibes/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint("Firebase initializeApp web note: $e");
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
      child: const WebAdminApp(),
    ),
  );
}

class WebAdminApp extends StatelessWidget {
  const WebAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Retro Vibes - Admin Portal',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: AppTheme.scaffoldBackground,
      ),
      home: const AdminWebLoginScreen(),
    );
  }
}

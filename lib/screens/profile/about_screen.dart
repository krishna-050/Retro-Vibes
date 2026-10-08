import 'package:flutter/material.dart';
import 'package:retro_vibes/theme/app_theme.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    double mediaWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.scaffoldBackground,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: AppTheme.white, size: mediaWidth * 0.055),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('About Retro Vibes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 12),

            // Logo & Title
            Center(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.cardBackground,
                      border: Border.all(color: AppTheme.primaryAccent, width: 2),
                    ),
                    child: Icon(Icons.equalizer, color: AppTheme.primaryAccent, size: 48),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Retro ', style: TextStyle(color: AppTheme.white, fontSize: 26, fontWeight: FontWeight.bold)),
                      Text('Vibes', style: TextStyle(color: const Color(0xFFC85A32), fontSize: 28, fontFamily: 'Cursive', fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('Version 1.0.0+1', style: TextStyle(color: AppTheme.white38, fontSize: 13, fontWeight: FontWeight.w600)),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Description Box
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppTheme.cardBackground.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('FEEL THE CLASSIC', style: TextStyle(color: AppTheme.primaryAccent, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 2)),
                  const SizedBox(height: 8),
                  Text(
                    'Retro Vibes is a premium 80s & 90s aesthetic music application featuring lossless audio streaming, curated vinyl collections, customizable themes, and built-in retro arcade mini-games.',
                    style: TextStyle(color: AppTheme.white70, fontSize: 13, height: 1.5),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            Text(
              '© ${DateTime.now().year} Retro Vibes. All Rights Reserved.',
              style: TextStyle(color: AppTheme.white38, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

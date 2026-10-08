import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:retro_vibes/provider/music_provider.dart';
import 'package:retro_vibes/theme/app_theme.dart';

class PlaybackSettingsScreen extends StatelessWidget {
  const PlaybackSettingsScreen({super.key});

  void _showQualityPicker(BuildContext context, MusicProvider musicProvider) {
    final currentQuality = musicProvider.audioQuality;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardBackground,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Select Audio Quality', style: TextStyle(color: AppTheme.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _buildQualityOption(context, musicProvider, 'Lossless Master (320kbps)', currentQuality),
              _buildQualityOption(context, musicProvider, 'High (256kbps)', currentQuality),
              _buildQualityOption(context, musicProvider, 'Standard (160kbps)', currentQuality),
              _buildQualityOption(context, musicProvider, 'Data Saver (96kbps)', currentQuality),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQualityOption(BuildContext context, MusicProvider musicProvider, String quality, String currentQuality) {
    final isSelected = currentQuality.contains(quality.split(' ').first);
    return ListTile(
      title: Text(quality, style: TextStyle(color: isSelected ? AppTheme.primaryAccent : AppTheme.white, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      trailing: isSelected ? Icon(Icons.check, color: AppTheme.primaryAccent) : null,
      onTap: () {
        musicProvider.setAudioQuality(quality);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Audio quality set to $quality'), backgroundColor: AppTheme.cardBackground),
        );
      },
    );
  }

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
        title: const Text('Playback Settings', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Consumer<MusicProvider>(
        builder: (context, musicProvider, child) {
          return ListView(
            padding: const EdgeInsets.all(20.0),
            children: [
              Text('STREAMING & QUALITY', style: TextStyle(color: AppTheme.white38, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
              const SizedBox(height: 12),

              Container(
                decoration: BoxDecoration(
                  color: AppTheme.cardBackground.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white12),
                ),
                child: ListTile(
                  leading: Icon(Icons.high_quality, color: AppTheme.primaryAccent, size: 28),
                  title: Text('Audio Streaming Quality', style: TextStyle(color: AppTheme.white, fontWeight: FontWeight.w600, fontSize: 15)),
                  subtitle: Text(musicProvider.audioQuality, style: TextStyle(color: AppTheme.white38, fontSize: 12)),
                  trailing: Icon(Icons.arrow_forward_ios, color: AppTheme.white38, size: 16),
                  onTap: () => _showQualityPicker(context, musicProvider),
                ),
              ),

              const SizedBox(height: 24),
              Text('PLAYBACK AUTOMATION', style: TextStyle(color: AppTheme.white38, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
              const SizedBox(height: 12),

              Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppTheme.cardBackground.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white12),
                ),
                child: SwitchListTile(
                  activeThumbColor: AppTheme.primaryAccent,
                  title: Text('Autoplay Next Track', style: TextStyle(color: AppTheme.white, fontWeight: FontWeight.w600, fontSize: 15)),
                  subtitle: Text('Automatically continue playing next song when current finishes', style: TextStyle(color: AppTheme.white38, fontSize: 12)),
                  value: musicProvider.isAutoplayNext,
                  onChanged: (val) {
                    musicProvider.setAutoplayNext(val);
                  },
                ),
              ),

              Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppTheme.cardBackground.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white12),
                ),
                child: SwitchListTile(
                  activeThumbColor: AppTheme.primaryAccent,
                  title: Text('Shuffle Mode', style: TextStyle(color: AppTheme.white, fontWeight: FontWeight.w600, fontSize: 15)),
                  subtitle: Text('Randomize playlist order during playback', style: TextStyle(color: AppTheme.white38, fontSize: 12)),
                  value: musicProvider.isShuffle,
                  onChanged: (val) {
                    musicProvider.toggleShuffle();
                  },
                ),
              ),

              Container(
                decoration: BoxDecoration(
                  color: AppTheme.cardBackground.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white12),
                ),
                child: SwitchListTile(
                  activeThumbColor: AppTheme.primaryAccent,
                  title: Text('Repeat Single Track', style: TextStyle(color: AppTheme.white, fontWeight: FontWeight.w600, fontSize: 15)),
                  subtitle: Text('Continuously repeat the currently playing song', style: TextStyle(color: AppTheme.white38, fontSize: 12)),
                  value: musicProvider.isRepeat,
                  onChanged: (val) {
                    musicProvider.toggleRepeat();
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

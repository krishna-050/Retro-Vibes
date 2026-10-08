import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:retro_vibes/theme/app_theme.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool _newMusic = true;
  bool _playlistUpdates = true;
  bool _appUpdates = false;
  bool _promotions = false;

  @override
  void initState() {
    super.initState();
    _loadNotificationPreferences();
  }

  Future<void> _loadNotificationPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _newMusic = prefs.getBool('pref_notif_new_music') ?? true;
        _playlistUpdates = prefs.getBool('pref_notif_playlist') ?? true;
        _appUpdates = prefs.getBool('pref_notif_app_updates') ?? false;
        _promotions = prefs.getBool('pref_notif_promotions') ?? false;
      });
    } catch (_) {}
  }

  Future<void> _savePreference(String key, bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(key, value);
    } catch (_) {}
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
        title: const Text('Notifications', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20.0),
        children: [
          _buildSwitchTile(
            title: 'New Music Releases',
            subtitle: 'Get notified when favorite retro artists publish new tracks',
            value: _newMusic,
            onChanged: (val) {
              setState(() => _newMusic = val);
              _savePreference('pref_notif_new_music', val);
            },
          ),
          _buildSwitchTile(
            title: 'Playlist Updates',
            subtitle: 'Notifications when songs are added to followed playlists',
            value: _playlistUpdates,
            onChanged: (val) {
              setState(() => _playlistUpdates = val);
              _savePreference('pref_notif_playlist', val);
            },
          ),
          _buildSwitchTile(
            title: 'App Updates & Features',
            subtitle: 'Receive updates about new Retro Vibes app features and Easter eggs',
            value: _appUpdates,
            onChanged: (val) {
              setState(() => _appUpdates = val);
              _savePreference('pref_notif_app_updates', val);
            },
          ),
          _buildSwitchTile(
            title: 'Promotional Offers',
            subtitle: 'Special discounts on Retro Vibes Premium membership',
            value: _promotions,
            onChanged: (val) {
              setState(() => _promotions = val);
              _savePreference('pref_notif_promotions', val);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: SwitchListTile(
        activeColor: AppTheme.primaryAccent,
        title: Text(title, style: TextStyle(color: AppTheme.white, fontWeight: FontWeight.w600, fontSize: 15)),
        subtitle: Text(subtitle, style: TextStyle(color: AppTheme.white38, fontSize: 12)),
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}

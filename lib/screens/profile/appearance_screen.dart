import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:retro_vibes/provider/theme_provider.dart';
import 'package:retro_vibes/theme/app_theme.dart';

class AppearanceScreen extends StatefulWidget {
  const AppearanceScreen({super.key});

  @override
  State<AppearanceScreen> createState() => _AppearanceScreenState();
}

class _AppearanceScreenState extends State<AppearanceScreen> {
  bool _animations = true;
  bool _reduceMotion = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _animations = prefs.getBool('pref_animations') ?? true;
        _reduceMotion = prefs.getBool('pref_reduce_motion') ?? false;
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
    final themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.scaffoldBackground,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: AppTheme.white, size: mediaWidth * 0.055),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Appearance & Theme', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20.0),
        children: [
          Text('RETRO THEME SELECTION', style: TextStyle(color: AppTheme.white38, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
          const SizedBox(height: 12),

          _buildThemeCard(
            title: 'Classic Retro (Default)',
            subtitle: 'Warm retro amber & neon orange glow',
            type: RetroThemeType.classic,
            currentType: themeProvider.currentTheme,
            onTap: () => themeProvider.setTheme(RetroThemeType.classic),
          ),

          _buildThemeCard(
            title: 'Spider-Man Dark Red',
            subtitle: 'Iconic Marvel Spider-Man crimson & gold',
            type: RetroThemeType.spiderMan,
            currentType: themeProvider.currentTheme,
            onTap: () => themeProvider.setTheme(RetroThemeType.spiderMan),
          ),

          const SizedBox(height: 24),
          Text('VISUAL EFFECTS', style: TextStyle(color: AppTheme.white38, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
          const SizedBox(height: 12),

          Container(
            decoration: BoxDecoration(
              color: AppTheme.cardBackground.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white12),
            ),
            child: SwitchListTile(
              activeColor: AppTheme.primaryAccent,
              title: Text('Vinyl & Cover Animations', style: TextStyle(color: AppTheme.white, fontWeight: FontWeight.w600, fontSize: 15)),
              subtitle: Text('Enable smooth spinning vinyl record animations in player', style: TextStyle(color: AppTheme.white38, fontSize: 12)),
              value: _animations,
              onChanged: (val) {
                setState(() => _animations = val);
                _savePreference('pref_animations', val);
              },
            ),
          ),

          const SizedBox(height: 10),

          Container(
            decoration: BoxDecoration(
              color: AppTheme.cardBackground.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white12),
            ),
            child: SwitchListTile(
              activeColor: AppTheme.primaryAccent,
              title: Text('Reduce Motion', style: TextStyle(color: AppTheme.white, fontWeight: FontWeight.w600, fontSize: 15)),
              subtitle: Text('Minimize non-essential screen transition animations', style: TextStyle(color: AppTheme.white38, fontSize: 12)),
              value: _reduceMotion,
              onChanged: (val) {
                setState(() => _reduceMotion = val);
                _savePreference('pref_reduce_motion', val);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeCard({
    required String title,
    required String subtitle,
    required RetroThemeType type,
    required RetroThemeType currentType,
    required VoidCallback onTap,
  }) {
    final isSelected = type == currentType;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSelected ? AppTheme.primaryAccent : Colors.white12,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: ListTile(
        leading: Icon(
          type == RetroThemeType.spiderMan ? Icons.local_fire_department : Icons.palette_outlined,
          color: isSelected ? AppTheme.primaryAccent : AppTheme.white38,
          size: 28,
        ),
        title: Text(title, style: TextStyle(color: AppTheme.white, fontWeight: FontWeight.w600, fontSize: 15)),
        subtitle: Text(subtitle, style: TextStyle(color: AppTheme.white38, fontSize: 12)),
        trailing: isSelected
            ? Icon(Icons.check_circle, color: AppTheme.primaryAccent, size: 22)
            : const Icon(Icons.radio_button_unchecked, color: Colors.white24, size: 22),
        onTap: onTap,
      ),
    );
  }
}

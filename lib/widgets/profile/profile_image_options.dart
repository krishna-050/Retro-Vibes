import 'package:flutter/material.dart';
import 'package:retro_vibes/theme/app_theme.dart';

class ProfileImageOptions extends StatelessWidget {
  final VoidCallback onCameraTap;
  final VoidCallback onGalleryTap;
  final VoidCallback onAvatarTap;
  final VoidCallback onRemoveTap;
  final bool hasCustomImage;

  const ProfileImageOptions({
    super.key,
    required this.onCameraTap,
    required this.onGalleryTap,
    required this.onAvatarTap,
    required this.onRemoveTap,
    this.hasCustomImage = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Choose Profile Picture',
            style: TextStyle(
              color: AppTheme.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildOption(
            icon: Icons.camera_alt,
            title: 'Camera',
            onTap: onCameraTap,
          ),
          _buildOption(
            icon: Icons.photo_library,
            title: 'Gallery',
            onTap: onGalleryTap,
          ),
          _buildOption(
            icon: Icons.face,
            title: 'Choose Avatar',
            onTap: onAvatarTap,
          ),
          if (hasCustomImage) ...[
            const Divider(color: Colors.white12),
            _buildOption(
              icon: Icons.delete_outline,
              title: 'Remove Profile Picture',
              color: Colors.redAccent,
              onTap: onRemoveTap,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color color = Colors.white,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: color == Colors.white ? AppTheme.primaryAccent : color),
      title: Text(
        title,
        style: TextStyle(color: color),
      ),
      onTap: onTap,
    );
  }
}

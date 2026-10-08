import 'package:flutter/material.dart';
import 'package:retro_vibes/model/user_model.dart';
import 'package:retro_vibes/theme/app_theme.dart';

class ProfileAvatar extends StatelessWidget {
  final UserModel? user;
  final double radius;
  final double borderWidth;

  const ProfileAvatar({
    super.key,
    required this.user,
    this.radius = 40.0,
    this.borderWidth = 3.0,
  });

  @override
  Widget build(BuildContext context) {
    ImageProvider imageProvider;

    if (user != null) {
      if (user!.profileImageType == 'default' && user!.profileAvatarId != null) {
        imageProvider = AssetImage('assets/avatars/${user!.profileAvatarId}.png');
      } else if (user!.profileImageType == 'custom' && user!.photoUrl.isNotEmpty) {
        imageProvider = NetworkImage(user!.photoUrl);
      } else if (user!.photoUrl.isNotEmpty) {
        // Fallback for older documents that have photoUrl but no profileImageType
        imageProvider = NetworkImage(user!.photoUrl);
      } else {
        imageProvider = const AssetImage('assets/images/eagle.webp');
      }
    } else {
      imageProvider = const AssetImage('assets/images/eagle.webp');
    }

    return Container(
      padding: EdgeInsets.all(borderWidth),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: AppTheme.primaryAccent,
          width: borderWidth,
        ),
      ),
      child: CircleAvatar(
        radius: radius,
        backgroundColor: AppTheme.cardBackground,
        backgroundImage: imageProvider,
        onBackgroundImageError: (exception, stackTrace) {
          // Can handle error, but it defaults to transparent if not caught, 
          // although we could show an icon if needed.
        },
      ),
    );
  }
}

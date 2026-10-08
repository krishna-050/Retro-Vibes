import 'package:flutter/material.dart';
import 'package:retro_vibes/theme/app_theme.dart';

class AvatarPicker extends StatefulWidget {
  final String? currentAvatarId;
  final ValueChanged<String> onAvatarSelected;

  const AvatarPicker({
    super.key,
    this.currentAvatarId,
    required this.onAvatarSelected,
  });

  @override
  State<AvatarPicker> createState() => _AvatarPickerState();
}

class _AvatarPickerState extends State<AvatarPicker> {
  // Assuming 12 default avatars
  final List<String> _avatars = List.generate(12, (index) {
    final num = (index + 1).toString().padLeft(2, '0');
    return 'avatar_$num';
  });

  String? _selectedAvatarId;

  @override
  void initState() {
    super.initState();
    _selectedAvatarId = widget.currentAvatarId;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.scaffoldBackground,
        elevation: 0,
        title: const Text('Choose Your Avatar', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          TextButton(
            onPressed: _selectedAvatarId != null
                ? () {
                    widget.onAvatarSelected(_selectedAvatarId!);
                    Navigator.of(context).pop();
                  }
                : null,
            child: Text(
              'Done',
              style: TextStyle(
                color: _selectedAvatarId != null ? AppTheme.primaryAccent : Colors.grey,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: _avatars.length,
          itemBuilder: (context, index) {
            final avatarId = _avatars[index];
            final isSelected = _selectedAvatarId == avatarId;

            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedAvatarId = avatarId;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? AppTheme.primaryAccent : Colors.transparent,
                    width: isSelected ? 4 : 0,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppTheme.primaryAccent.withValues(alpha: 0.5),
                            blurRadius: 8,
                            spreadRadius: 2,
                          )
                        ]
                      : [],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: CircleAvatar(
                    backgroundColor: AppTheme.cardBackground,
                    backgroundImage: AssetImage('assets/avatars/$avatarId.png'),
                    onBackgroundImageError: (exception, stackTrace) {
                      // Silently ignore if image is missing.
                    },
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

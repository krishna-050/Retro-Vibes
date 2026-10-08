import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:retro_vibes/provider/auth_provider.dart';
import 'package:retro_vibes/services/storage_service.dart';
import 'package:retro_vibes/theme/app_theme.dart';
import 'package:retro_vibes/widgets/profile/avatar_picker.dart';
import 'package:retro_vibes/widgets/profile/profile_avatar.dart';
import 'package:retro_vibes/widgets/profile/profile_image_options.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _bioController;
  bool _isSaving = false;
  bool _isUploadingImage = false;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().currentUser;
    _nameController = TextEditingController(text: user?.name ?? '');
    _bioController = TextEditingController(text: 'Retro music lover & vinyl collector 🎵');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _showProfileImageOptions(AuthProvider authProvider) async {
    final user = authProvider.currentUser;
    if (user == null) return;

    final hasCustomImage = user.profileImageType == 'custom' || 
        (user.profileImageType == null && user.photoUrl.isNotEmpty);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return ProfileImageOptions(
          hasCustomImage: hasCustomImage,
          onCameraTap: () {
            Navigator.pop(ctx);
            _pickAndUploadImage(authProvider, ImageSource.camera);
          },
          onGalleryTap: () {
            Navigator.pop(ctx);
            _pickAndUploadImage(authProvider, ImageSource.gallery);
          },
          onAvatarTap: () {
            Navigator.pop(ctx);
            _navigateToAvatarPicker(authProvider);
          },
          onRemoveTap: () {
            Navigator.pop(ctx);
            _confirmRemoveProfilePicture(authProvider);
          },
        );
      },
    );
  }

  void _navigateToAvatarPicker(AuthProvider authProvider) {
    final user = authProvider.currentUser;
    if (user == null) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AvatarPicker(
          currentAvatarId: user.profileImageType == 'default' ? user.profileAvatarId : null,
          onAvatarSelected: (avatarId) async {
            setState(() {
              _isUploadingImage = true;
            });

            try {
              if (user.profileImageType == 'custom' && user.photoUrl.isNotEmpty) {
                await StorageService().deleteProfileImage(user.uid);
              }

              await authProvider.updateProfileImageInfo(
                uid: user.uid,
                photoUrl: '',
                profileImageType: 'default',
                profileAvatarId: avatarId,
              );

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Avatar updated successfully')),
                );
              }
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to update avatar: $e'), backgroundColor: Colors.red),
                );
              }
            } finally {
              if (mounted) {
                setState(() {
                  _isUploadingImage = false;
                });
              }
            }
          },
        ),
      ),
    );
  }

  void _confirmRemoveProfilePicture(AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        title: Text('Remove Profile Picture?', style: TextStyle(color: AppTheme.white)),
        content: Text(
          'Are you sure you want to remove your profile picture?',
          style: TextStyle(color: AppTheme.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: AppTheme.white38)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() {
                _isUploadingImage = true;
              });

              try {
                final user = authProvider.currentUser!;
                if (user.profileImageType == 'custom' && user.photoUrl.isNotEmpty) {
                  await StorageService().deleteProfileImage(user.uid);
                }

                await authProvider.updateProfileImageInfo(
                  uid: user.uid,
                  photoUrl: '',
                  profileImageType: null,
                  profileAvatarId: null,
                );

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Profile picture removed')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                  );
                }
              } finally {
                if (mounted) {
                  setState(() {
                    _isUploadingImage = false;
                  });
                }
              }
            },
            child: const Text('Remove', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAndUploadImage(AuthProvider authProvider, ImageSource source) async {
    final user = authProvider.currentUser;
    if (user == null) return;

    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        imageQuality: 70,
        maxWidth: 800,
      );

      if (pickedFile != null) {
        setState(() {
          _isUploadingImage = true;
        });

        final storageService = StorageService();
        String photoUrl = '';
        
        if (kIsWeb) {
          final bytes = await pickedFile.readAsBytes();
          photoUrl = await storageService.uploadProfileImage(
            uid: user.uid,
            bytes: bytes,
          );
        } else {
          photoUrl = await storageService.uploadProfileImage(
            uid: user.uid,
            file: File(pickedFile.path),
          );
        }

        if (photoUrl.isNotEmpty) {
          await authProvider.updateProfileImageInfo(
            uid: user.uid,
            photoUrl: photoUrl,
            profileImageType: 'custom',
            profileAvatarId: null,
          );
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Profile image updated successfully')),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update image: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingImage = false;
        });
      }
    }
  }

  Future<void> _handleSave() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Display name cannot be empty')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final messenger = ScaffoldMessenger.of(context);
    final authProvider = context.read<AuthProvider>();

    try {
      await authProvider.updateProfileName(name);
      if (mounted) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text('Error updating profile: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    double mediaWidth = MediaQuery.of(context).size.width;
    final authProvider = context.watch<AuthProvider>();
    final currentUser = authProvider.currentUser;

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.scaffoldBackground,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: AppTheme.white, size: mediaWidth * 0.055),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Edit Profile', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar Header
            Center(
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _isUploadingImage ? null : () => _showProfileImageOptions(authProvider),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        ProfileAvatar(
                          user: currentUser,
                          radius: mediaWidth * 0.16,
                          borderWidth: 3,
                        ),
                        if (_isUploadingImage)
                          Container(
                            width: mediaWidth * 0.32,
                            height: mediaWidth * 0.32,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.black.withValues(alpha: 0.5),
                            ),
                            child: Center(
                              child: CircularProgressIndicator(color: AppTheme.primaryAccent),
                            ),
                          )
                        else
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryAccent,
                                shape: BoxShape.circle,
                                border: Border.all(color: AppTheme.scaffoldBackground, width: 2),
                              ),
                              child: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _isUploadingImage ? null : () => _showProfileImageOptions(authProvider),
                    child: Text(
                      'Change Photo',
                      style: TextStyle(
                        color: AppTheme.primaryAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Display Name Input
            Text(
              'Display Name',
              style: TextStyle(color: AppTheme.white70, fontSize: 13, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: AppTheme.cardBackground.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white12),
              ),
              child: TextField(
                controller: _nameController,
                style: TextStyle(color: AppTheme.white),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  prefixIcon: Icon(Icons.person_outline, color: AppTheme.primaryAccent),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Bio Input
            Text(
              'Bio',
              style: TextStyle(color: AppTheme.white70, fontSize: 13, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: AppTheme.cardBackground.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white12),
              ),
              child: TextField(
                controller: _bioController,
                maxLines: 3,
                style: TextStyle(color: AppTheme.white),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                  hintText: 'Tell the community about your retro taste...',
                  hintStyle: TextStyle(color: AppTheme.white38),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Email Field (Read-only)
            Text(
              'Email Address',
              style: TextStyle(color: AppTheme.white70, fontSize: 13, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white12),
              ),
              child: ListTile(
                leading: Icon(Icons.email_outlined, color: AppTheme.white38),
                title: Text(
                  currentUser?.email.isNotEmpty == true ? currentUser!.email : 'No email associated',
                  style: TextStyle(color: AppTheme.white70),
                ),
                subtitle: const Text('Email changes require account re-authentication', style: TextStyle(color: Colors.white30, fontSize: 11)),
              ),
            ),

            const SizedBox(height: 32),

            // Save Changes Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 4,
                ),
                onPressed: _isSaving ? null : _handleSave,
                child: _isSaving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        'Save Changes',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

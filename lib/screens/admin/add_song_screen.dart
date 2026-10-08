import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:retro_vibes/model/song.dart';
import 'package:retro_vibes/provider/song_provider.dart';
import 'package:retro_vibes/services/audio_metadata_reader.dart';
import 'package:retro_vibes/services/storage_service.dart';
import 'package:retro_vibes/theme/app_theme.dart';

class AddSongScreen extends StatefulWidget {
  const AddSongScreen({super.key});

  @override
  State<AddSongScreen> createState() => _AddSongScreenState();
}

class _AddSongScreenState extends State<AddSongScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _artistController = TextEditingController();
  final TextEditingController _albumController = TextEditingController();
  final TextEditingController _releaseYearController = TextEditingController(text: '2024');
  final TextEditingController _durationController = TextEditingController();
  final TextEditingController _coverUrlController = TextEditingController(text: 'assets/images/80s_hit.png');
  final TextEditingController _audioUrlController = TextEditingController(text: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3');

  String _selectedGenre = 'Retro';
  String _selectedCategoryCard = 'None';

  bool _isFeatured = false;
  bool _isPublished = true;
  bool _isRetroRadio = false;

  File? _audioFile;
  Uint8List? _audioBytes;
  String? _audioFileName;

  Uint8List? _coverBytes;
  bool _hasEmbeddedArtwork = false;

  bool _isReadingMetadata = false;
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  String _uploadStatusText = '';

  static const List<String> availableGenres = [
    'Retro',
    'Pop',
    'Rock',
    'Bollywood',
    'Romantic',
    'Sad',
    'Party',
    'Workout',
    'Lo-Fi',
    'Classical',
    'Jazz',
    'Hip-Hop',
    'Devotional',
    'Indie',
    'Other',
  ];

  static const List<String> browseCategories = [
    'None',
    'Retro Playlist',
    '80s Albums',
    'Classic Artists',
    'Retro Podcasts',
    'Nostalgia Genres',
    'Top Charts',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _artistController.dispose();
    _albumController.dispose();
    _releaseYearController.dispose();
    _durationController.dispose();
    _coverUrlController.dispose();
    _audioUrlController.dispose();
    super.dispose();
  }

  Future<void> _pickAudioFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp3', 'wav', 'm4a', 'aac'],
    );

    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      Uint8List? bytes;
      String? filePath;

      if (kIsWeb) {
        bytes = file.bytes;
      } else if (file.path != null) {
        filePath = file.path;
        bytes = await File(filePath!).readAsBytes();
      }

      setState(() {
        _audioFileName = file.name;
        if (kIsWeb) {
          _audioBytes = file.bytes;
        } else if (filePath != null) {
          _audioFile = File(filePath);
        }
        _isReadingMetadata = true;
      });

      // Automatically read available audio metadata
      try {
        final metadata = await AudioMetadataReader.readMetadata(
          bytes: bytes,
          filePath: filePath,
          fileName: file.name,
        );

        setState(() {
          // Auto populate Title if available
          if (metadata.title != null && metadata.title!.trim().isNotEmpty) {
            _titleController.text = metadata.title!.trim();
          }

          // Auto populate Artist if available; if not available, leave editable/empty
          if (metadata.artist != null && metadata.artist!.trim().isNotEmpty) {
            _artistController.text = metadata.artist!.trim();
          } else if (_artistController.text.trim().isEmpty) {
            _artistController.text = ''; // Leave editable/empty instead of inventing
          }

          // Auto populate Album if available
          if (metadata.album != null && metadata.album!.trim().isNotEmpty) {
            _albumController.text = metadata.album!.trim();
          }

          // Auto populate Year if available
          if (metadata.year != null && metadata.year!.trim().isNotEmpty) {
            _releaseYearController.text = metadata.year!.trim();
          }

          // Auto populate Genre if available in our list
          if (metadata.genre != null && metadata.genre!.trim().isNotEmpty) {
            final match = availableGenres.firstWhere(
              (g) => g.toLowerCase() == metadata.genre!.trim().toLowerCase(),
              orElse: () => '',
            );
            if (match.isNotEmpty) {
              _selectedGenre = match;
            }
          }

          // Automatically detect duration
          if (metadata.duration != null && metadata.duration!.trim().isNotEmpty) {
            _durationController.text = metadata.duration!.trim();
          } else if (_durationController.text.isEmpty) {
            _durationController.text = '3:30';
          }

          // Embedded cover artwork handling from MP3
          if (metadata.artworkBytes != null && metadata.artworkBytes!.isNotEmpty) {
            _coverBytes = metadata.artworkBytes;
            _hasEmbeddedArtwork = true;
          }
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Audio metadata auto-detected successfully!'),
              backgroundColor: Color(0xFFC85A32),
              duration: Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        debugPrint('Metadata extraction note: $e');
      } finally {
        if (mounted) {
          setState(() {
            _isReadingMetadata = false;
          });
        }
      }
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.2;
      _uploadStatusText = 'Processing track metadata & uploads...';
    });

    try {
      final songId = 'song_${DateTime.now().millisecondsSinceEpoch}';
      String coverUrl = _coverUrlController.text.trim();
      String audioUrl = _audioUrlController.text.trim();

      // 1. Upload Cover Artwork if embedded bytes extracted
      if (_coverBytes != null && _coverBytes!.isNotEmpty) {
        setState(() {
          _uploadProgress = 0.4;
          _uploadStatusText = 'Uploading artwork image to storage...';
        });

        try {
          final storageService = StorageService();
          final uploadedCover = await storageService
              .uploadCover(
                songId: songId,
                bytes: _coverBytes,
              )
              .timeout(const Duration(seconds: 5));

          if (uploadedCover.isNotEmpty) {
            coverUrl = uploadedCover;
          }
        } catch (e) {
          debugPrint('Storage cover upload note/timeout: $e');
          final mime = _hasEmbeddedArtwork ? 'image/jpeg' : 'image/png';
          coverUrl = 'data:$mime;base64,${base64Encode(_coverBytes!)}';
        }
      }

      // 2. Upload MP3 Audio file if provided
      if (_audioFile != null || _audioBytes != null) {
        setState(() {
          _uploadProgress = 0.6;
          _uploadStatusText = 'Uploading audio file to storage...';
        });

        try {
          final storageService = StorageService();
          final uploadedAudio = await storageService
              .uploadAudio(
                songId: songId,
                file: _audioFile,
                bytes: _audioBytes,
                onProgress: (p) {
                  if (mounted) {
                    setState(() {
                      _uploadProgress = 0.6 + (p * 0.25);
                    });
                  }
                },
              )
              .timeout(const Duration(seconds: 8));

          if (uploadedAudio.isNotEmpty) {
            audioUrl = uploadedAudio;
          }
        } catch (e) {
          debugPrint('Storage audio upload note/timeout: $e');
        }
      }

      if (coverUrl.isEmpty) {
        coverUrl = 'assets/images/70s.png';
      }
      if (audioUrl.isEmpty) {
        audioUrl = 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3';
      }

      String dur = _durationController.text.trim();
      if (dur.isEmpty) {
        dur = '3:30';
      }

      // Resolve final album name (use category card name if selected)
      String finalAlbum = _albumController.text.trim();
      if (_selectedCategoryCard != 'None') {
        finalAlbum = _selectedCategoryCard;
      } else if (finalAlbum.isEmpty) {
        finalAlbum = 'Single';
      }

      setState(() {
        _uploadProgress = 0.9;
        _uploadStatusText = 'Publishing live to Cloud Firestore...';
      });

      final song = Song(
        songId: songId,
        title: _titleController.text.trim(),
        artist: _artistController.text.trim(),
        album: finalAlbum,
        genre: _selectedGenre,
        releaseYear: _releaseYearController.text.trim().isEmpty ? '2024' : _releaseYearController.text.trim(),
        duration: dur,
        coverUrl: coverUrl,
        audioUrl: audioUrl,
        isPublished: _isPublished,
        isFeatured: _isFeatured,
        isRetroRadio: _isRetroRadio,
        createdAt: DateTime.now(),
      );

      // Save instantly to Cloud Firestore
      if (mounted) {
        await context.read<SongProvider>().addSong(song);
      }

      setState(() {
        _uploadProgress = 1.0;
        _uploadStatusText = 'Song published instantly!';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Song "${song.title}" published live to catalog!'),
            backgroundColor: const Color(0xFF4CAF50),
          ),
        );

        // Reset form
        _titleController.clear();
        _artistController.clear();
        _albumController.clear();
        _releaseYearController.text = '2024';
        _durationController.clear();
        setState(() {
          _selectedGenre = 'Retro';
          _selectedCategoryCard = 'None';
          _audioFile = null;
          _audioBytes = null;
          _audioFileName = null;
          _coverBytes = null;
          _hasEmbeddedArtwork = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Publish error: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.cardBackground,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: AppTheme.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Image.asset(
              'assets/icons/retro_vibes_icon.png',
              width: 26,
              height: 26,
              errorBuilder: (c, e, s) => Icon(Icons.music_note, color: AppTheme.primaryAccent, size: 24),
            ),
            const SizedBox(width: 10),
            Text(
              'UPLOAD TRACK / ADD SONG',
              style: TextStyle(
                color: AppTheme.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primaryAccent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.primaryAccent.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.auto_awesome, color: AppTheme.primaryAccent, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Smart Metadata & Duration Reader',
                            style: TextStyle(color: AppTheme.white, fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Selecting an MP3 file automatically reads the Title, Artist, Album, Duration, and Embedded Artwork.',
                            style: TextStyle(color: AppTheme.white70, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Audio File Selector
              _buildSectionTitle('AUDIO TRACK FILE'),
              const SizedBox(height: 12),

              _buildFilePickerTile(
                title: _audioFileName ?? 'Select Audio File (.mp3, .wav, .m4a)',
                subtitle: _audioFileName != null
                    ? (_isReadingMetadata ? 'Extracting ID3 tags & detecting duration...' : 'Audio attached • Auto-populated below')
                    : 'Click to select audio file from your device',
                icon: Icons.audio_file,
                isPicked: _audioFileName != null,
                isLoading: _isReadingMetadata,
                onTap: _pickAudioFile,
              ),

              const SizedBox(height: 24),
              _buildSectionTitle('SONG METADATA & CATEGORY'),
              const SizedBox(height: 12),

              // Title
              _buildTextField(_titleController, 'Song Title *', Icons.music_note, required: true),
              const SizedBox(height: 12),

              // Artist
              _buildTextField(_artistController, 'Artist Name *', Icons.person, required: true),
              const SizedBox(height: 12),

              // Browse Category Card Selector
              _buildCategoryCardDropdown(),
              const SizedBox(height: 12),

              // Album Name
              _buildTextField(_albumController, 'Album Name / Collection', Icons.album),
              const SizedBox(height: 12),

              // Genre & Year Row
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: _buildGenreDropdown(),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: _buildTextField(_releaseYearController, 'Year', Icons.calendar_today),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Auto-detected Duration
              _buildTextField(_durationController, 'Duration (Auto-detected)', Icons.access_time),

              const SizedBox(height: 24),
              _buildSectionTitle('COVER ARTWORK & STREAMING LINKS'),
              const SizedBox(height: 12),

              // Show Embedded Cover Artwork Status Tile if extracted
              if (_hasEmbeddedArtwork && _coverBytes != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.cardBackground,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.primaryAccent, width: 1.5),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.memory(_coverBytes!, width: 44, height: 44, fit: BoxFit.cover),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Embedded MP3 Cover Art Extracted', style: TextStyle(color: AppTheme.white, fontSize: 13, fontWeight: FontWeight.bold)),
                            Text('This artwork will be published with the song.', style: TextStyle(color: AppTheme.white38, fontSize: 11)),
                          ],
                        ),
                      ),
                      Icon(Icons.check_circle, color: const Color(0xFF4CAF50), size: 20),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              _buildTextField(_coverUrlController, 'Artwork Image URL / Path', Icons.image_outlined),
              const SizedBox(height: 12),
              _buildTextField(_audioUrlController, 'Audio Stream Direct URL', Icons.link, required: true),

              const SizedBox(height: 24),
              _buildSectionTitle('PUBLISHING OPTIONS'),
              const SizedBox(height: 12),

              Container(
                decoration: BoxDecoration(
                  color: AppTheme.cardBackground,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white12),
                ),
                child: Column(
                  children: [
                    SwitchListTile(
                      activeThumbColor: AppTheme.primaryAccent,
                      title: Text('Publish immediately', style: TextStyle(color: AppTheme.white, fontSize: 14)),
                      subtitle: Text('Visible to users in search & catalog', style: TextStyle(color: AppTheme.white38, fontSize: 12)),
                      value: _isPublished,
                      onChanged: (val) => setState(() => _isPublished = val),
                    ),
                    const Divider(color: Colors.white12, height: 1),
                    SwitchListTile(
                      activeThumbColor: const Color(0xFFFFD700),
                      title: Text('Mark as Featured Song', style: TextStyle(color: AppTheme.white, fontSize: 14)),
                      subtitle: Text('Showcases in top home banner', style: TextStyle(color: AppTheme.white38, fontSize: 12)),
                      value: _isFeatured,
                      onChanged: (val) => setState(() => _isFeatured = val),
                    ),
                    const Divider(color: Colors.white12, height: 1),
                    SwitchListTile(
                      activeThumbColor: AppTheme.deepOrangeAccent,
                      title: Text('Add to Retro Radio', style: TextStyle(color: AppTheme.white, fontSize: 14, fontWeight: FontWeight.bold)),
                      subtitle: Text('Include in continuous random play radio', style: TextStyle(color: AppTheme.white38, fontSize: 12)),
                      value: _isRetroRadio,
                      onChanged: (val) => setState(() => _isRetroRadio = val),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // Upload Progress Bar
              if (_isUploading) ...[
                LinearProgressIndicator(
                  value: _uploadProgress,
                  backgroundColor: AppTheme.cardBackground,
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryAccent),
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    '$_uploadStatusText (${(_uploadProgress * 100).toInt()}%)',
                    style: TextStyle(color: AppTheme.white70, fontSize: 12),
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryAccent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 4,
                  ),
                  onPressed: _isUploading ? null : _handleSubmit,
                  child: _isUploading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.cloud_upload, color: Colors.white, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'UPLOAD & PUBLISH SONG',
                              style: TextStyle(
                                color: AppTheme.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        color: AppTheme.primaryAccent,
        fontSize: 11,
        fontWeight: FontWeight.bold,
        letterSpacing: 2,
      ),
    );
  }

  Widget _buildCategoryCardDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButtonFormField<String>(
          initialValue: _selectedCategoryCard,
          dropdownColor: AppTheme.cardBackground,
          style: TextStyle(color: AppTheme.white, fontSize: 14),
          decoration: InputDecoration(
            border: InputBorder.none,
            labelText: 'Assign to Browse Category Card (Optional)',
            labelStyle: TextStyle(color: AppTheme.white38, fontSize: 12),
            prefixIcon: Icon(Icons.grid_view, color: AppTheme.primaryAccent, size: 20),
            contentPadding: EdgeInsets.zero,
          ),
          items: browseCategories.map((category) {
            return DropdownMenuItem<String>(
              value: category,
              child: Text(
                category == 'None' ? 'None (General Catalog)' : category,
                style: TextStyle(color: category == 'None' ? AppTheme.white38 : AppTheme.white),
              ),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) {
              setState(() {
                _selectedCategoryCard = val;
                if (val != 'None' && _albumController.text.trim().isEmpty) {
                  _albumController.text = val;
                }
              });
            }
          },
        ),
      ),
    );
  }

  Widget _buildGenreDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButtonFormField<String>(
          initialValue: _selectedGenre,
          dropdownColor: AppTheme.cardBackground,
          style: TextStyle(color: AppTheme.white, fontSize: 14),
          decoration: InputDecoration(
            border: InputBorder.none,
            labelText: 'Genre',
            labelStyle: TextStyle(color: AppTheme.white38, fontSize: 12),
            prefixIcon: Icon(Icons.category, color: AppTheme.primaryAccent, size: 20),
            contentPadding: EdgeInsets.zero,
          ),
          items: availableGenres.map((genre) {
            return DropdownMenuItem<String>(
              value: genre,
              child: Text(genre, style: TextStyle(color: AppTheme.white)),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) {
              setState(() {
                _selectedGenre = val;
              });
            }
          },
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool required = false,
  }) {
    return TextFormField(
      controller: controller,
      style: TextStyle(color: AppTheme.white, fontSize: 14),
      validator: required
          ? (val) => (val == null || val.trim().isEmpty) ? 'This field is required' : null
          : null,
      decoration: InputDecoration(
        filled: true,
        fillColor: AppTheme.cardBackground,
        labelText: label,
        labelStyle: TextStyle(color: AppTheme.white38, fontSize: 13),
        prefixIcon: Icon(icon, color: AppTheme.primaryAccent, size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.white12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppTheme.primaryAccent, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildFilePickerTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isPicked,
    bool isLoading = false,
    Uint8List? imagePreviewBytes,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isPicked ? AppTheme.primaryAccent : Colors.white12,
          width: isPicked ? 1.5 : 1,
        ),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: imagePreviewBytes != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.memory(imagePreviewBytes, width: 44, height: 44, fit: BoxFit.cover),
              )
            : Icon(
                icon,
                color: isPicked ? AppTheme.primaryAccent : AppTheme.white38,
                size: 26,
              ),
        title: Text(
          title,
          style: TextStyle(
            color: isPicked ? AppTheme.white : AppTheme.white70,
            fontSize: 14,
            fontWeight: isPicked ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Text(subtitle, style: TextStyle(color: AppTheme.white38, fontSize: 12)),
        trailing: isLoading
            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Color(0xFFC85A32), strokeWidth: 2))
            : Icon(
                isPicked ? Icons.check_circle : Icons.add_circle_outline,
                color: isPicked ? const Color(0xFF4CAF50) : AppTheme.white38,
              ),
      ),
    );
  }
}

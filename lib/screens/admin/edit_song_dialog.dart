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

class EditSongDialog extends StatefulWidget {
  final Song song;

  const EditSongDialog({super.key, required this.song});

  @override
  State<EditSongDialog> createState() => _EditSongDialogState();
}

class _EditSongDialogState extends State<EditSongDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleController;
  late TextEditingController _artistController;
  late TextEditingController _albumController;
  late TextEditingController _releaseYearController;
  late TextEditingController _durationController;
  late TextEditingController _coverUrlController;
  late TextEditingController _audioUrlController;

  late String _selectedGenre;
  late String _selectedCategoryCard;

  late bool _isPublished;
  late bool _isFeatured;
  late bool _isRetroRadio;

  File? _newAudioFile;
  Uint8List? _newAudioBytes;
  String? _newAudioFileName;

  bool _isSaving = false;
  double _saveProgress = 0.0;
  String _saveStatusText = '';

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
  void initState() {
    super.initState();
    final song = widget.song;

    _titleController = TextEditingController(text: song.title);
    _artistController = TextEditingController(text: song.artist);
    _albumController = TextEditingController(text: song.album);
    _releaseYearController = TextEditingController(text: song.releaseYear);
    _durationController = TextEditingController(text: song.duration);
    _coverUrlController = TextEditingController(text: song.coverUrl);
    _audioUrlController = TextEditingController(text: song.audioUrl);

    // Ensure matching existing genre or default to 'Retro'
    if (availableGenres.contains(song.genre)) {
      _selectedGenre = song.genre;
    } else {
      _selectedGenre = 'Retro';
    }

    // Matching category card if album matches
    if (browseCategories.contains(song.album)) {
      _selectedCategoryCard = song.album;
    } else {
      _selectedCategoryCard = 'None';
    }

    _isPublished = song.isPublished;
    _isFeatured = song.isFeatured;
    _isRetroRadio = song.isRetroRadio;
  }

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

  Future<void> _pickNewAudioFile() async {
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
        _newAudioFileName = file.name;
        if (kIsWeb) {
          _newAudioBytes = file.bytes;
        } else if (filePath != null) {
          _newAudioFile = File(filePath);
        }
      });

      // Auto read duration from new audio file
      if (bytes != null) {
        final metadata = await AudioMetadataReader.readMetadata(
          bytes: bytes,
          filePath: filePath,
          fileName: file.name,
        );
        if (metadata.duration != null && metadata.duration!.isNotEmpty) {
          setState(() {
            _durationController.text = metadata.duration!;
          });
        }
      }
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _saveProgress = 0.2;
      _saveStatusText = 'Saving updated metadata...';
    });

    try {
      final songId = widget.song.songId;
      String coverUrl = _coverUrlController.text.trim();
      String audioUrl = _audioUrlController.text.trim();

      // Upload new audio track if attached
      if (_newAudioFile != null || _newAudioBytes != null) {
        setState(() {
          _saveStatusText = 'Uploading new audio file...';
          _saveProgress = 0.6;
        });
        try {
          final storageService = StorageService();
          final uploadedAudio = await storageService
              .uploadAudio(
                songId: songId,
                file: _newAudioFile,
                bytes: _newAudioBytes,
              )
              .timeout(const Duration(seconds: 8));
          if (uploadedAudio.isNotEmpty) {
            audioUrl = uploadedAudio;
          }
        } catch (e) {
          debugPrint('Audio storage upload note/timeout: $e');
        }
      }

      if (coverUrl.isEmpty) {
        coverUrl = widget.song.coverUrl;
      }
      if (audioUrl.isEmpty) {
        audioUrl = widget.song.audioUrl;
      }

      // Resolve album
      String finalAlbum = _albumController.text.trim();
      if (_selectedCategoryCard != 'None') {
        finalAlbum = _selectedCategoryCard;
      } else if (finalAlbum.isEmpty) {
        finalAlbum = 'Single';
      }

      setState(() {
        _saveProgress = 0.8;
        _saveStatusText = 'Updating Cloud Firestore song record...';
      });

      final updatedSong = Song(
        songId: songId,
        title: _titleController.text.trim(),
        artist: _artistController.text.trim(),
        album: finalAlbum,
        genre: _selectedGenre,
        releaseYear: _releaseYearController.text.trim(),
        duration: _durationController.text.trim(),
        coverUrl: coverUrl,
        audioUrl: audioUrl,
        isPublished: _isPublished,
        isFeatured: _isFeatured,
        isRetroRadio: _isRetroRadio,
        lyricsObject: widget.song.lyricsObject,
        playCount: widget.song.playCount,
        createdAt: widget.song.createdAt,
      );

      // Save updated record without duplicating
      if (mounted) {
        await context.read<SongProvider>().updateSong(updatedSong);
      }

      setState(() {
        _saveProgress = 1.0;
        _saveStatusText = 'Song updated successfully!';
      });

      if (mounted) {
        Navigator.pop(context, updatedSong);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Song "${updatedSong.title}" updated successfully!'),
            backgroundColor: const Color(0xFF4CAF50),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Update error: $e'), backgroundColor: Colors.redAccent),
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
    final mediaWidth = MediaQuery.of(context).size.width;
    final mediaHeight = MediaQuery.of(context).size.height;

    return Dialog(
      backgroundColor: AppTheme.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: AppTheme.primaryAccent.withValues(alpha: 0.4), width: 1.5),
      ),
      child: Container(
        width: (mediaWidth * 0.9).clamp(320.0, 650.0),
        height: (mediaHeight * 0.88).clamp(480.0, 750.0),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryAccent.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.edit, color: AppTheme.primaryAccent, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'EDIT SONG METADATA',
                            style: TextStyle(
                              color: AppTheme.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                          Text(
                            'ID: ${widget.song.songId}',
                            style: TextStyle(color: AppTheme.white38, fontSize: 11),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: AppTheme.white38),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              const Divider(color: Colors.white12, height: 1),
              const SizedBox(height: 16),

              // Scrollable Form Fields
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionLabel('TRACK METADATA & CATEGORY'),
                      const SizedBox(height: 12),

                      // Title
                      _buildTextField(_titleController, 'Song Title *', Icons.music_note, required: true),
                      const SizedBox(height: 12),

                      // Artist
                      _buildTextField(_artistController, 'Artist Name *', Icons.person, required: true),
                      const SizedBox(height: 12),

                      // Category Card Selector
                      _buildCategoryCardDropdown(),
                      const SizedBox(height: 12),

                      // Album
                      _buildTextField(_albumController, 'Album Name', Icons.album),
                      const SizedBox(height: 12),

                      // Genre Dropdown & Year Row
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

                      // Duration
                      _buildTextField(_durationController, 'Duration (e.g. 3:45)', Icons.access_time),

                      const SizedBox(height: 20),
                      _buildSectionLabel('AUDIO & ARTWORK LINKS / FILES'),
                      const SizedBox(height: 12),

                      // Cover URL/Path
                      _buildTextField(_coverUrlController, 'Cover Image URL or Path', Icons.image_outlined),
                      const SizedBox(height: 12),

                      // Audio URL
                      _buildTextField(_audioUrlController, 'Audio Stream URL *', Icons.link, required: true),
                      const SizedBox(height: 10),

                      // Audio Picker Tile
                      _buildFilePickerTile(
                        title: _newAudioFileName ?? 'Optionally Replace MP3 File',
                        subtitle: _newAudioFileName != null ? 'New MP3 file attached' : 'Keep existing audio file without re-uploading',
                        icon: Icons.audio_file,
                        isPicked: _newAudioFileName != null,
                        onTap: _pickNewAudioFile,
                      ),

                      const SizedBox(height: 20),
                      _buildSectionLabel('PUBLISHING & VISIBILITY OPTIONS'),
                      const SizedBox(height: 12),

                      Container(
                        decoration: BoxDecoration(
                          color: Colors.black26,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Column(
                          children: [
                            SwitchListTile(
                              activeThumbColor: const Color(0xFF4CAF50),
                              title: Text('Published / Visible to Users', style: TextStyle(color: AppTheme.white, fontSize: 13, fontWeight: FontWeight.bold)),
                              subtitle: Text('Track is live in catalog and mobile search', style: TextStyle(color: AppTheme.white38, fontSize: 11)),
                              value: _isPublished,
                              onChanged: (val) => setState(() => _isPublished = val),
                            ),
                            const Divider(color: Colors.white12, height: 1),
                            SwitchListTile(
                              activeThumbColor: const Color(0xFFFFD700),
                              title: Text('Mark as Featured Song', style: TextStyle(color: AppTheme.white, fontSize: 13, fontWeight: FontWeight.bold)),
                              subtitle: Text('Featured in top dashboard / home carousel', style: TextStyle(color: AppTheme.white38, fontSize: 11)),
                              value: _isFeatured,
                              onChanged: (val) => setState(() => _isFeatured = val),
                            ),
                            const Divider(color: Colors.white12, height: 1),
                            SwitchListTile(
                              activeThumbColor: AppTheme.deepOrangeAccent,
                              title: Text('Retro Radio Station', style: TextStyle(color: AppTheme.white, fontSize: 13, fontWeight: FontWeight.bold)),
                              subtitle: Text('Include in continuous retro radio stream', style: TextStyle(color: AppTheme.white38, fontSize: 11)),
                              value: _isRetroRadio,
                              onChanged: (val) => setState(() => _isRetroRadio = val),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Progress indicator when saving
              if (_isSaving) ...[
                LinearProgressIndicator(
                  value: _saveProgress,
                  backgroundColor: Colors.black26,
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryAccent),
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(3),
                ),
                const SizedBox(height: 6),
                Center(
                  child: Text(
                    _saveStatusText,
                    style: TextStyle(color: AppTheme.white70, fontSize: 11),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Action buttons footer
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isSaving ? null : () => Navigator.pop(context),
                    child: Text('Cancel', style: TextStyle(color: AppTheme.white38)),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryAccent,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _isSaving ? null : _handleSave,
                    icon: _isSaving
                        ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.check, color: Colors.white, size: 18),
                    label: Text(
                      _isSaving ? 'SAVING...' : 'SAVE CHANGES',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: TextStyle(color: AppTheme.primaryAccent, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5),
    );
  }

  Widget _buildCategoryCardDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black38,
        borderRadius: BorderRadius.circular(12),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black38,
        borderRadius: BorderRadius.circular(12),
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
        fillColor: Colors.black38,
        labelText: label,
        labelStyle: TextStyle(color: AppTheme.white38, fontSize: 12),
        prefixIcon: Icon(icon, color: AppTheme.primaryAccent, size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.primaryAccent, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }

  Widget _buildFilePickerTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isPicked,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isPicked ? AppTheme.primaryAccent : Colors.white12,
          width: isPicked ? 1.5 : 1,
        ),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        leading: Icon(
          icon,
          color: isPicked ? AppTheme.primaryAccent : AppTheme.white38,
          size: 22,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isPicked ? AppTheme.white : AppTheme.white70,
            fontSize: 13,
            fontWeight: isPicked ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Text(subtitle, style: TextStyle(color: AppTheme.white38, fontSize: 11)),
        trailing: Icon(
          isPicked ? Icons.check_circle : Icons.add_circle_outline,
          color: isPicked ? const Color(0xFF4CAF50) : AppTheme.white38,
          size: 20,
        ),
      ),
    );
  }
}

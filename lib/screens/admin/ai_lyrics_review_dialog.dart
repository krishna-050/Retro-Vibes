import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:retro_vibes/model/song.dart';
import 'package:retro_vibes/provider/music_provider.dart';
import 'package:retro_vibes/provider/song_provider.dart';
import 'package:retro_vibes/services/ai_lyrics_service.dart';
import 'package:retro_vibes/theme/app_theme.dart';

class AiLyricsReviewDialog extends StatefulWidget {
  final Song song;
  final LyricsData draftLyrics;

  const AiLyricsReviewDialog({
    super.key,
    required this.song,
    required this.draftLyrics,
  });

  @override
  State<AiLyricsReviewDialog> createState() => _AiLyricsReviewDialogState();
}

class _AiLyricsReviewDialogState extends State<AiLyricsReviewDialog> {
  late LyricsData _currentLyricsData;
  late List<TextEditingController> _segmentTextControllers;
  late List<TextEditingController> _segmentTimeControllers;
  late TextEditingController _plainTextController;

  bool _isRegenerating = false;
  String _statusText = 'Needs Review';

  @override
  void initState() {
    super.initState();
    _currentLyricsData = widget.draftLyrics;
    _statusText = _currentLyricsData.status.toUpperCase();
    _plainTextController = TextEditingController(text: _currentLyricsData.text);
    _initSegmentControllers();
  }

  void _initSegmentControllers() {
    _segmentTextControllers = _currentLyricsData.segments
        .map((s) => TextEditingController(text: s.text))
        .toList();
    _segmentTimeControllers = _currentLyricsData.segments
        .map((s) => TextEditingController(text: s.timeFormatted))
        .toList();
  }

  @override
  void dispose() {
    _plainTextController.dispose();
    for (var c in _segmentTextControllers) {
      c.dispose();
    }
    for (var c in _segmentTimeControllers) {
      c.dispose();
    }
    super.dispose();
  }

  int _parseTimestampMs(String timeStr) {
    try {
      final clean = timeStr.replaceAll('[', '').replaceAll(']', '').trim();
      final parts = clean.split(':');
      if (parts.length == 2) {
        final minutes = int.parse(parts[0]);
        final secParts = parts[1].split('.');
        final seconds = int.parse(secParts[0]);
        final ms = secParts.length > 1 ? int.parse(secParts[1].padRight(3, '0')) : 0;
        return (minutes * 60 * 1000) + (seconds * 1000) + ms;
      }
    } catch (_) {}
    return 0;
  }

  LyricsData _collectEditedLyricsData({required bool approved}) {
    if (_currentLyricsData.type == 'synced' && _segmentTextControllers.isNotEmpty) {
      final List<LyricSegment> updatedSegments = [];
      for (int i = 0; i < _segmentTextControllers.length; i++) {
        final text = _segmentTextControllers[i].text.trim();
        final timeStr = _segmentTimeControllers[i].text.trim();
        if (text.isNotEmpty) {
          final startMs = _parseTimestampMs(timeStr);
          final endMs = startMs + 6000;
          final confidence = i < _currentLyricsData.segments.length
              ? _currentLyricsData.segments[i].confidence
              : 0.95;

          updatedSegments.add(LyricSegment(
            startMs: startMs,
            endMs: endMs,
            text: text,
            confidence: confidence,
          ));
        }
      }

      final fullText = updatedSegments.map((s) => '${s.timeFormatted} ${s.text}').join('\n');

      return LyricsData(
        enabled: true,
        type: 'synced',
        status: approved ? 'approved' : 'needs_review',
        text: fullText,
        segments: updatedSegments,
        overallConfidence: _currentLyricsData.overallConfidence,
        generatedBy: _currentLyricsData.generatedBy,
        reviewedByAdmin: approved,
        generatedAt: _currentLyricsData.generatedAt ?? DateTime.now().toIso8601String(),
        approvedAt: approved ? DateTime.now().toIso8601String() : null,
      );
    } else {
      return LyricsData(
        enabled: true,
        type: 'plain',
        status: approved ? 'approved' : 'needs_review',
        text: _plainTextController.text.trim(),
        segments: [],
        overallConfidence: _currentLyricsData.overallConfidence,
        generatedBy: _currentLyricsData.generatedBy,
        reviewedByAdmin: approved,
        generatedAt: _currentLyricsData.generatedAt ?? DateTime.now().toIso8601String(),
        approvedAt: approved ? DateTime.now().toIso8601String() : null,
      );
    }
  }

  Future<void> _handleRegenerate() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        title: Text('Regenerate AI Lyrics?', style: TextStyle(color: AppTheme.white)),
        content: Text(
          'AI transcription consumes processing credits. Generate a new draft while keeping current version for comparison?',
          style: TextStyle(color: AppTheme.white70, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: TextStyle(color: AppTheme.white38)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.yellow300, foregroundColor: Colors.black),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Generate', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isRegenerating = true;
    });

    try {
      final newDraft = await AiLyricsService.instance.generateLyricsWithAi(
        songTitle: widget.song.title,
        artist: widget.song.artist,
        audioUrl: widget.song.audioUrl,
        generateSynced: _currentLyricsData.type == 'synced',
        userUid: 'admin',
      );

      setState(() {
        _currentLyricsData = newDraft;
        _plainTextController.text = newDraft.text;
        _initSegmentControllers();
        _isRegenerating = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('New AI Lyrics Draft generated! Verify before publishing.'),
            backgroundColor: AppTheme.yellow300,
          ),
        );
      }
    } catch (e) {
      setState(() => _isRegenerating = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Regeneration failed: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  Future<void> _handleApproveAndSave() async {
    final finalLyrics = _collectEditedLyricsData(approved: true);

    final updatedSong = Song(
      songId: widget.song.songId,
      title: widget.song.title,
      artist: widget.song.artist,
      album: widget.song.album,
      genre: widget.song.genre,
      releaseYear: widget.song.releaseYear,
      duration: widget.song.duration,
      coverUrl: widget.song.coverUrl,
      audioUrl: widget.song.audioUrl,
      isPublished: widget.song.isPublished,
      isFeatured: widget.song.isFeatured,
      isRetroRadio: widget.song.isRetroRadio,
      lyricsObject: finalLyrics,
      createdAt: widget.song.createdAt,
    );

    try {
      await context.read<SongProvider>().addSong(updatedSong);
      if (mounted) {
        Navigator.pop(context, finalLyrics);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Lyrics approved & published to Cloud Firestore!'),
            backgroundColor: const Color(0xFF4CAF50),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Firestore write error: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    double mediaWidth = MediaQuery.of(context).size.width;
    double mediaHeight = MediaQuery.of(context).size.height;

    final confidencePct = (_currentLyricsData.overallConfidence * 100).toInt();

    return Dialog(
      backgroundColor: AppTheme.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: AppTheme.yellow300.withValues(alpha: 0.4), width: 1.5),
      ),
      child: Container(
        width: (mediaWidth * 0.9).clamp(320.0, 680.0),
        height: (mediaHeight * 0.85).clamp(480.0, 750.0),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Info
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI LYRICS REVIEW',
                      style: TextStyle(
                        color: AppTheme.yellow300,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${widget.song.title} • ${widget.song.artist}',
                      style: TextStyle(color: AppTheme.white70, fontSize: 13),
                    ),
                  ],
                ),
                IconButton(
                  icon: Icon(Icons.close, color: AppTheme.white38),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Confidence & Status Badges Row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.yellow300.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.yellow300.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.auto_awesome, color: AppTheme.yellow300, size: 14),
                      const SizedBox(width: 6),
                      Text(
                        'AI Confidence: $confidencePct%',
                        style: TextStyle(color: AppTheme.yellow300, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _currentLyricsData.status == 'approved'
                        ? Colors.green.withValues(alpha: 0.2)
                        : Colors.orange.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _currentLyricsData.status == 'approved' ? Colors.green : Colors.orange,
                    ),
                  ),
                  child: Text(
                    _statusText,
                    style: TextStyle(
                      color: _currentLyricsData.status == 'approved' ? Colors.green : Colors.orange,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
            Text(
              'AI-generated draft — please verify audio before publishing.',
              style: TextStyle(color: AppTheme.white38, fontSize: 11, fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 12),
            const Divider(color: Colors.white12, height: 1),
            const SizedBox(height: 12),

            // Main Lyrics Editor
            Expanded(
              child: _isRegenerating
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: AppTheme.yellow300),
                          const SizedBox(height: 16),
                          Text('Generating AI Lyrics Draft...', style: TextStyle(color: AppTheme.white)),
                          const SizedBox(height: 4),
                          Text('Step 2/3 Transcribing Vocals', style: TextStyle(color: AppTheme.white38, fontSize: 12)),
                        ],
                      ),
                    )
                  : _currentLyricsData.type == 'synced'
                      ? Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 90,
                                    child: Text('TIMESTAMP', style: TextStyle(color: AppTheme.yellow300, fontSize: 11, fontWeight: FontWeight.bold)),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text('LYRIC LINE (EDITABLE)', style: TextStyle(color: AppTheme.yellow300, fontSize: 11, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: ListView.builder(
                                physics: const BouncingScrollPhysics(),
                                itemCount: _segmentTextControllers.length,
                                itemBuilder: (context, index) {
                                  final conf = index < _currentLyricsData.segments.length
                                      ? _currentLyricsData.segments[index].confidence
                                      : 0.95;
                                  final isUncertain = conf < 0.85;

                                  return Container(
                                    margin: const EdgeInsets.symmetric(vertical: 4),
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isUncertain
                                          ? Colors.orange.withValues(alpha: 0.1)
                                          : AppTheme.cardBackground,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: isUncertain ? Colors.orange.withValues(alpha: 0.4) : Colors.white12,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        SizedBox(
                                          width: 85,
                                          child: TextField(
                                            controller: _segmentTimeControllers[index],
                                            style: TextStyle(color: AppTheme.yellow300, fontSize: 12, fontFamily: 'monospace'),
                                            decoration: const InputDecoration(border: InputBorder.none),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: TextField(
                                            controller: _segmentTextControllers[index],
                                            style: TextStyle(color: AppTheme.white, fontSize: 13),
                                            decoration: const InputDecoration(border: InputBorder.none),
                                          ),
                                        ),
                                        if (isUncertain)
                                          Tooltip(
                                            message: 'Needs Verification',
                                            child: Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 16),
                                          ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        )
                      : TextField(
                          controller: _plainTextController,
                          maxLines: null,
                          expands: true,
                          style: TextStyle(color: AppTheme.white, fontSize: 13),
                          decoration: InputDecoration(
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white12)),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppTheme.yellow300)),
                          ),
                        ),
            ),

            const SizedBox(height: 12),

            // Audio Preview Control Row
            Consumer<MusicProvider>(
              builder: (context, musicProvider, child) {
                final isPlaying = musicProvider.isPlaying && musicProvider.currentSong?.audioUrl == widget.song.audioUrl;

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill, color: AppTheme.yellow300, size: 32),
                        onPressed: () {
                          if (isPlaying) {
                            musicProvider.togglePlayPause();
                          } else {
                            musicProvider.playSong(widget.song);
                          }
                        },
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('AUDIO PREVIEW', style: TextStyle(color: AppTheme.white70, fontSize: 11, fontWeight: FontWeight.bold)),
                            Text(
                              isPlaying ? 'Playing track preview...' : 'Tap play to verify audio sync',
                              style: TextStyle(color: AppTheme.white38, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 16),

            // Action Buttons Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.yellow300,
                    side: BorderSide(color: AppTheme.yellow300.withValues(alpha: 0.5)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: _isRegenerating ? null : _handleRegenerate,
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Regenerate'),
                ),
                Row(
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Cancel', style: TextStyle(color: AppTheme.white38)),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4CAF50),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: _handleApproveAndSave,
                      icon: const Icon(Icons.check_circle_outline, size: 18),
                      label: const Text('Approve & Save', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

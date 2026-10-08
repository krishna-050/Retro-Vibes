class LyricSegment {
  final int startMs;
  final int endMs;
  final String text;
  final double confidence;

  LyricSegment({
    required this.startMs,
    required this.endMs,
    required this.text,
    this.confidence = 0.95,
  });

  String get timeFormatted {
    final dur = Duration(milliseconds: startMs);
    final min = dur.inMinutes.remainder(60).toString().padLeft(2, '0');
    final sec = dur.inSeconds.remainder(60).toString().padLeft(2, '0');
    final ms = (dur.inMilliseconds.remainder(1000) ~/ 10).toString().padLeft(2, '0');
    return '[$min:$sec.$ms]';
  }

  Map<String, dynamic> toMap() => {
        'startMs': startMs,
        'endMs': endMs,
        'text': text,
        'confidence': confidence,
      };

  factory LyricSegment.fromMap(Map<String, dynamic> map) => LyricSegment(
        startMs: map['startMs'] is int ? map['startMs'] : 0,
        endMs: map['endMs'] is int ? map['endMs'] : 0,
        text: map['text']?.toString() ?? '',
        confidence: (map['confidence'] is num) ? (map['confidence'] as num).toDouble() : 0.95,
      );
}

class LyricsData {
  final bool enabled;
  final String type; // 'synced' | 'plain'
  final String status; // 'none' | 'processing' | 'draft' | 'needs_review' | 'approved' | 'failed'
  final String text;
  final List<LyricSegment> segments;
  final double overallConfidence;
  final String generatedBy;
  final bool reviewedByAdmin;
  final String? generatedAt;
  final String? approvedAt;

  LyricsData({
    this.enabled = true,
    this.type = 'synced',
    this.status = 'none',
    this.text = '',
    this.segments = const [],
    this.overallConfidence = 0.92,
    this.generatedBy = 'AI',
    this.reviewedByAdmin = false,
    this.generatedAt,
    this.approvedAt,
  });

  String toLrcString() {
    if (segments.isNotEmpty) {
      return segments.map((s) => '${s.timeFormatted} ${s.text}').join('\n');
    }
    if (text.isNotEmpty) return text;
    return Song.defaultSampleLyrics;
  }

  Map<String, dynamic> toMap() => {
        'enabled': enabled,
        'type': type,
        'status': status,
        'text': text,
        'segments': segments.map((s) => s.toMap()).toList(),
        'overallConfidence': overallConfidence,
        'generatedBy': generatedBy,
        'reviewedByAdmin': reviewedByAdmin,
        'generatedAt': generatedAt,
        'approvedAt': approvedAt,
      };

  factory LyricsData.fromMap(Map<String, dynamic> map) {
    final rawSegments = map['segments'];
    final List<LyricSegment> list = [];
    if (rawSegments is List) {
      for (final item in rawSegments) {
        if (item is Map) {
          list.add(LyricSegment.fromMap(Map<String, dynamic>.from(item)));
        }
      }
    }
    return LyricsData(
      enabled: map['enabled'] ?? true,
      type: map['type']?.toString() ?? 'synced',
      status: map['status']?.toString() ?? 'none',
      text: map['text']?.toString() ?? '',
      segments: list,
      overallConfidence: (map['overallConfidence'] is num) ? (map['overallConfidence'] as num).toDouble() : 0.92,
      generatedBy: map['generatedBy']?.toString() ?? 'AI',
      reviewedByAdmin: map['reviewedByAdmin'] ?? false,
      generatedAt: map['generatedAt']?.toString(),
      approvedAt: map['approvedAt']?.toString(),
    );
  }
}

class Song {
  final String songId;
  final String title;
  final String artist;
  final String artistId;
  final String album;
  final String albumId;
  final String genre;
  final String releaseYear;
  final String duration;
  final String coverUrl;
  final String audioUrl;
  final bool isPublished;
  final bool isFeatured;
  final bool isRetroRadio;
  final LyricsData? lyricsObject;
  final int playCount;
  final DateTime? createdAt;

  Song({
    required this.title,
    required this.artist,
    required this.duration,
    String? songId,
    String? artistId,
    String? album,
    String? albumId,
    String? genre,
    String? releaseYear,
    String? coverUrl,
    String? audioUrl,
    String? image,
    String? audio,
    String? lyrics,
    this.lyricsObject,
    this.isPublished = true,
    this.isFeatured = false,
    this.isRetroRadio = false,
    this.playCount = 0,
    this.createdAt,
  })  : songId = (songId != null && songId.isNotEmpty)
            ? songId
            : 'song_${DateTime.now().millisecondsSinceEpoch}_${title.replaceAll(' ', '_').toLowerCase()}',
        artistId = artistId ?? '',
        album = (album != null && album.isNotEmpty) ? album : 'Single',
        albumId = albumId ?? '',
        genre = (genre != null && genre.isNotEmpty) ? genre : 'Retro',
        releaseYear = (releaseYear != null && releaseYear.isNotEmpty) ? releaseYear : '2024',
        coverUrl = _resolveCoverUrl(coverUrl ?? image),
        audioUrl = _resolveAudioUrl(audioUrl ?? audio);

  static String _resolveCoverUrl(String? input) {
    if (input == null || input.trim().isEmpty) {
      return 'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=500';
    }
    return input.trim();
  }

  static String _resolveAudioUrl(String? input) {
    if (input == null || input.trim().isEmpty) {
      return 'assets/songs/jo_tum_mere_ho.mp3';
    }
    return input.trim();
  }

  // Backwards compatibility getters for existing UI
  String get image => coverUrl;
  String get audio => audioUrl;
  String get lyrics => lyricsObject?.toLrcString() ?? defaultSampleLyrics;

  static const String defaultSampleLyrics = '''
[00:00.00] ♪ Instrumental Retro Vibe Intro ♪
[00:08.00] Pehli dafa jab dekha tujhe
[00:14.50] Dil ne kaha bas yeh hi hai
[00:21.00] Raaton ki neend udne lagi
[00:28.00] Har pal tera hi khayal hai
[00:35.00] Tum hi ho, ab tum hi ho
[00:42.00] Zindagi ab tum hi ho
[00:49.00] Chain bhi, mera dard bhi
[00:56.00] Meri aashiqui ab tum hi ho
[01:05.00] ♪ Synthwave Melody Solo ♪
[01:15.00] Tere liye hi jiya main
[01:22.00] Khud ko jo yun de diya hai
[01:29.00] Teri wafa ne mujhko sambhala
[01:36.00] Saare ghamon ko dil se nikala
[01:44.00] Tum hi ho, ab tum hi ho
[01:52.00] Zindagi ab tum hi ho
''';

  Map<String, dynamic> toMap() {
    return {
      'songId': songId,
      'title': title,
      'artistName': artist,
      'artistId': artistId,
      'albumName': album,
      'albumId': albumId,
      'genre': genre,
      'releaseYear': releaseYear,
      'duration': duration,
      'coverUrl': coverUrl,
      'audioUrl': audioUrl,
      'isPublished': isPublished,
      'isFeatured': isFeatured,
      'isRetroRadio': isRetroRadio,
      'lyrics': lyricsObject?.toMap() ?? LyricsData(text: lyrics).toMap(),
      'playCount': playCount,
      'createdAt': createdAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
    };
  }

  factory Song.fromMap(Map<String, dynamic> map, [String? docId]) {
    final rawCover = map['coverUrl'] ?? map['image'];
    final rawAudio = map['audioUrl'] ?? map['audio'];

    LyricsData? lyricsObj;
    if (map['lyrics'] is Map) {
      lyricsObj = LyricsData.fromMap(Map<String, dynamic>.from(map['lyrics']));
    } else if (map['lyrics'] is String) {
      lyricsObj = LyricsData(text: map['lyrics'].toString());
    }

    return Song(
      songId: docId ?? map['songId'] ?? '',
      title: map['title'] ?? map['name'] ?? 'Unknown Title',
      artist: map['artistName'] ?? map['artist'] ?? 'Unknown Artist',
      artistId: map['artistId'] ?? '',
      album: map['albumName'] ?? map['album'] ?? 'Single',
      albumId: map['albumId'] ?? '',
      genre: map['genre'] ?? 'Retro',
      releaseYear: map['releaseYear']?.toString() ?? '2024',
      duration: map['duration'] ?? '3:30',
      coverUrl: rawCover?.toString(),
      audioUrl: rawAudio?.toString(),
      lyricsObject: lyricsObj,
      isPublished: map['isPublished'] ?? true,
      isFeatured: map['isFeatured'] ?? false,
      isRetroRadio: map['isRetroRadio'] ?? false,
      playCount: map['playCount'] is int ? map['playCount'] : 0,
      createdAt: map['createdAt'] != null ? DateTime.tryParse(map['createdAt'].toString()) : null,
    );
  }
}

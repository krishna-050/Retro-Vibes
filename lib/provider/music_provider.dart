import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:retro_vibes/data/dummy_songs.dart';
import 'package:retro_vibes/model/song.dart';
import 'package:retro_vibes/services/app_audio_service.dart';

class MusicProvider extends ChangeNotifier {
  final AppAudioService _audioService = AppAudioService();

  List<Song> _playlist = List.from(roadTripSongs);
  final List<Song> _knownCatalog = [];
  // ignore: unused_field
  int _currentIndex = 0;
  final List<Song> _likedSongs = [];
  final List<Song> _playbackHistory = [];
  final Map<String, List<Song>> _customPlaylists = {
    'Late Night Retro': [],
    'Road Trip Classics': [],
  };

  Song? _currentSong;
  bool _isMusicPlayerOpen = false;
  bool _isPlaying = false;
  bool _isShuffle = false;
  bool _isRepeat = false;
  bool _isAutoplayNext = true;
  String _audioQuality = 'High (320kbps)';
  bool _isHandlingCompletion = false;
  bool _isChangingTrack = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  StreamSubscription<PlayerState>? _playerStateSubscription;
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration?>? _durationSubscription;

  MusicProvider() {
    _initAudioStreams();
    _loadFromPrefs();
  }

  // Getters
  Song? get currentSong => _currentSong;
  bool get isMusicPlayerOpen => _isMusicPlayerOpen;
  bool get isPlaying => _isPlaying;
  bool get isShuffle => _isShuffle;
  bool get isRepeat => _isRepeat;
  bool get isAutoplayNext => _isAutoplayNext;
  String get audioQuality => _audioQuality;
  Duration get position => _position;

  void setAutoplayNext(bool value) async {
    _isAutoplayNext = value;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('pref_autoplay_next', value);
    } catch (_) {}
  }

  void setAudioQuality(String quality) async {
    _audioQuality = quality;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('pref_audio_quality', quality);
    } catch (_) {}
  }

  Duration get duration {
    if (_duration != Duration.zero) return _duration;
    if (_currentSong != null && _currentSong!.duration.isNotEmpty) {
      return _parseSongDuration(_currentSong!.duration);
    }
    return Duration.zero;
  }

  Duration _parseSongDuration(String durStr) {
    try {
      final parts = durStr.trim().split(':');
      if (parts.length == 2) {
        final minutes = int.parse(parts[0].trim());
        final seconds = int.parse(parts[1].trim());
        return Duration(minutes: minutes, seconds: seconds);
      }
    } catch (_) {}
    return Duration.zero;
  }

  AudioPlayer get audioPlayer => _audioService.audioPlayer;
  List<Song> get likedSongs => List.unmodifiable(_likedSongs);
  List<Song> get playlist => List.unmodifiable(_playlist);
  Map<String, List<Song>> get customPlaylists => Map.unmodifiable(_customPlaylists);

  void _initAudioStreams() {
    _playerStateSubscription = _audioService.audioPlayer.playerStateStream.listen((state) {
      _isPlaying = state.playing;

      // Auto Play Next Song when current song naturally completes
      if (state.processingState == ProcessingState.completed) {
        debugPrint("[RETRO_AUTONEXT] PROCESSING STATE: completed for ${_currentSong?.title}");
        if (!_isHandlingCompletion) {
          _isHandlingCompletion = true;
          if (_isAutoplayNext) {
            debugPrint("[RETRO_AUTONEXT] Triggering next song automatically");
            nextSong(isAutoNext: true).whenComplete(() {
              Future.delayed(const Duration(milliseconds: 1000), () {
                _isHandlingCompletion = false;
              });
            });
          } else {
            debugPrint("[RETRO_AUTONEXT] Autoplay disabled in settings.");
            _isHandlingCompletion = false;
          }
        }
      }

      notifyListeners();
    });

    _positionSubscription = _audioService.audioPlayer.positionStream.listen((pos) {
      if (_position.inSeconds != pos.inSeconds) {
        _position = pos;
        notifyListeners();
      }
    });

    _durationSubscription = _audioService.audioPlayer.durationStream.listen((dur) {
      if (dur != null && dur != _duration) {
        _duration = dur;
        notifyListeners();
      }
    });
  }

  /// Safely stops playback and clears playback state and user library on user logout
  void resetPlaybackOnLogout() {
    try {
      _audioService.audioPlayer.stop();
      _audioService.currentSong = null;
    } catch (e) {
      debugPrint('Logout audio stop error: $e');
    }
    _currentSong = null;
    _position = Duration.zero;
    _duration = Duration.zero;
    _playbackHistory.clear();
    _isMusicPlayerOpen = false;

    // Clear user library memory so next logged in user doesn't see previous user's data
    _likedSongs.clear();
    _customPlaylists.clear();
    _activeUserId = null;

    notifyListeners();
  }

  String? _activeUserId;

  /// Permanently sync user's library (Liked Songs & Custom Playlists) from Cloud Firestore for specific UID
  void syncUserLibrary(String? userId) {
    if (userId == null || userId.isEmpty || userId == 'local_user') {
      // Guest or logged out: clear user memory
      if (_activeUserId != null) {
        _likedSongs.clear();
        _customPlaylists.clear();
        _activeUserId = null;
        notifyListeners();
      }
      return;
    }

    if (_activeUserId == userId) return;

    // Account switched! Clear memory first to prevent data bleeding
    _likedSongs.clear();
    _customPlaylists.clear();
    _activeUserId = userId;
    notifyListeners();

    _loadFromFirestoreAndPrefs(userId);
  }

  Future<void> _loadFromFirestoreAndPrefs(String userId) async {
    await _loadFromPrefs(userId);

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('user_data')
          .doc('library')
          .get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;

        // Load Liked Songs permanently from Firestore
        if (data['likedSongs'] is List) {
          final List rawLiked = data['likedSongs'] as List;
          _likedSongs.clear();
          for (final item in rawLiked) {
            if (item is Map<String, dynamic>) {
              _likedSongs.add(Song.fromMap(item));
            } else if (item is Map) {
              _likedSongs.add(Song.fromMap(Map<String, dynamic>.from(item)));
            }
          }
        } else {
          _likedSongs.clear();
        }

        // Load Custom Playlists permanently from Firestore
        if (data['customPlaylists'] is Map) {
          final Map<String, dynamic> rawPlaylists = Map<String, dynamic>.from(data['customPlaylists'] as Map);
          _customPlaylists.clear();
          rawPlaylists.forEach((pName, songsRaw) {
            if (songsRaw is List) {
              final List<Song> pSongs = [];
              for (final item in songsRaw) {
                if (item is Map<String, dynamic>) {
                  pSongs.add(Song.fromMap(item));
                } else if (item is Map) {
                  pSongs.add(Song.fromMap(Map<String, dynamic>.from(item)));
                }
              }
              _customPlaylists[pName] = pSongs;
            }
          });
        } else {
          _customPlaylists.clear();
        }

        notifyListeners();
        await _saveToPrefsAndFirestore(userId);
      } else {
        // New user with no document in Firestore yet
        _likedSongs.clear();
        _customPlaylists.clear();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error syncing library from Firestore: $e');
    }
  }

  // Local & Firestore Persistence Methods (User UID Scoped)
  Future<void> _loadFromPrefs([String? uid]) async {
    final userId = uid ?? _activeUserId ?? 'guest';
    try {
      final prefs = await SharedPreferences.getInstance();

      final likedTitles = prefs.getStringList('liked_song_titles_$userId') ?? [];
      _likedSongs.clear();
      for (final title in likedTitles) {
        final songMatch = _getAllAvailableSongs().firstWhere(
          (s) => s.title == title,
          orElse: () => Song(title: title, artist: 'Retro Artist', duration: '3:30', image: 'assets/images/80s_hit.png'),
        );
        if (songMatch.title.isNotEmpty) {
          _likedSongs.add(songMatch);
        }
      }

      final playlistsJsonStr = prefs.getString('custom_playlists_$userId');
      if (playlistsJsonStr != null) {
        final Map<String, dynamic> rawMap = json.decode(playlistsJsonStr);
        _customPlaylists.clear();
        rawMap.forEach((pName, songTitlesRaw) {
          final List<dynamic> songTitles = songTitlesRaw as List<dynamic>;
          final List<Song> pSongs = [];
          for (final t in songTitles) {
            final songMatch = _getAllAvailableSongs().firstWhere(
              (s) => s.title == t.toString(),
              orElse: () => Song(title: t.toString(), artist: 'Retro Artist', duration: '3:30', image: 'assets/images/70s.png'),
            );
            if (songMatch.title.isNotEmpty) {
              pSongs.add(songMatch);
            }
          }
          _customPlaylists[pName] = pSongs;
        });
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading preferences: $e');
    }
  }

  Future<void> _saveToPrefsAndFirestore([String? userId]) async {
    final uid = userId ?? _activeUserId ?? 'guest';

    try {
      final prefs = await SharedPreferences.getInstance();

      final likedTitles = _likedSongs.map((s) => s.title).toList();
      await prefs.setStringList('liked_song_titles_$uid', likedTitles);

      final Map<String, List<String>> serializableMap = {};
      _customPlaylists.forEach((key, list) {
        serializableMap[key] = list.map((s) => s.title).toList();
      });
      await prefs.setString('custom_playlists_$uid', json.encode(serializableMap));

      // Permanent Cloud Firestore Backup under users/{uid}/user_data/library
      if (uid.isNotEmpty && uid != 'local_user' && uid != 'guest') {
        final Map<String, dynamic> serializablePlaylistsData = {};
        _customPlaylists.forEach((key, list) {
          serializablePlaylistsData[key] = list.map((s) => s.toMap()).toList();
        });

        final likedSongsData = _likedSongs.map((s) => s.toMap()).toList();

        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('user_data')
            .doc('library')
            .set({
          'likedSongs': likedSongsData,
          'customPlaylists': serializablePlaylistsData,
          'updatedAt': DateTime.now().toIso8601String(),
        }, SetOptions(merge: true));
        debugPrint('Library synced permanently to Firestore for user: $uid');
      }
    } catch (e) {
      debugPrint('Error saving preferences and Firestore: $e');
    }
  }

  /// Helper to aggregate all available songs across active playlists, known catalog, and dummy lists
  List<Song> _getAllAvailableSongs() {
    final Map<String, Song> uniqueMap = {};

    for (final s in _playlist) {
      if (s.title.trim().isNotEmpty) {
        uniqueMap[s.title.trim().toLowerCase()] = s;
      }
    }
    for (final s in _knownCatalog) {
      if (s.title.trim().isNotEmpty) {
        uniqueMap[s.title.trim().toLowerCase()] = s;
      }
    }
    for (final s in roadTripSongs) {
      if (s.title.trim().isNotEmpty) {
        uniqueMap[s.title.trim().toLowerCase()] = s;
      }
    }
    for (final s in eightiesHitsSongs) {
      if (s.title.trim().isNotEmpty) {
        uniqueMap[s.title.trim().toLowerCase()] = s;
      }
    }
    for (final s in ninetiesNostalgiaSongs) {
      if (s.title.trim().isNotEmpty) {
        uniqueMap[s.title.trim().toLowerCase()] = s;
      }
    }
    if (_currentSong != null && _currentSong!.title.trim().isNotEmpty) {
      uniqueMap[_currentSong!.title.trim().toLowerCase()] = _currentSong!;
    }

    return uniqueMap.values.toList();
  }

  Future<void> playSong(Song song, {List<Song>? playlist, bool recordHistory = true}) async {
    debugPrint("[RETRO_AUDIO_TRANSITION] playSong requested: ${song.title}");

    if (playlist != null && playlist.isNotEmpty) {
      _playlist = List.from(playlist);
      for (final s in playlist) {
        if (!_knownCatalog.any((k) => k.title == s.title)) {
          _knownCatalog.add(s);
        }
      }
    }

    if (!_knownCatalog.any((k) => k.title == song.title)) {
      _knownCatalog.add(song);
    }

    if (!_playlist.any((s) => s.title == song.title)) {
      _playlist.add(song);
    }

    // Record previous song into playback history stack for Previous navigation
    if (recordHistory && _currentSong != null && _currentSong!.title != song.title) {
      _playbackHistory.add(_currentSong!);
    }

    _currentIndex = _playlist.indexWhere((s) => s.title == song.title);
    _currentSong = song;

    notifyListeners();
    await _audioService.playAudio(song);
  }

  /// Centralized Track Transition: Next Song Navigation
  Future<void> nextSong({bool isAutoNext = false}) async {
    if (_isChangingTrack) {
      debugPrint("[RETRO_NEXT] Already changing track, ignoring call.");
      return;
    }
    _isChangingTrack = true;

    final logPrefix = isAutoNext ? "[RETRO_AUTONEXT]" : "[RETRO_NEXT]";

    try {
      debugPrint("$logPrefix NEXT PRESSED / TRIGGERED");
      debugPrint("$logPrefix CURRENT SONG: ${_currentSong?.title}");
      debugPrint("$logPrefix SHUFFLE: $_isShuffle, REPEAT: $_isRepeat");

      // Repeat mode override
      if (_isRepeat && _currentSong != null) {
        debugPrint("$logPrefix REPEAT MODE: Replaying current song ${_currentSong!.title}");
        await playSong(_currentSong!, recordHistory: false);
        return;
      }

      // 1. Shuffle mode: select random song from all available catalog
      if (_isShuffle) {
        final available = _getAllAvailableSongs();
        if (available.isEmpty) {
          debugPrint("$logPrefix SHUFFLE FAILED: No available songs.");
          return;
        }

        if (available.length == 1) {
          debugPrint("$logPrefix SHUFFLE: Only 1 song available, replaying.");
          await playSong(available[0], recordHistory: true);
          return;
        }

        // Exclude current song from candidates to ensure distinct next song
        final candidates = available.where((s) => s.title != _currentSong?.title).toList();
        final pool = candidates.isNotEmpty ? candidates : available;

        final randomNextSong = pool[Random().nextInt(pool.length)];
        debugPrint("$logPrefix SELECTED RANDOM NEXT SONG: ${randomNextSong.title}");
        await playSong(randomNextSong, recordHistory: true);
        return;
      }

      // 2. Non-shuffle mode: Use active playlist first
      if (_playlist.length > 1 && _currentSong != null) {
        int currentIndex = _playlist.indexWhere(
          (s) => s.title.trim().toLowerCase() == _currentSong!.title.trim().toLowerCase(),
        );
        if (currentIndex != -1) {
          int nextIndex = (currentIndex + 1) % _playlist.length;
          final targetSong = _playlist[nextIndex];
          debugPrint("$logPrefix PLAYLIST INDEX $currentIndex -> $nextIndex, SONG: ${targetSong.title}");
          await playSong(targetSong, recordHistory: true);
          return;
        }
      }

      // 3. Fallback: Use all available catalog songs if playlist is empty or single song
      final available = _getAllAvailableSongs();
      if (available.isNotEmpty) {
        int currentIndex = _currentSong != null
            ? available.indexWhere(
                (s) => s.title.trim().toLowerCase() == _currentSong!.title.trim().toLowerCase(),
              )
            : -1;

        int nextIndex = 0;
        if (currentIndex != -1 && available.length > 1) {
          nextIndex = (currentIndex + 1) % available.length;
        }

        final targetSong = available[nextIndex];
        debugPrint("$logPrefix CATALOG FALLBACK INDEX $currentIndex -> $nextIndex, SONG: ${targetSong.title}");
        await playSong(targetSong, recordHistory: true);
      } else {
        debugPrint("$logPrefix NO SONGS AVAILABLE IN CATALOG.");
      }
    } catch (e) {
      debugPrint("$logPrefix ERROR in nextSong: $e");
    } finally {
      _isChangingTrack = false;
    }
  }

  /// Centralized Track Transition: Previous Song Navigation
  Future<void> previousSong() async {
    if (_isChangingTrack) {
      debugPrint("[RETRO_PREVIOUS] Already changing track, ignoring call.");
      return;
    }
    _isChangingTrack = true;

    try {
      debugPrint("[RETRO_PREVIOUS] PREVIOUS PRESSED");
      debugPrint("[RETRO_PREVIOUS] CURRENT POSITION: ${_position.inSeconds}s, HISTORY SIZE: ${_playbackHistory.length}");
      debugPrint("[RETRO_PREVIOUS] CURRENT SONG: ${_currentSong?.title}");

      // If position > 3 seconds, seek to start of current song
      if (_position.inSeconds > 3) {
        debugPrint("[RETRO_PREVIOUS] POSITION > 3s, seeking to 0:00");
        seek(Duration.zero);
        _audioService.audioPlayer.play();
        return;
      }

      // Check playback history stack
      if (_playbackHistory.isNotEmpty) {
        final prevSong = _playbackHistory.removeLast();
        debugPrint("[RETRO_PREVIOUS] PLAYING FROM HISTORY STACK: ${prevSong.title}");
        await playSong(prevSong, recordHistory: false);
        return;
      }

      // Fallback 1: Use active playlist previous song
      if (_playlist.length > 1 && _currentSong != null) {
        int currentIndex = _playlist.indexWhere(
          (s) => s.title.trim().toLowerCase() == _currentSong!.title.trim().toLowerCase(),
        );
        if (currentIndex != -1) {
          int prevIndex = (currentIndex - 1 + _playlist.length) % _playlist.length;
          final targetSong = _playlist[prevIndex];
          debugPrint("[RETRO_PREVIOUS] PLAYLIST INDEX $currentIndex -> $prevIndex, SONG: ${targetSong.title}");
          await playSong(targetSong, recordHistory: false);
          return;
        }
      }

      // Fallback 2: Use catalog previous song
      final available = _getAllAvailableSongs();
      if (available.isNotEmpty) {
        int currentIndex = _currentSong != null
            ? available.indexWhere(
                (s) => s.title.trim().toLowerCase() == _currentSong!.title.trim().toLowerCase(),
              )
            : -1;

        int prevIndex = 0;
        if (currentIndex != -1 && available.length > 1) {
          prevIndex = (currentIndex - 1 + available.length) % available.length;
        }

        final targetSong = available[prevIndex];
        debugPrint("[RETRO_PREVIOUS] CATALOG FALLBACK INDEX $currentIndex -> $prevIndex, SONG: ${targetSong.title}");
        await playSong(targetSong, recordHistory: false);
        return;
      }

      // Default fallback: Seek to 0:00
      debugPrint("[RETRO_PREVIOUS] FALLBACK: Seeking to 0:00");
      seek(Duration.zero);
      _audioService.audioPlayer.play();
    } catch (e) {
      debugPrint("[RETRO_PREVIOUS] ERROR in previousSong: $e");
    } finally {
      _isChangingTrack = false;
    }
  }

  void toggleShuffle() {
    _isShuffle = !_isShuffle;
    notifyListeners();
  }

  void toggleRepeat() {
    _isRepeat = !_isRepeat;
    notifyListeners();
  }

  bool isLiked(Song song) {
    return _likedSongs.any((s) => s.title == song.title);
  }

  void toggleLike(Song song, {String? userId}) {
    if (isLiked(song)) {
      _likedSongs.removeWhere((s) => s.title == song.title);
    } else {
      _likedSongs.add(song);
    }
    _saveToPrefsAndFirestore(userId);
    notifyListeners();
  }

  void createPlaylist(String name, {String? userId}) {
    if (name.isNotEmpty && !_customPlaylists.containsKey(name)) {
      _customPlaylists[name] = [];
      _saveToPrefsAndFirestore(userId);
      notifyListeners();
    }
  }

  void deletePlaylist(String name, {String? userId}) {
    if (_customPlaylists.containsKey(name)) {
      _customPlaylists.remove(name);
      _saveToPrefsAndFirestore(userId);
      notifyListeners();
    }
  }

  void addToPlaylist(String playlistName, Song song, {String? userId}) {
    if (_customPlaylists.containsKey(playlistName)) {
      final list = _customPlaylists[playlistName]!;
      if (!list.any((s) => s.title == song.title)) {
        list.add(song);
        _saveToPrefsAndFirestore(userId);
        notifyListeners();
      }
    }
  }

  void removeFromPlaylist(String playlistName, String songTitle, {String? userId}) {
    if (_customPlaylists.containsKey(playlistName)) {
      _customPlaylists[playlistName]!.removeWhere((s) => s.title == songTitle);
      _saveToPrefsAndFirestore(userId);
      notifyListeners();
    }
  }

  void togglePlayPause() {
    _audioService.togglePlayPause();
  }

  void seek(Duration position) {
    _audioService.seek(position);
  }

  void setMusicPlayerOpen(bool isOpen) {
    _isMusicPlayerOpen = isOpen;
    notifyListeners();
  }

  @override
  void dispose() {
    _playerStateSubscription?.cancel();
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    super.dispose();
  }
}

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:retro_vibes/model/song.dart';

class AppAudioService {
  static final AppAudioService instance = AppAudioService._internal();
  factory AppAudioService() => instance;
  
  AppAudioService._internal() {
    debugPrint("[RETRO_AUDIO_TRACE] AppAudioService INSTANCE: $hashCode");
  }

  AudioPlayer? _player;

  void initPlayer() {
    if (_player != null) {
      debugPrint("[RETRO_AUDIO_INIT] initPlayer() called, but Existing player found: ${_player!.hashCode}");
      debugPrint("[RETRO_AUDIO_TRACE] AudioPlayer INSTANCE: ${_player!.hashCode}");
      return;
    }

    debugPrint("[RETRO_AUDIO_INIT] Starting background audio initialization / Creating AudioPlayer");
    debugPrint("[RETRO_AUDIO_INIT] Creating AudioPlayer");
    _player = AudioPlayer();
    _player!.setVolume(1.0);
    debugPrint("[RETRO_AUDIO] AudioPlayer CREATED: ${_player.hashCode}");
    debugPrint("[RETRO_AUDIO_TRACE] AudioPlayer INSTANCE: ${_player!.hashCode}");
    debugPrint("[RETRO_AUDIO_INIT] AudioPlayer ready");

    _player!.playbackEventStream.listen((event) {
      debugPrint("[RETRO_AUDIO_STATE] ProcessingState: ${event.processingState}");
    }, onError: (Object e, StackTrace st) {
      debugPrint("[RETRO_AUDIO_ERROR] Playback stream error: $e");
      if (e is PlayerException) {
        debugPrint("[RETRO_AUDIO_ERROR] PlayerException Code: ${e.code}");
        debugPrint("[RETRO_AUDIO_ERROR] PlayerException Message: ${e.message}");
      }
    });

    _player!.playerStateStream.listen((state) {
      debugPrint("[RETRO_AUDIO_STATE] Playing: ${state.playing}, ProcessingState: ${state.processingState}");
    });
  }

  AudioPlayer get audioPlayer {
    if (_player == null) {
      initPlayer();
    }
    debugPrint("[RETRO_AUDIO_TRACE] AudioPlayer ACCESS hashCode: ${_player?.hashCode}");
    return _player!;
  }

  Uri? _resolveArtUri(String coverUrl) {
    final clean = coverUrl.trim();
    if (clean.isEmpty) {
      return Uri.parse('https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=500');
    }
    if (clean.startsWith('http')) {
      return Uri.tryParse(clean);
    }
    if (clean.startsWith('assets/')) {
      return Uri.parse('asset:///$clean');
    }
    if (clean.startsWith('file:') || clean.startsWith('/')) {
      final path = clean.replaceAll('file://', '');
      return Uri.parse('file://$path');
    }
    return Uri.parse('https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=500');
  }

  Duration? _parseDuration(String durStr) {
    try {
      final parts = durStr.trim().split(':');
      if (parts.length == 2) {
        final min = int.parse(parts[0]);
        final sec = int.parse(parts[1]);
        return Duration(minutes: min, seconds: sec);
      }
    } catch (_) {}
    return null;
  }

  Song? currentSong;

  Future<void> playAudio(Song song) async {
    debugPrint("[RETRO_AUDIO_INIT] playAudio called for: ${song.title}");
    debugPrint("[RETRO_AUDIO_TRACE] playAudio - AppAudioService INSTANCE: ${instance.hashCode}, AudioPlayer INSTANCE: ${audioPlayer.hashCode}");
    
    final audioUrl = song.audio.trim();
    
    debugPrint("=== RETRO VIBES AUDIO DEBUG ===");
    debugPrint("Song title: ${song.title}");
    debugPrint("Original URL / Path: $audioUrl");

    if (audioUrl.isEmpty) {
      debugPrint("[RETRO_AUDIO_ERROR] URL is empty!");
      return;
    }

    try {
      final player = audioPlayer;
      debugPrint("[RETRO_AUDIO_TRACE] AudioPlayer USING hashCode: ${player.hashCode}");

      final isNewSong = currentSong == null ||
          currentSong!.title != song.title ||
          currentSong!.audio != song.audio;

      if (isNewSong) {
        debugPrint("[RETRO_AUDIO_TRANSITION] Changing audio source to: ${song.title}");

        final mediaItem = MediaItem(
          id: song.songId.isNotEmpty ? song.songId : 'song_${song.title.hashCode}',
          album: song.album.isNotEmpty ? song.album : "Retro Vibes",
          title: song.title.isNotEmpty ? song.title : "Unknown Track",
          artist: song.artist.isNotEmpty ? song.artist : "Retro Vibes",
          artUri: _resolveArtUri(song.coverUrl),
          duration: _parseDuration(song.duration),
        );

        AudioSource source;
        if (audioUrl.startsWith('http')) {
          debugPrint("[RETRO_AUDIO] Loading Network AudioSource: $audioUrl");
          source = AudioSource.uri(Uri.parse(audioUrl), tag: mediaItem);
        } else if (audioUrl.startsWith('/') || audioUrl.startsWith('file:') || audioUrl.contains('storage')) {
          final filePath = audioUrl.replaceAll('file://', '');
          debugPrint("[RETRO_AUDIO] Loading Local File: $filePath");
          source = AudioSource.file(filePath, tag: mediaItem);
        } else if (audioUrl.startsWith('assets/')) {
          debugPrint("[RETRO_AUDIO] Loading Asset: $audioUrl");
          source = AudioSource.asset(audioUrl, tag: mediaItem);
        } else {
          final fallbackUrl = audioUrl.contains('.') ? audioUrl : '';
          debugPrint("[RETRO_AUDIO] Loading Fallback AudioSource: $fallbackUrl");
          source = AudioSource.uri(Uri.parse(fallbackUrl), tag: mediaItem);
        }

        // Pause active playback smoothly if playing to transition to new AudioSource without destroying background notification widget
        try {
          if (player.playing) {
            await player.pause();
          }
        } catch (_) {}

        debugPrint("[RETRO_AUDIO_TRANSITION] Calling setAudioSource for: ${song.title}");
        final duration = await player.setAudioSource(source);
        debugPrint("[RETRO_AUDIO_TRANSITION] setAudioSource SUCCESS, duration: $duration");

        currentSong = song;
      } else {
        debugPrint("[RETRO_AUDIO_TRANSITION] Same song requested: ${song.title}");
        if (player.processingState == ProcessingState.completed) {
          await player.seek(Duration.zero);
        }
      }

      debugPrint("[RETRO_AUDIO_TRANSITION] Calling play()...");
      debugPrint("[RETRO_AUDIO_TRACE] play() USING hashCode: ${player.hashCode}");
      player.play();
      debugPrint("[RETRO_AUDIO_TRANSITION] play() triggered successfully for ${song.title}.");
    } catch (e, st) {
      debugPrint("[RETRO_AUDIO_ERROR] ================================");
      debugPrint("[RETRO_AUDIO_ERROR] Playback failed for song: ${song.title}");
      debugPrint("[RETRO_AUDIO_ERROR] Source URL/Path: $audioUrl");
      debugPrint("[RETRO_AUDIO_ERROR] Exception Type: ${e.runtimeType}");
      debugPrint("[RETRO_AUDIO_ERROR] Exception Details: $e");
      if (e is PlayerException) {
        debugPrint("[RETRO_AUDIO_ERROR] PlayerException Code: ${e.code}");
        debugPrint("[RETRO_AUDIO_ERROR] PlayerException Message: ${e.message}");
      }
      debugPrint("[RETRO_AUDIO_ERROR] Stacktrace:\n$st");
      debugPrint("[RETRO_AUDIO_ERROR] ================================");
    }
  }

  void togglePlayPause() {
    final player = audioPlayer;
    debugPrint("[RETRO_AUDIO_TRACE] togglePlayPause USING hashCode: ${player.hashCode}");
    if (player.playing) {
      player.pause();
    } else {
      player.play();
    }
  }

  void seek(Duration position) {
    debugPrint("[RETRO_AUDIO_TRACE] seek USING hashCode: ${audioPlayer.hashCode}");
    audioPlayer.seek(position);
  }
}

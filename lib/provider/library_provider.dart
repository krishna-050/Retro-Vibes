import 'package:flutter/material.dart';
import 'package:retro_vibes/model/playlist_model.dart';
import 'package:retro_vibes/model/song.dart';
import 'package:retro_vibes/repositories/library_repository.dart';

class LibraryProvider extends ChangeNotifier {
  final LibraryRepository _libraryRepository = LibraryRepository();

  List<Song> _likedSongs = [];
  List<PlaylistModel> _userPlaylists = [];
  List<Song> _recentlyPlayed = [];
  bool _isLoading = false;

  List<Song> get likedSongs => List.unmodifiable(_likedSongs);
  List<PlaylistModel> get userPlaylists => List.unmodifiable(_userPlaylists);
  List<Song> get recentlyPlayed => List.unmodifiable(_recentlyPlayed);
  bool get isLoading => _isLoading;

  Future<void> loadLibraryData(String uid, List<Song> allAvailableSongs) async {
    _isLoading = true;
    notifyListeners();

    try {
      final likedIds = await _libraryRepository.getLikedSongIds(uid);
      _likedSongs = allAvailableSongs.where((s) => likedIds.contains(s.songId)).toList();
      _userPlaylists = await _libraryRepository.getUserPlaylists(uid);
    } catch (e) {
      debugPrint('LibraryProvider loadLibraryData error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  bool isLiked(Song song) {
    return _likedSongs.any((s) => s.songId == song.songId || s.title == song.title);
  }

  Future<void> toggleLike({required String uid, required Song song}) async {
    final currentlyLiked = isLiked(song);
    if (currentlyLiked) {
      _likedSongs.removeWhere((s) => s.songId == song.songId || s.title == song.title);
    } else {
      _likedSongs.add(song);
    }
    notifyListeners();

    if (uid.isNotEmpty && !uid.startsWith('local_')) {
      await _libraryRepository.toggleFavorite(
        uid: uid,
        song: song,
        isCurrentlyLiked: currentlyLiked,
      );
    }
  }

  Future<void> createPlaylist({required String uid, required String name}) async {
    if (name.trim().isEmpty) return;
    final newPlaylist = await _libraryRepository.createPlaylist(uid: uid, playlistName: name);
    if (newPlaylist != null) {
      _userPlaylists.add(newPlaylist);
      notifyListeners();
    }
  }

  Future<void> addToPlaylist({required String playlistId, required String songId}) async {
    await _libraryRepository.addSongToPlaylist(playlistId: playlistId, songId: songId);
    final index = _userPlaylists.indexWhere((p) => p.playlistId == playlistId);
    if (index != -1) {
      final old = _userPlaylists[index];
      if (!old.songIds.contains(songId)) {
        final updatedList = List<String>.from(old.songIds)..add(songId);
        _userPlaylists[index] = PlaylistModel(
          playlistId: old.playlistId,
          name: old.name,
          ownerId: old.ownerId,
          coverUrl: old.coverUrl,
          songIds: updatedList,
          createdAt: old.createdAt,
          updatedAt: DateTime.now(),
        );
        notifyListeners();
      }
    }
  }

  void addRecentlyPlayed(Song song) {
    _recentlyPlayed.removeWhere((s) => s.songId == song.songId || s.title == song.title);
    _recentlyPlayed.insert(0, song);
    if (_recentlyPlayed.length > 20) {
      _recentlyPlayed = _recentlyPlayed.sublist(0, 20);
    }
    notifyListeners();
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:retro_vibes/model/playlist_model.dart';
import 'package:retro_vibes/model/song.dart';

class LibraryRepository {
  FirebaseFirestore? get _firestore {
    try {
      return FirebaseFirestore.instance;
    } catch (e) {
      debugPrint('FirebaseFirestore instance error: $e');
      return null;
    }
  }

  /// Get user's liked song IDs
  Future<List<String>> getLikedSongIds(String uid) async {
    final firestore = _firestore;
    if (firestore == null) return [];

    try {
      final snapshot = await firestore.collection('users').doc(uid).collection('favorites').get();
      return snapshot.docs.map((doc) => doc.id).toList();
    } catch (e) {
      debugPrint('LibraryRepository getLikedSongIds error: $e');
      return [];
    }
  }

  /// Toggle liked status for a song in `users/{uid}/favorites/{songId}`
  Future<bool> toggleFavorite({
    required String uid,
    required Song song,
    required bool isCurrentlyLiked,
  }) async {
    final firestore = _firestore;
    if (firestore == null) return !isCurrentlyLiked;

    try {
      final docRef = firestore.collection('users').doc(uid).collection('favorites').doc(song.songId);
      if (isCurrentlyLiked) {
        await docRef.delete();
        return false;
      } else {
        await docRef.set({
          'songId': song.songId,
          'title': song.title,
          'artist': song.artist,
          'addedAt': DateTime.now().toIso8601String(),
        });
        return true;
      }
    } catch (e) {
      debugPrint('LibraryRepository toggleFavorite error: $e');
      return !isCurrentlyLiked;
    }
  }

  /// Fetch custom playlists for user
  Future<List<PlaylistModel>> getUserPlaylists(String uid) async {
    final firestore = _firestore;
    if (firestore == null) return [];

    try {
      final snapshot = await firestore
          .collection('playlists')
          .where('ownerId', isEqualTo: uid)
          .get();

      return snapshot.docs.map((doc) => PlaylistModel.fromMap(doc.data(), doc.id)).toList();
    } catch (e) {
      debugPrint('LibraryRepository getUserPlaylists error: $e');
      return [];
    }
  }

  /// Create new playlist in Firestore
  Future<PlaylistModel?> createPlaylist({
    required String uid,
    required String playlistName,
  }) async {
    final firestore = _firestore;
    if (firestore == null) return null;

    try {
      final docRef = firestore.collection('playlists').doc();
      final playlist = PlaylistModel(
        playlistId: docRef.id,
        name: playlistName,
        ownerId: uid,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await docRef.set(playlist.toMap());
      return playlist;
    } catch (e) {
      debugPrint('LibraryRepository createPlaylist error: $e');
      return null;
    }
  }

  /// Add song to custom playlist
  Future<void> addSongToPlaylist({
    required String playlistId,
    required String songId,
  }) async {
    final firestore = _firestore;
    if (firestore == null) return;

    try {
      await firestore.collection('playlists').doc(playlistId).update({
        'songIds': FieldValue.arrayUnion([songId]),
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('LibraryRepository addSongToPlaylist error: $e');
    }
  }

  /// Save recently played song ID
  Future<void> saveRecentlyPlayed({
    required String uid,
    required String songId,
  }) async {
    final firestore = _firestore;
    if (firestore == null) return;

    try {
      await firestore.collection('users').doc(uid).collection('recentlyPlayed').doc(songId).set({
        'songId': songId,
        'playedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('LibraryRepository saveRecentlyPlayed error: $e');
    }
  }
}

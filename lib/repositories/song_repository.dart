import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:retro_vibes/model/song.dart';

class SongRepository {
  FirebaseFirestore? get _firestore {
    try {
      return FirebaseFirestore.instance;
    } catch (e) {
      debugPrint('FirebaseFirestore instance error: $e');
      return null;
    }
  }

  int _getSongTimestamp(Song song) {
    if (song.createdAt != null) {
      return song.createdAt!.millisecondsSinceEpoch;
    }
    try {
      if (song.songId.startsWith('song_')) {
        final parts = song.songId.split('_');
        if (parts.length >= 2) {
          final ts = int.tryParse(parts[1]);
          if (ts != null) return ts;
        }
      }
    } catch (_) {}
    return 0;
  }

  /// Real-time stream of all published songs (`isPublished == true`) directly from Cloud Firestore (Newest first)
  Stream<List<Song>> getPublishedSongsStream() {
    final firestore = _firestore;
    if (firestore == null) {
      return Stream.value([]);
    }
    try {
      return firestore.collection('songs').snapshots().map((snapshot) {
        if (snapshot.docs.isEmpty) return [];
        final list = snapshot.docs
            .map((doc) => Song.fromMap(doc.data(), doc.id))
            .where((song) => song.isPublished)
            .toList();

        // Sort newest added songs first at the top
        list.sort((a, b) => _getSongTimestamp(b).compareTo(_getSongTimestamp(a)));
        return list;
      });
    } catch (e) {
      debugPrint('SongRepository getPublishedSongsStream error: $e');
      return Stream.value([]);
    }
  }

  /// Real-time stream of featured songs (`isFeatured == true` and `isPublished == true`) (Newest first)
  Stream<List<Song>> getFeaturedSongsStream() {
    final firestore = _firestore;
    if (firestore == null) {
      return Stream.value([]);
    }
    try {
      return firestore.collection('songs').snapshots().map((snapshot) {
        if (snapshot.docs.isEmpty) return [];
        final list = snapshot.docs
            .map((doc) => Song.fromMap(doc.data(), doc.id))
            .where((song) => song.isPublished && song.isFeatured)
            .toList();

        list.sort((a, b) => _getSongTimestamp(b).compareTo(_getSongTimestamp(a)));
        return list;
      });
    } catch (e) {
      debugPrint('SongRepository getFeaturedSongsStream error: $e');
      return Stream.value([]);
    }
  }

  /// Real-time stream of Retro Radio songs (`isRetroRadio == true` and `isPublished == true`) (Newest first)
  Stream<List<Song>> getRetroRadioSongsStream() {
    final firestore = _firestore;
    if (firestore == null) {
      return Stream.value([]);
    }
    try {
      return firestore.collection('songs').snapshots().map((snapshot) {
        if (snapshot.docs.isEmpty) return [];
        final list = snapshot.docs
            .map((doc) => Song.fromMap(doc.data(), doc.id))
            .where((song) => song.isPublished && song.isRetroRadio)
            .toList();

        list.sort((a, b) => _getSongTimestamp(b).compareTo(_getSongTimestamp(a)));
        return list;
      });
    } catch (e) {
      debugPrint('SongRepository getRetroRadioSongsStream error: $e');
      return Stream.value([]);
    }
  }

  /// Stream of all songs in catalog for Admin Dashboard (Newest first)
  Stream<List<Song>> getAllSongsStream() {
    final firestore = _firestore;
    if (firestore == null) {
      return Stream.value([]);
    }
    try {
      return firestore.collection('songs').snapshots().map((snapshot) {
        if (snapshot.docs.isEmpty) return [];
        final list = snapshot.docs.map((doc) => Song.fromMap(doc.data(), doc.id)).toList();
        list.sort((a, b) => _getSongTimestamp(b).compareTo(_getSongTimestamp(a)));
        return list;
      });
    } catch (e) {
      debugPrint('SongRepository getAllSongsStream error: $e');
      return Stream.value([]);
    }
  }

  /// Fetch all published songs (Newest first)
  Future<List<Song>> getPublishedSongs() async {
    final firestore = _firestore;
    if (firestore != null) {
      try {
        final snapshot = await firestore.collection('songs').get();
        if (snapshot.docs.isNotEmpty) {
          final list = snapshot.docs
              .map((doc) => Song.fromMap(doc.data(), doc.id))
              .where((s) => s.isPublished)
              .toList();

          list.sort((a, b) => _getSongTimestamp(b).compareTo(_getSongTimestamp(a)));
          return list;
        }
      } catch (e) {
        debugPrint('SongRepository getPublishedSongs error: $e');
      }
    }
    return [];
  }

  /// Search songs
  Future<List<Song>> searchSongs(String query) async {
    final lowerQuery = query.toLowerCase().trim();
    if (lowerQuery.isEmpty) return getPublishedSongs();

    final all = await getPublishedSongs();
    return all.where((song) {
      return song.title.toLowerCase().contains(lowerQuery) ||
          song.artist.toLowerCase().contains(lowerQuery) ||
          song.genre.toLowerCase().contains(lowerQuery) ||
          song.album.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  /// Add a new song document in Firestore `songs/{songId}`
  Future<void> addSong(Song song) async {
    final firestore = _firestore;
    if (firestore != null) {
      try {
        await firestore.collection('songs').doc(song.songId).set(song.toMap());
      } catch (e) {
        debugPrint('SongRepository addSong error: $e');
      }
    }
  }

  /// Update song metadata in Firestore
  Future<void> updateSong(Song song) async {
    final firestore = _firestore;
    if (firestore != null) {
      try {
        await firestore.collection('songs').doc(song.songId).update(song.toMap());
      } catch (e) {
        debugPrint('SongRepository updateSong error: $e');
      }
    }
  }

  /// Toggle song published state
  Future<void> togglePublishState(String songId, bool isPublished) async {
    final firestore = _firestore;
    if (firestore != null) {
      try {
        await firestore.collection('songs').doc(songId).update({
          'isPublished': isPublished,
          'updatedAt': DateTime.now().toIso8601String(),
        });
      } catch (e) {
        debugPrint('SongRepository togglePublishState error: $e');
      }
    }
  }

  /// Toggle song featured state
  Future<void> toggleFeaturedState(String songId, bool isFeatured) async {
    final firestore = _firestore;
    if (firestore != null) {
      try {
        await firestore.collection('songs').doc(songId).update({
          'isFeatured': isFeatured,
          'updatedAt': DateTime.now().toIso8601String(),
        });
      } catch (e) {
        debugPrint('SongRepository toggleFeaturedState error: $e');
      }
    }
  }

  /// Toggle song retro radio state
  Future<void> toggleRetroRadioState(String songId, bool isRetroRadio) async {
    final firestore = _firestore;
    if (firestore != null) {
      try {
        await firestore.collection('songs').doc(songId).update({
          'isRetroRadio': isRetroRadio,
          'updatedAt': DateTime.now().toIso8601String(),
        });
      } catch (e) {
        debugPrint('SongRepository toggleRetroRadioState error: $e');
      }
    }
  }

  /// Delete a song from Firestore
  Future<void> deleteSong(String songId) async {
    final firestore = _firestore;
    if (firestore != null) {
      try {
        await firestore.collection('songs').doc(songId).delete();
      } catch (e) {
        debugPrint('SongRepository deleteSong error: $e');
      }
    }
  }

  /// Increment play count
  Future<void> incrementPlayCount(String songId) async {
    final firestore = _firestore;
    if (firestore != null) {
      try {
        await firestore.collection('songs').doc(songId).update({
          'playCount': FieldValue.increment(1),
        });
      } catch (e) {
        debugPrint('SongRepository incrementPlayCount error: $e');
      }
    }
  }
}

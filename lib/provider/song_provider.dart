import 'dart:async';
import 'package:flutter/material.dart';
import 'package:retro_vibes/model/song.dart';
import 'package:retro_vibes/repositories/song_repository.dart';

class SongProvider extends ChangeNotifier {
  final SongRepository _songRepository = SongRepository();

  List<Song> _publishedSongs = [];
  List<Song> _featuredSongs = [];
  List<Song> _retroRadioSongs = [];
  List<Song> _searchResults = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = '';

  StreamSubscription<List<Song>>? _publishedSub;
  StreamSubscription<List<Song>>? _featuredSub;
  StreamSubscription<List<Song>>? _retroRadioSub;

  List<Song> get publishedSongs => List.unmodifiable(_publishedSongs);
  List<Song> get featuredSongs => List.unmodifiable(_featuredSongs);
  List<Song> get retroRadioSongs => List.unmodifiable(_retroRadioSongs);
  List<Song> get searchResults => List.unmodifiable(_searchResults);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;

  SongProvider() {
    _initRealtimeStreams();
  }

  /// Subscribe to Firestore real-time streams for live synchronization
  void _initRealtimeStreams() {
    _isLoading = true;
    notifyListeners();

    _publishedSub = _songRepository.getPublishedSongsStream().listen((songs) {
      _publishedSongs = songs;
      _isLoading = false;
      notifyListeners();
    }, onError: (e) {
      debugPrint('SongProvider published stream error: $e');
      _isLoading = false;
      notifyListeners();
    });

    _featuredSub = _songRepository.getFeaturedSongsStream().listen((songs) {
      _featuredSongs = songs;
      notifyListeners();
    }, onError: (e) {
      debugPrint('SongProvider featured stream error: $e');
    });

    _retroRadioSub = _songRepository.getRetroRadioSongsStream().listen((songs) {
      _retroRadioSongs = songs;
      notifyListeners();
    }, onError: (e) {
      debugPrint('SongProvider retro radio stream error: $e');
    });
  }

  Future<void> search(String query) async {
    _searchQuery = query;
    if (query.trim().isEmpty) {
      _searchResults = [];
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      _searchResults = await _songRepository.searchSongs(query);
    } catch (e) {
      debugPrint('SongProvider search error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Stream<List<Song>> getAllSongsStream() {
    return _songRepository.getAllSongsStream();
  }

  Future<void> addSong(Song song) async {
    await _songRepository.addSong(song);
  }

  Future<void> updateSong(Song song) async {
    await _songRepository.updateSong(song);
  }

  Future<void> togglePublish(String songId, bool isPublished) async {
    await _songRepository.togglePublishState(songId, isPublished);
  }

  Future<void> toggleFeatured(String songId, bool isFeatured) async {
    await _songRepository.toggleFeaturedState(songId, isFeatured);
  }

  Future<void> toggleRetroRadio(String songId, bool isRetroRadio) async {
    await _songRepository.toggleRetroRadioState(songId, isRetroRadio);
  }

  Future<void> deleteSong(String songId) async {
    await _songRepository.deleteSong(songId);
  }

  @override
  void dispose() {
    _publishedSub?.cancel();
    _featuredSub?.cancel();
    _retroRadioSub?.cancel();
    super.dispose();
  }
}

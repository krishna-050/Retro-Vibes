import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

class StorageService {
  FirebaseStorage? get _storage {
    try {
      return FirebaseStorage.instance;
    } catch (e) {
      debugPrint('FirebaseStorage instance error: $e');
      return null;
    }
  }

  /// Uploads audio file or bytes to Firebase Storage at `songs/{songId}.mp3`
  Future<String> uploadAudio({
    required String songId,
    File? file,
    Uint8List? bytes,
    Function(double progress)? onProgress,
  }) async {
    final storage = _storage;
    if (storage == null) {
      throw Exception('Firebase Storage is not initialized.');
    }

    try {
      final ref = storage.ref().child('songs/$songId.mp3');
      UploadTask uploadTask;

      if (file != null) {
        uploadTask = ref.putFile(file, SettableMetadata(contentType: 'audio/mpeg'));
      } else if (bytes != null) {
        uploadTask = ref.putData(bytes, SettableMetadata(contentType: 'audio/mpeg'));
      } else {
        throw Exception('Neither File nor Uint8List provided for audio upload');
      }

      if (onProgress != null) {
        uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
          final progress = snapshot.bytesTransferred / (snapshot.totalBytes > 0 ? snapshot.totalBytes : 1);
          onProgress(progress);
        });
      }

      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      debugPrint('StorageService uploadAudio error: $e');
      rethrow;
    }
  }

  /// Uploads cover artwork to Firebase Storage at `covers/{songId}.jpg`
  Future<String> uploadCover({
    required String songId,
    File? file,
    Uint8List? bytes,
    Function(double progress)? onProgress,
  }) async {
    final storage = _storage;
    if (storage == null) {
      throw Exception('Firebase Storage is not initialized.');
    }

    try {
      final ref = storage.ref().child('covers/$songId.jpg');
      UploadTask uploadTask;

      if (file != null) {
        uploadTask = ref.putFile(file, SettableMetadata(contentType: 'image/jpeg'));
      } else if (bytes != null) {
        uploadTask = ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
      } else {
        throw Exception('Neither File nor Uint8List provided for cover upload');
      }

      if (onProgress != null) {
        uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
          final progress = snapshot.bytesTransferred / (snapshot.totalBytes > 0 ? snapshot.totalBytes : 1);
          onProgress(progress);
        });
      }

      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      debugPrint('StorageService uploadCover error: $e');
      rethrow;
    }
  }

  /// Uploads user profile image to Firebase Storage at `profiles/{uid}.jpg`
  Future<String> uploadProfileImage({
    required String uid,
    File? file,
    Uint8List? bytes,
  }) async {
    final storage = _storage;
    if (storage == null) {
      throw Exception('Firebase Storage is not initialized.');
    }

    try {
      final ref = storage.ref().child('profiles/$uid.jpg');
      UploadTask uploadTask;

      if (file != null) {
        uploadTask = ref.putFile(file, SettableMetadata(contentType: 'image/jpeg'));
      } else if (bytes != null) {
        uploadTask = ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
      } else {
        throw Exception('Neither File nor Uint8List provided for profile image upload');
      }

      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      debugPrint('StorageService uploadProfileImage error: $e');
      rethrow;
    }
  }

  /// Deletes user profile image from Firebase Storage at `profiles/{uid}.jpg`
  Future<void> deleteProfileImage(String uid) async {
    final storage = _storage;
    if (storage == null) {
      throw Exception('Firebase Storage is not initialized.');
    }

    try {
      final ref = storage.ref().child('profiles/$uid.jpg');
      await ref.delete();
    } catch (e) {
      debugPrint('StorageService deleteProfileImage error: $e');
      // If the file doesn't exist, it will throw an error, which we can safely ignore
    }
  }
}

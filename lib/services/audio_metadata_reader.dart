import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

class AudioMetadataResult {
  final String? title;
  final String? artist;
  final String? album;
  final String? year;
  final String? genre;
  final String? duration;
  final Uint8List? artworkBytes;
  final String? artworkMimeType;

  AudioMetadataResult({
    this.title,
    this.artist,
    this.album,
    this.year,
    this.genre,
    this.duration,
    this.artworkBytes,
    this.artworkMimeType,
  });
}

class AudioMetadataReader {
  /// Reads available ID3 tags and audio duration from the provided audio bytes / file path
  static Future<AudioMetadataResult> readMetadata({
    Uint8List? bytes,
    String? filePath,
    String? fileName,
  }) async {
    String? title;
    String? artist;
    String? album;
    String? year;
    String? genre;
    String? durationStr;
    Uint8List? artworkBytes;
    String? artworkMimeType;

    // 1. Try reading ID3 v2 tags from audio bytes
    if (bytes != null && bytes.length > 10) {
      try {
        final id3 = _parseId3v2(bytes);
        title = id3['title'] as String?;
        artist = id3['artist'] as String?;
        album = id3['album'] as String?;
        year = id3['year'] as String?;
        genre = id3['genre'] as String?;
        artworkBytes = id3['artworkBytes'] as Uint8List?;
        artworkMimeType = id3['artworkMimeType'] as String?;
      } catch (e) {
        debugPrint('ID3 Tag Parsing Exception: $e');
      }
    }

    // 2. Fallback title from file name if ID3 title not found
    if ((title == null || title.trim().isEmpty) && fileName != null && fileName.isNotEmpty) {
      String clean = fileName;
      final lastDot = clean.lastIndexOf('.');
      if (lastDot > 0) {
        clean = clean.substring(0, lastDot);
      }
      // Replace underscores/hyphens with spaces
      clean = clean.replaceAll('_', ' ').replaceAll('-', ' ').trim();
      if (clean.isNotEmpty) {
        title = _capitalizeWords(clean);
      }
    }

    // 3. Detect Audio Duration using just_audio Player or MP3 frame calculation
    durationStr = await _detectDuration(bytes: bytes, filePath: filePath);

    return AudioMetadataResult(
      title: title?.isNotEmpty == true ? title : null,
      artist: artist?.isNotEmpty == true ? artist : null,
      album: album?.isNotEmpty == true ? album : null,
      year: year?.isNotEmpty == true ? year : null,
      genre: genre?.isNotEmpty == true ? genre : null,
      duration: durationStr,
      artworkBytes: artworkBytes,
      artworkMimeType: artworkMimeType,
    );
  }

  /// Extracts duration formatted as "M:SS"
  static Future<String?> _detectDuration({Uint8List? bytes, String? filePath}) async {
    final player = AudioPlayer();
    try {
      Duration? dur;
      if (kIsWeb && bytes != null && bytes.isNotEmpty) {
        final dataUri = Uri.dataFromBytes(bytes, mimeType: 'audio/mpeg');
        dur = await player.setAudioSource(AudioSource.uri(dataUri)).timeout(const Duration(seconds: 4));
      } else if (filePath != null && filePath.isNotEmpty) {
        dur = await player.setFilePath(filePath).timeout(const Duration(seconds: 4));
      }

      if (dur != null && dur.inSeconds > 0) {
        final minutes = dur.inMinutes;
        final seconds = (dur.inSeconds % 60).toString().padLeft(2, '0');
        return '$minutes:$seconds';
      }
    } catch (e) {
      debugPrint('AudioPlayer duration detection note: $e');
    } finally {
      try {
        await player.dispose();
      } catch (_) {}
    }

    // Fallback MP3 duration estimation based on bitrate / byte size
    if (bytes != null && bytes.length > 1000) {
      try {
        // Average MP3 bitrate 128 kbps (16 KB/sec) or 192 kbps (24 KB/sec)
        final audioSize = bytes.length;
        final estSeconds = (audioSize / (192 * 1000 / 8)).round();
        if (estSeconds > 10 && estSeconds < 3600) {
          final minutes = estSeconds ~/ 60;
          final seconds = (estSeconds % 60).toString().padLeft(2, '0');
          return '$minutes:$seconds';
        }
      } catch (_) {}
    }

    return '3:30'; // Default reasonable duration
  }

  /// Internal ID3v2 Tag Parser (Supports ID3v2.2, ID3v2.3, ID3v2.4)
  static Map<String, dynamic> _parseId3v2(Uint8List bytes) {
    final result = <String, dynamic>{};

    // Check header "ID3"
    if (bytes[0] != 0x49 || bytes[1] != 0x44 || bytes[2] != 0x33) {
      return result;
    }

    final versionMajor = bytes[3]; // 2 = v2.2, 3 = v2.3, 4 = v2.4
    final flags = bytes[5];
    final tagSize = _readSynchsafeInt32(bytes, 6);

    int offset = 10;
    final maxOffset = (10 + tagSize).clamp(0, bytes.length);

    // Skip extended header if present (ID3v2.3 & ID3v2.4)
    if ((flags & 0x40) != 0 && offset + 4 < maxOffset) {
      final extHeaderSize = _readInt32BE(bytes, offset);
      offset += extHeaderSize;
    }

    final isV22 = versionMajor == 2;

    while (offset < maxOffset) {
      final frameIdLength = isV22 ? 3 : 4;
      if (offset + frameIdLength >= maxOffset) break;

      final frameId = String.fromCharCodes(bytes.sublist(offset, offset + frameIdLength));
      if (frameId.codeUnits.every((c) => c == 0)) break; // Padding reached

      offset += frameIdLength;

      int frameSize = 0;
      if (isV22) {
        if (offset + 3 > maxOffset) break;
        frameSize = (bytes[offset] << 16) | (bytes[offset + 1] << 8) | bytes[offset + 2];
        offset += 3;
      } else if (versionMajor == 4) {
        if (offset + 4 > maxOffset) break;
        frameSize = _readSynchsafeInt32(bytes, offset);
        offset += 6; // 4 size bytes + 2 flag bytes
      } else {
        if (offset + 4 > maxOffset) break;
        frameSize = _readInt32BE(bytes, offset);
        offset += 6; // 4 size bytes + 2 flag bytes
      }

      if (frameSize <= 0 || offset + frameSize > maxOffset) break;

      final frameData = bytes.sublist(offset, offset + frameSize);
      offset += frameSize;

      // Extract frame values
      if (frameId == 'TIT2' || frameId == 'TT2') {
        result['title'] = _decodeTextFrame(frameData);
      } else if (frameId == 'TPE1' || frameId == 'TP1') {
        result['artist'] = _decodeTextFrame(frameData);
      } else if (frameId == 'TALB' || frameId == 'TAL') {
        result['album'] = _decodeTextFrame(frameData);
      } else if (frameId == 'TYER' || frameId == 'TDRC' || frameId == 'TYE') {
        result['year'] = _decodeTextFrame(frameData);
      } else if (frameId == 'TCON' || frameId == 'TCO') {
        result['genre'] = _decodeTextFrame(frameData);
      } else if (frameId == 'APIC' || frameId == 'PIC') {
        final apic = _parseApicFrame(frameData, isV22);
        if (apic != null) {
          result['artworkBytes'] = apic['bytes'];
          result['artworkMimeType'] = apic['mime'];
        }
      }
    }

    return result;
  }

  static String _decodeTextFrame(Uint8List frameData) {
    if (frameData.isEmpty) return '';
    final encoding = frameData[0];
    final payload = frameData.sublist(1);

    try {
      if (encoding == 1 || encoding == 2) {
        // UTF-16
        final codeUnits = _uint8ToUint16(payload);
        String str = String.fromCharCodes(codeUnits);
        return str.replaceAll('\x00', '').trim();
      } else if (encoding == 3) {
        // UTF-8
        String str = utf8.decode(payload, allowMalformed: true);
        return str.replaceAll('\x00', '').trim();
      } else {
        // ISO-8859-1 (Latin1)
        String str = latin1.decode(payload);
        return str.replaceAll('\x00', '').trim();
      }
    } catch (_) {
      return String.fromCharCodes(payload).replaceAll('\x00', '').trim();
    }
  }

  static Map<String, dynamic>? _parseApicFrame(Uint8List frameData, bool isV22) {
    if (frameData.length < 5) return null;

    int idx = 1; // Skip encoding byte
    String mime = 'image/jpeg';

    if (isV22) {
      // 3 bytes format e.g. "JPG" or "PNG"
      if (idx + 3 < frameData.length) {
        final fmt = String.fromCharCodes(frameData.sublist(idx, idx + 3)).toUpperCase();
        if (fmt == 'PNG') mime = 'image/png';
        idx += 3;
      }
    } else {
      // Null terminated MIME string
      final mimeStart = idx;
      while (idx < frameData.length && frameData[idx] != 0) {
        idx++;
      }
      if (idx > mimeStart) {
        mime = String.fromCharCodes(frameData.sublist(mimeStart, idx));
      }
      idx++; // Skip null terminator
    }

    if (idx < frameData.length) {
      idx++; // Skip picture type byte (e.g. 0x03)
    }

    // Skip description string
    while (idx < frameData.length && frameData[idx] != 0) {
      idx++;
    }
    idx++; // Skip null byte

    if (idx < frameData.length) {
      final imgBytes = frameData.sublist(idx);
      if (imgBytes.isNotEmpty) {
        return {'bytes': imgBytes, 'mime': mime};
      }
    }

    return null;
  }

  static List<int> _uint8ToUint16(Uint8List list) {
    final result = <int>[];
    if (list.length >= 2 && list[0] == 0xFF && list[1] == 0xFE) {
      // Little endian UTF-16LE with BOM
      for (int i = 2; i < list.length - 1; i += 2) {
        final val = list[i] | (list[i + 1] << 8);
        if (val != 0) result.add(val);
      }
    } else {
      // Big endian UTF-16BE (default or 0xFE 0xFF BOM)
      int start = 0;
      if (list.length >= 2 && list[0] == 0xFE && list[1] == 0xFF) {
        start = 2;
      }
      for (int i = start; i < list.length - 1; i += 2) {
        final val = (list[i] << 8) | list[i + 1];
        if (val != 0) result.add(val);
      }
    }
    return result;
  }

  static int _readSynchsafeInt32(Uint8List bytes, int offset) {
    return (bytes[offset] << 21) |
        (bytes[offset + 1] << 14) |
        (bytes[offset + 2] << 7) |
        bytes[offset + 3];
  }

  static int _readInt32BE(Uint8List bytes, int offset) {
    return (bytes[offset] << 24) |
        (bytes[offset + 1] << 16) |
        (bytes[offset + 2] << 8) |
        bytes[offset + 3];
  }

  static String _capitalizeWords(String text) {
    return text.split(' ').map((word) {
      if (word.isEmpty) return '';
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }
}

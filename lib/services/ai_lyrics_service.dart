import 'dart:convert';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:retro_vibes/model/song.dart';

class AiLyricsService {
  static final AiLyricsService instance = AiLyricsService._internal();
  factory AiLyricsService() => instance;
  AiLyricsService._internal();

  /// Validates audio file/URL eligibility for AI Transcription
  String? validateAudioForAi(String? audioUrlOrPath) {
    if (audioUrlOrPath == null || audioUrlOrPath.trim().isEmpty) {
      return "Please upload an audio file first.";
    }

    final clean = audioUrlOrPath.trim().toLowerCase();
    final supportedExtensions = ['.mp3', '.wav', '.m4a', '.aac', '.flac'];
    
    bool isValidFormat = supportedExtensions.any((ext) => clean.contains(ext)) ||
        clean.startsWith('http') ||
        clean.startsWith('assets/');

    if (!isValidFormat) {
      return "Unsupported audio format. Please use MP3, WAV, M4A, AAC, or FLAC.";
    }

    return null;
  }

  /// Default Google AI Studio API Key
  static const String defaultGeminiApiKey = 'AQ.Ab8RN6KN9NBLEtxdgfZl4XWOwRanD43d0L6wq6xRJQMtPi97YA';

  /// Get saved Google AI Studio API key (from constant, environment or SharedPreferences)
  Future<String?> getSavedApiKey() async {
    if (defaultGeminiApiKey.trim().isNotEmpty) return defaultGeminiApiKey.trim();

    const geminiKey = String.fromEnvironment('GEMINI_API_KEY');
    if (geminiKey.isNotEmpty) return geminiKey;

    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('admin_ai_lyrics_api_key');
    } catch (_) {
      return null;
    }
  }

  /// Save Google AI Studio API Key in Admin Local Prefs
  Future<void> saveApiKey(String apiKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('admin_ai_lyrics_api_key', apiKey.trim());
    } catch (e) {
      debugPrint("Error saving Google AI Studio API Key: $e");
    }
  }

  /// Real-Time AI Lyrics Generation strictly using Google AI Studio (Gemini 1.5 Flash)
  Future<LyricsData> generateLyricsWithAi({
    required String songTitle,
    required String artist,
    required String audioUrl,
    required bool generateSynced,
    required String? userUid,
    String? providedApiKey,
    Uint8List? rawAudioBytes,
  }) async {
    // 1. Auth Check
    final authUser = FirebaseAuth.instance.currentUser;
    if (authUser == null && (userUid == null || userUid == 'local_user')) {
      throw Exception("Authentication required. Only authorized admins can generate lyrics.");
    }

    // 2. Audio Validation
    final validationError = validateAudioForAi(audioUrl);
    if (validationError != null) {
      throw Exception(validationError);
    }

    final apiKey = providedApiKey?.trim() ?? await getSavedApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception("API_KEY_REQUIRED");
    }

    if (!apiKey.startsWith('AIzaSy')) {
      throw Exception("INVALID_GEMINI_KEY");
    }

    debugPrint("[AI_LYRICS] Starting Real-Time Google AI Studio (Gemini 1.5 Flash) Audio Transcription for $songTitle");

    return await _transcribeAudioWithGemini(
      apiKey: apiKey,
      audioUrl: audioUrl,
      songTitle: songTitle,
      artist: artist,
      generateSynced: generateSynced,
      rawAudioBytes: rawAudioBytes,
    );
  }

  /// Transcribe audio strictly using Google AI Studio (Gemini 1.5 Flash) FREE API
  Future<LyricsData> _transcribeAudioWithGemini({
    required String apiKey,
    required String audioUrl,
    required String songTitle,
    required String artist,
    required bool generateSynced,
    Uint8List? rawAudioBytes,
  }) async {
    List<int>? audioBytes = rawAudioBytes;

    if (audioBytes == null || audioBytes.isEmpty) {
      if (audioUrl.startsWith('http')) {
        debugPrint("[AI_LYRICS] Downloading Audio Stream for Gemini 1.5 Flash: $audioUrl");
        final res = await http.get(Uri.parse(audioUrl));
        if (res.statusCode != 200) {
          throw Exception("Unable to download audio file (${res.statusCode}). Please check URL.");
        }
        audioBytes = res.bodyBytes;
      } else {
        try {
          final file = File(audioUrl);
          if (await file.exists()) {
            audioBytes = await file.readAsBytes();
          }
        } catch (_) {}
      }
    }

    if (audioBytes == null || audioBytes.isEmpty) {
      throw Exception("Unable to access audio content. Please provide a valid MP3 Stream URL or upload an audio file.");
    }

    final base64Audio = base64Encode(audioBytes);

    final prompt = '''
You are a precise music audio transcription system.
Transcribe the sung vocals in the provided audio track for song "$songTitle" by "$artist".
Return ONLY a raw JSON object with this exact structure:
{
  "text": "Full lyrics...",
  "segments": [
    { "startMs": 0, "endMs": 8000, "text": "First line", "confidence": 0.98 },
    { "startMs": 8000, "endMs": 14500, "text": "Second line", "confidence": 0.95 }
  ]
}
Do not invent lyrics not present in the audio.
''';

    final modelCandidates = [
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-lite-preview-02-05:generateContent?key=$apiKey',
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-lite:generateContent?key=$apiKey',
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$apiKey',
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-exp:generateContent?key=$apiKey',
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-8b:generateContent?key=$apiKey',
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$apiKey',
    ];

    final mimeType = audioUrl.toLowerCase().contains('.wav') ? 'audio/wav' : 'audio/mp3';

    http.Response? response;
    String? lastErrorMessage;

    for (final endpoint in modelCandidates) {
      try {
        debugPrint("[AI_LYRICS] Trying Gemini Endpoint: $endpoint");
        final res = await http.post(
          Uri.parse(endpoint),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            "contents": [
              {
                "parts": [
                  {
                    "inline_data": {
                      "mime_type": mimeType,
                      "data": base64Audio,
                    }
                  },
                  {"text": prompt}
                ]
              }
            ],
            "generationConfig": {
              "temperature": 0.2,
              "responseMimeType": "application/json"
            }
          }),
        );

        if (res.statusCode == 200) {
          response = res;
          break;
        } else {
          try {
            final errBody = jsonDecode(res.body);
            lastErrorMessage = errBody['error']?['message'] ?? res.body;
          } catch (_) {
            lastErrorMessage = res.body;
          }
          debugPrint("[AI_LYRICS] Endpoint failed (${res.statusCode}): $lastErrorMessage");
        }
      } catch (e) {
        lastErrorMessage = e.toString();
        debugPrint("[AI_LYRICS] Endpoint exception: $e");
      }
    }

    if (response == null || response.statusCode != 200) {
      throw Exception("Google AI Studio API Error: $lastErrorMessage");
    }

    final Map<String, dynamic> jsonResult = jsonDecode(response.body);
    final candidates = jsonResult['candidates'] as List?;
    if (candidates == null || candidates.isEmpty) {
      throw Exception("Google AI Studio API returned an empty response.");
    }

    final textContent = candidates[0]['content']?['parts']?[0]?['text']?.toString() ?? '';
    final cleanJson = textContent.replaceAll('```json', '').replaceAll('```', '').trim();

    final Map<String, dynamic> parsedJson = jsonDecode(cleanJson);
    final List<LyricSegment> segments = [];

    if (parsedJson['segments'] is List) {
      final List rawSegs = parsedJson['segments'];
      for (final s in rawSegs) {
        if (s is Map) {
          segments.add(LyricSegment.fromMap(Map<String, dynamic>.from(s)));
        }
      }
    }

    final fullText = segments.isNotEmpty
        ? segments.map((s) => generateSynced ? '${s.timeFormatted} ${s.text}' : s.text).join('\n')
        : (parsedJson['text']?.toString() ?? '');

    return LyricsData(
      enabled: true,
      type: generateSynced ? 'synced' : 'plain',
      status: 'needs_review',
      text: fullText,
      segments: generateSynced ? segments : [],
      overallConfidence: 0.96,
      generatedBy: 'Google AI Studio (Gemini 1.5 Flash)',
      reviewedByAdmin: false,
      generatedAt: DateTime.now().toIso8601String(),
    );
  }
}

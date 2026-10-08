import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class OtpSession {
  final String email;
  final String otpHash;
  final DateTime createdAt;
  final DateTime expiresAt;
  int attemptsCount;

  OtpSession({
    required this.email,
    required this.otpHash,
    required this.createdAt,
    required this.expiresAt,
    this.attemptsCount = 0,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

class OtpService {
  static final OtpService instance = OtpService._internal();
  factory OtpService() => instance;
  OtpService._internal();

  final Map<String, OtpSession> _localOtpStore = {};
  final Map<String, DateTime> _lastResendTimes = {};

  /// Validate email format
  String? validateEmail(String? email) {
    if (email == null || email.trim().isEmpty) {
      return 'Please enter your email address.';
    }
    final clean = email.trim();
    final emailRegex = RegExp(r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9]+\.[a-zA-Z]+");
    if (!emailRegex.hasMatch(clean) || !clean.contains('.')) {
      return 'Please enter a valid, existing email address (e.g. user@gmail.com).';
    }
    return null;
  }

  /// Mask email address for display (e.g. k****@gmail.com)
  String maskEmail(String email) {
    final clean = email.trim().toLowerCase();
    final parts = clean.split('@');
    if (parts.length != 2) return clean;

    final name = parts[0];
    final domain = parts[1];

    if (name.length <= 2) {
      return '${name[0]}*@$domain';
    } else {
      final first = name[0];
      final last = name[name.length - 1];
      final masked = '*' * (name.length - 2);
      return '$first$masked$last@$domain';
    }
  }

  /// Check whether an email is already registered in Firestore users collection
  Future<bool> checkEmailRegistered(String email) async {
    final clean = email.trim().toLowerCase();
    try {
      final query = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: clean)
          .limit(1)
          .get();
      return query.docs.isNotEmpty;
    } catch (e) {
      debugPrint("[RETRO_OTP] checkEmailRegistered note: $e");
      return false;
    }
  }

  /// Check resend cooldown (60 seconds)
  int getResendCooldownRemaining(String email) {
    final clean = email.trim().toLowerCase();
    final lastTime = _lastResendTimes[clean];
    if (lastTime == null) return 0;
    final elapsed = DateTime.now().difference(lastTime).inSeconds;
    final remaining = 60 - elapsed;
    return remaining > 0 ? remaining : 0;
  }

  /// Generate & Send 4-Digit OTP to Email via EmailJS
  Future<void> sendOtpToEmail(String email, {String? userName}) async {
    final cleanEmail = email.trim().toLowerCase();
    final name = (userName != null && userName.trim().isNotEmpty) ? userName.trim() : cleanEmail.split('@').first;

    // 1. Check Resend Cooldown (60 seconds)
    final cooldown = getResendCooldownRemaining(cleanEmail);
    if (cooldown > 0) {
      throw Exception('Please wait $cooldown seconds before requesting a new OTP.');
    }

    // 2. Generate secure 4-digit OTP (1000 - 9999)
    final random = Random.secure();
    final otpInt = 1000 + random.nextInt(9000);
    final otpStr = otpInt.toString();

    final now = DateTime.now();
    final expiresAt = now.add(const Duration(minutes: 5));

    // Store in local memory session & Firestore backup
    _localOtpStore[cleanEmail] = OtpSession(
      email: cleanEmail,
      otpHash: otpStr,
      createdAt: now,
      expiresAt: expiresAt,
      attemptsCount: 0,
    );
    _lastResendTimes[cleanEmail] = now;

    debugPrint("[RETRO_OTP] Generated 4-Digit OTP for $cleanEmail (Expires at $expiresAt)");

    // 3. Store OTP Request in Cloud Firestore under `otp_requests/{email}`
    try {
      await FirebaseFirestore.instance.collection('otp_requests').doc(cleanEmail).set({
        'email': cleanEmail,
        'otp': otpStr,
        'createdAt': now.toIso8601String(),
        'expiresAt': expiresAt.toIso8601String(),
        'status': 'pending',
        'attempts': 0,
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint("[RETRO_OTP] Firestore request backup note: $e");
    }

    // 4. Send Email via EmailJS REST API
    await _deliverOtpEmailJs(cleanEmail, name, otpStr);
  }

  /// Deliver Email containing 4-digit OTP using EmailJS REST API
  Future<void> _deliverOtpEmailJs(String email, String name, String otp) async {
    const serviceId = 'service_x12xnk5';
    const templateId = 'template_511mono';
    const publicKey = '7zq_Bwo0zTjjnDHdK';
    const endpoint = 'https://api.emailjs.com/api/v1.0/email/send';

    try {
      final res = await http.post(
        Uri.parse(endpoint),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'service_id': serviceId,
          'template_id': templateId,
          'user_id': publicKey,
          'template_params': {
            'email': email,
            'name': name,
            'otp': otp,
            'user_email': email,
            'to_email': email,
            'to_name': name,
          },
        }),
      );

      debugPrint("[RETRO_EMAILJS] Status: ${res.statusCode} | Body: ${res.body}");

      if (res.statusCode != 200 && res.statusCode != 201) {
        final errText = res.body.isNotEmpty ? res.body : 'Status ${res.statusCode}';
        throw Exception("EmailJS API Error ($errText). Please check EmailJS dashboard settings.");
      }
    } catch (e) {
      debugPrint("[RETRO_EMAILJS_ERROR] Exception: $e");
      final msg = e.toString().replaceAll('Exception: ', '');
      throw Exception(msg);
    }
  }

  /// Verify 4-Digit OTP
  Future<bool> verifyOtp({required String email, required String enteredOtp}) async {
    final cleanEmail = email.trim().toLowerCase();
    final cleanOtp = enteredOtp.trim();

    final session = _localOtpStore[cleanEmail];

    // Check local session or Firestore
    if (session == null) {
      // Check Firestore backup
      try {
        final doc = await FirebaseFirestore.instance.collection('otp_requests').doc(cleanEmail).get();
        if (doc.exists && doc.data() != null) {
          final data = doc.data()!;
          final expiresAt = DateTime.tryParse(data['expiresAt'].toString()) ?? DateTime.now();
          final storedOtp = data['otp']?.toString() ?? '';
          final status = data['status']?.toString();

          if (status == 'verified') {
            throw Exception('This OTP has already been used. Please request a new OTP.');
          }

          if (DateTime.now().isAfter(expiresAt)) {
            throw Exception('OTP has expired. Please tap "Resend OTP".');
          }

          if (storedOtp == cleanOtp) {
            await FirebaseFirestore.instance.collection('otp_requests').doc(cleanEmail).update({
              'status': 'verified',
              'verifiedAt': DateTime.now().toIso8601String(),
            });
            _localOtpStore.remove(cleanEmail);
            return true;
          }
        }
      } catch (e) {
        if (e is Exception && !e.toString().contains('Firestore')) rethrow;
      }

      throw Exception('No active OTP request found for this email. Please request a new OTP.');
    }

    // 1. Check Expiration (5 minutes)
    if (session.isExpired) {
      _localOtpStore.remove(cleanEmail);
      throw Exception('OTP has expired. Please tap "Resend OTP".');
    }

    // 2. Check Rate-Limiting / Max Incorrect Attempts (Max 4 attempts)
    if (session.attemptsCount >= 4) {
      _localOtpStore.remove(cleanEmail);
      throw Exception('Too many incorrect attempts. Please request a new OTP.');
    }

    // 3. Verify OTP Match
    if (session.otpHash != cleanOtp) {
      session.attemptsCount++;
      final remainingAttempts = 4 - session.attemptsCount;
      if (remainingAttempts <= 0) {
        _localOtpStore.remove(cleanEmail);
        throw Exception('Too many incorrect attempts. Please request a new OTP.');
      }
      throw Exception('Invalid OTP. Please try again. ($remainingAttempts attempts remaining)');
    }

    // 4. Success! Immediately invalidate OTP so it cannot be reused
    _localOtpStore.remove(cleanEmail);

    try {
      await FirebaseFirestore.instance.collection('otp_requests').doc(cleanEmail).update({
        'status': 'verified',
        'verifiedAt': DateTime.now().toIso8601String(),
      });
    } catch (_) {}

    return true;
  }
}

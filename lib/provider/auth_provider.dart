import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:retro_vibes/model/user_model.dart';
import 'package:retro_vibes/repositories/auth_repository.dart';
import 'package:retro_vibes/services/app_audio_service.dart';

enum AuthLoadingType { none, email, google, guest }

class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepository = AuthRepository();

  UserModel? _currentUser;
  AuthLoadingType _loadingType = AuthLoadingType.none;
  String? _errorMessage;

  UserModel? get currentUser => _currentUser;
  AuthLoadingType get loadingType => _loadingType;
  bool get isLoading => _loadingType != AuthLoadingType.none;
  bool get isEmailLoading => _loadingType == AuthLoadingType.email;
  bool get isGoogleLoading => _loadingType == AuthLoadingType.google;
  bool get isGuestLoading => _loadingType == AuthLoadingType.guest;

  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;
  bool get isAdmin => _currentUser?.isAdmin ?? false;
  bool get isGuest => _currentUser?.isGuest ?? false;

  AuthProvider() {
    _initUser();
  }

  Future<void> _initUser() async {
    _loadingType = AuthLoadingType.email;
    notifyListeners();

    try {
      final fbUser = _authRepository.currentUser;
      if (fbUser != null) {
        final profile = await _authRepository.getUserProfile(fbUser.uid);
        if (profile != null) {
          _currentUser = profile;
        } else {
          _currentUser = UserModel(
            uid: fbUser.uid,
            name: fbUser.displayName ?? fbUser.email?.split('@').first ?? (fbUser.isAnonymous ? 'Guest Listener' : 'Retro Listener'),
            email: fbUser.email ?? '',
            photoUrl: fbUser.photoURL ?? '',
            isGuest: fbUser.isAnonymous,
            provider: fbUser.isAnonymous ? 'anonymous' : 'email',
          );
        }
      } else {
        final prefs = await SharedPreferences.getInstance();
        final isLoggedIn = prefs.getBool('is_logged_in') ?? false;
        if (isLoggedIn) {
          final email = prefs.getString('user_email') ?? 'user@retrovibes.com';
          final name = prefs.getString('user_name') ?? 'Retro Listener';
          final role = prefs.getString('user_role') ?? 'user';
          final photoUrl = prefs.getString('user_photo') ?? '';
          final provider = prefs.getString('user_provider') ?? 'email';
          final isGuestVal = prefs.getBool('user_is_guest') ?? false;
          final profileImageType = prefs.getString('user_profile_image_type');
          final profileAvatarId = prefs.getString('user_profile_avatar_id');

          _currentUser = UserModel(
            uid: 'local_user',
            name: name,
            email: email,
            role: role,
            photoUrl: photoUrl,
            provider: provider,
            isGuest: isGuestVal,
            profileImageType: profileImageType,
            profileAvatarId: profileAvatarId,
          );
        }
      }
    } catch (e) {
      debugPrint('AuthProvider _initUser error: $e');
    } finally {
      _loadingType = AuthLoadingType.none;
      notifyListeners();
    }
  }

  Future<void> _saveUserToPrefs(UserModel user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_logged_in', true);
      await prefs.setString('user_email', user.email);
      await prefs.setString('user_name', user.name);
      await prefs.setString('user_role', user.role);
      await prefs.setString('user_photo', user.photoUrl);
      await prefs.setString('user_provider', user.provider);
      await prefs.setBool('user_is_guest', user.isGuest);
      if (user.profileImageType != null) {
        await prefs.setString('user_profile_image_type', user.profileImageType!);
      }
      if (user.profileAvatarId != null) {
        await prefs.setString('user_profile_avatar_id', user.profileAvatarId!);
      }
    } catch (e) {
      debugPrint('AuthProvider _saveUserToPrefs error: $e');
    }
  }

  Future<bool> login(String email, String password) async {
    _loadingType = AuthLoadingType.email;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentUser = await _authRepository.login(email: email, password: password);
      await _saveUserToPrefs(_currentUser!);

      _loadingType = AuthLoadingType.none;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('AuthProvider login error: $e');
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _currentUser = null;
      _loadingType = AuthLoadingType.none;
      notifyListeners();
      return false;
    }
  }

  Future<bool> loginWithOtpVerifiedEmail(String email) async {
    _loadingType = AuthLoadingType.email;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentUser = await _authRepository.loginWithOtpVerifiedEmail(email: email);
      await _saveUserToPrefs(_currentUser!);

      _loadingType = AuthLoadingType.none;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('AuthProvider loginWithOtpVerifiedEmail error: $e');
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _currentUser = null;
      _loadingType = AuthLoadingType.none;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signUp({
    required String name,
    required String email,
    required String password,
    String role = 'user',
  }) async {
    _loadingType = AuthLoadingType.email;
    _errorMessage = null;
    notifyListeners();

    try {
      final fbUser = _authRepository.currentUser;
      if (fbUser != null && fbUser.isAnonymous) {
        // Link existing guest account to new email & password
        _currentUser = await _authRepository.linkGuestToEmailPassword(
          email: email,
          password: password,
          name: name,
        );
      } else {
        _currentUser = await _authRepository.signUp(
          name: name,
          email: email,
          password: password,
          role: role,
        );
      }

      await _saveUserToPrefs(_currentUser!);

      _loadingType = AuthLoadingType.none;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('AuthProvider signUp error: $e');
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _currentUser = null;
      _loadingType = AuthLoadingType.none;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
    _loadingType = AuthLoadingType.google;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await _authRepository.signInWithGoogle();
      if (user == null) {
        _loadingType = AuthLoadingType.none;
        notifyListeners();
        return false;
      }

      _currentUser = user;
      await _saveUserToPrefs(_currentUser!);

      _loadingType = AuthLoadingType.none;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('AuthProvider signInWithGoogle error: $e');
      final errorStr = e.toString().toLowerCase();

      if (errorStr.contains('network') || errorStr.contains('connection')) {
        _errorMessage = 'Network error. Please check your internet connection.';
      } else if (errorStr.contains('canceled') || errorStr.contains('cancelled')) {
        _errorMessage = null;
      } else {
        _errorMessage = 'Unable to sign in with Google. Please try again.';
      }

      _currentUser = null;
      _loadingType = AuthLoadingType.none;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signInAnonymously() async {
    _loadingType = AuthLoadingType.guest;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentUser = await _authRepository.signInAnonymously();
      await _saveUserToPrefs(_currentUser!);

      _loadingType = AuthLoadingType.none;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('AuthProvider signInAnonymously error: $e');
      _errorMessage = 'Unable to continue as Guest. Please try again.';
      _currentUser = null;
      _loadingType = AuthLoadingType.none;
      notifyListeners();
      return false;
    }
  }

  Future<void> sendEmailVerification() async {
    try {
      await _authRepository.sendEmailVerification();
    } catch (e) {
      debugPrint("Error sending verification email: $e");
    }
  }

  Future<bool> checkEmailVerified() async {
    try {
      return await _authRepository.checkEmailVerified();
    } catch (e) {
      debugPrint("Error checking email verification: $e");
      return false;
    }
  }

  Future<bool> sendPasswordReset(String email) async {
    _loadingType = AuthLoadingType.email;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authRepository.sendPasswordReset(email);
      _loadingType = AuthLoadingType.none;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _loadingType = AuthLoadingType.none;
      notifyListeners();
      return false;
    }
  }

  Future<void> updateProfileName(String name) async {
    if (_currentUser == null) return;
    try {
      await _authRepository.updateProfileName(uid: _currentUser!.uid, name: name);
      _currentUser = UserModel(
        uid: _currentUser!.uid,
        name: name,
        email: _currentUser!.email,
        photoUrl: _currentUser!.photoUrl,
        provider: _currentUser!.provider,
        isGuest: _currentUser!.isGuest,
        profileImageType: _currentUser!.profileImageType,
        profileAvatarId: _currentUser!.profileAvatarId,
        role: _currentUser!.role,
        createdAt: _currentUser!.createdAt,
        lastLoginAt: _currentUser!.lastLoginAt,
        updatedAt: DateTime.now(),
        isActive: _currentUser!.isActive,
      );
      await _saveUserToPrefs(_currentUser!);
      notifyListeners();
    } catch (e) {
      debugPrint('AuthProvider updateProfileName error: $e');
      rethrow;
    }
  }

  Future<void> updateProfileImageInfo({
    required String uid,
    required String photoUrl,
    required String? profileImageType,
    required String? profileAvatarId,
  }) async {
    try {
      await _authRepository.updateProfileImageInfo(
        uid: uid,
        photoUrl: photoUrl,
        profileImageType: profileImageType,
        profileAvatarId: profileAvatarId,
      );
      if (_currentUser != null && _currentUser!.uid == uid) {
        _currentUser = UserModel(
          uid: _currentUser!.uid,
          name: _currentUser!.name,
          email: _currentUser!.email,
          role: _currentUser!.role,
          photoUrl: photoUrl,
          provider: _currentUser!.provider,
          isGuest: _currentUser!.isGuest,
          profileImageType: profileImageType,
          profileAvatarId: profileAvatarId,
          createdAt: _currentUser!.createdAt,
          lastLoginAt: _currentUser!.lastLoginAt,
          updatedAt: DateTime.now(),
          isActive: _currentUser!.isActive,
        );
        await _saveUserToPrefs(_currentUser!);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('AuthProvider updateProfileImageInfo error: $e');
      rethrow;
    }
  }

  Future<bool> deleteAccount() async {
    _loadingType = AuthLoadingType.email;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authRepository.deleteAccount();
      await logout();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _loadingType = AuthLoadingType.none;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _loadingType = AuthLoadingType.none;
    notifyListeners();

    try {
      await AppAudioService.instance.audioPlayer.stop();
      AppAudioService.instance.currentSong = null;
    } catch (e) {
      debugPrint('Logout audio stop note: $e');
    }

    try {
      await _authRepository.logout();
    } catch (_) {}

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('is_logged_in');
    await prefs.remove('user_email');
    await prefs.remove('user_name');
    await prefs.remove('user_role');
    await prefs.remove('user_photo');
    await prefs.remove('user_provider');
    await prefs.remove('user_is_guest');
    await prefs.remove('user_profile_image_type');
    await prefs.remove('user_profile_avatar_id');

    _currentUser = null;
    _loadingType = AuthLoadingType.none;
    notifyListeners();
  }
}

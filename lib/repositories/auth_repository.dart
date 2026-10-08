import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:retro_vibes/model/user_model.dart';

class AuthRepository {
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  FirebaseAuth? get _auth {
    try {
      return FirebaseAuth.instance;
    } catch (e) {
      debugPrint('FirebaseAuth instance error: $e');
      return null;
    }
  }

  FirebaseFirestore? get _firestore {
    try {
      return FirebaseFirestore.instance;
    } catch (e) {
      debugPrint('FirebaseFirestore instance error: $e');
      return null;
    }
  }

  // Stream of auth changes
  Stream<User?> get authStateChanges {
    try {
      return _auth?.authStateChanges() ?? const Stream.empty();
    } catch (_) {
      return const Stream.empty();
    }
  }

  User? get currentUser {
    try {
      return _auth?.currentUser;
    } catch (_) {
      return null;
    }
  }

  /// Fetch user profile document from Firestore `users/{uid}`
  Future<UserModel?> getUserProfile(String uid) async {
    final firestore = _firestore;
    if (firestore == null) return null;

    try {
      final doc = await firestore.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return UserModel.fromMap(doc.data()!, doc.id);
      }
    } catch (e) {
      debugPrint('AuthRepository getUserProfile error: $e');
    }
    return null;
  }

  /// Helper to convert Firebase Auth exceptions to clean human-readable messages
  String _mapFirebaseAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email address.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Invalid email or password. Please try again.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled. Please contact support.';
      case 'email-already-in-use':
        return 'An account already exists with this email address.';
      case 'weak-password':
        return 'The password is too weak. Please enter at least 6 characters.';
      case 'operation-not-allowed':
        return 'This sign-in method is currently disabled.';
      case 'too-many-requests':
        return 'Too many unsuccessful attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network connection error. Please check your internet connection.';
      case 'credential-already-in-use':
        return 'This credential is already linked to another account.';
      default:
        return e.message ?? 'An authentication error occurred. Please try again.';
    }
  }

  /// Login with Email and Password
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    final auth = _auth;
    if (auth == null) {
      final role = email.toLowerCase().contains('admin') ? 'admin' : 'user';
      return UserModel(
        uid: 'local_user_${DateTime.now().millisecondsSinceEpoch}',
        name: email.split('@').first,
        email: email,
        role: role,
        provider: 'email',
        isGuest: false,
      );
    }

    try {
      final credential = await auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user!;
      final uid = user.uid;
      final firestore = _firestore;

      if (firestore != null) {
        await firestore.collection('users').doc(uid).update({
          'lastLoginAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
        }).catchError((_) {});
      }

      final userProfile = await getUserProfile(uid);
      if (userProfile != null) {
        return userProfile;
      }

      final defaultUser = UserModel(
        uid: uid,
        name: user.displayName ?? email.split('@').first,
        email: email,
        role: email.toLowerCase().contains('admin') ? 'admin' : 'user',
        provider: 'email',
        isGuest: false,
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (firestore != null) {
        await firestore.collection('users').doc(uid).set(defaultUser.toMap()).catchError((_) {});
      }
      return defaultUser;
    } on FirebaseAuthException catch (e) {
      debugPrint('AuthRepository login FirebaseAuthException: ${e.code} - ${e.message}');
      throw Exception(_mapFirebaseAuthException(e));
    } catch (e) {
      debugPrint('AuthRepository login error: $e');
      rethrow;
    }
  }

  /// Authenticate/Login user after 4-digit OTP verification
  Future<UserModel> loginWithOtpVerifiedEmail({required String email}) async {
    final auth = _auth;
    final firestore = _firestore;
    final cleanEmail = email.trim().toLowerCase();

    if (firestore != null) {
      try {
        final query = await firestore
            .collection('users')
            .where('email', isEqualTo: cleanEmail)
            .limit(1)
            .get();

        if (query.docs.isNotEmpty) {
          final doc = query.docs.first;
          final existingUser = UserModel.fromMap(doc.data(), doc.id);

          await firestore.collection('users').doc(doc.id).update({
            'lastLoginAt': DateTime.now().toIso8601String(),
            'updatedAt': DateTime.now().toIso8601String(),
          }).catchError((_) {});

          return existingUser;
        }
      } catch (e) {
        debugPrint('AuthRepository loginWithOtpVerifiedEmail Firestore note: $e');
      }
    }

    if (auth != null) {
      try {
        final user = auth.currentUser;
        if (user != null) {
          final uid = user.uid;
          final userModel = UserModel(
            uid: uid,
            name: cleanEmail.split('@').first,
            email: cleanEmail,
            role: cleanEmail.contains('admin') ? 'admin' : 'user',
            provider: 'otp_email',
            isGuest: false,
            createdAt: DateTime.now(),
            lastLoginAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );

          if (firestore != null) {
            await firestore.collection('users').doc(uid).set(userModel.toMap(), SetOptions(merge: true)).catchError((_) {});
          }
          return userModel;
        }
      } catch (e) {
        debugPrint('AuthRepository loginWithOtpVerifiedEmail Auth note: $e');
      }
    }

    final newUid = 'otp_user_${DateTime.now().millisecondsSinceEpoch}';
    final newUser = UserModel(
      uid: newUid,
      name: cleanEmail.split('@').first,
      email: cleanEmail,
      role: cleanEmail.contains('admin') ? 'admin' : 'user',
      provider: 'otp_email',
      isGuest: false,
      createdAt: DateTime.now(),
      lastLoginAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    if (firestore != null) {
      await firestore.collection('users').doc(newUid).set(newUser.toMap()).catchError((_) {});
    }
    return newUser;
  }

  /// Sign Up with Email and Password
  Future<UserModel> signUp({
    required String name,
    required String email,
    required String password,
    String role = 'user',
  }) async {
    final auth = _auth;
    if (auth == null) {
      return UserModel(
        uid: 'local_user_${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        email: email,
        role: role,
        provider: 'email',
        isGuest: false,
      );
    }

    try {
      final credential = await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user!;
      final uid = user.uid;
      await user.updateDisplayName(name).catchError((_) {});

      // Send Verification Email Link to confirm email actually exists and is owned by user
      try {
        await user.sendEmailVerification();
      } catch (e) {
        debugPrint("Verification email sending note: $e");
      }

      final userModel = UserModel(
        uid: uid,
        name: name,
        email: email,
        role: role,
        provider: 'email',
        isGuest: false,
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final firestore = _firestore;
      if (firestore != null) {
        await firestore.collection('users').doc(uid).set(userModel.toMap()).catchError((_) {});
      }
      return userModel;
    } on FirebaseAuthException catch (e) {
      debugPrint('AuthRepository signUp FirebaseAuthException: ${e.code} - ${e.message}');
      throw Exception(_mapFirebaseAuthException(e));
    } catch (e) {
      debugPrint('AuthRepository signUp error: $e');
      rethrow;
    }
  }

  /// Sign In with Google
  Future<UserModel?> signInWithGoogle() async {
    try {
      try {
        await _googleSignIn.signOut();
      } catch (_) {}

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return null; // User cancelled account picker
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final auth = _auth;
      if (auth != null) {
        final UserCredential userCredential = await auth.signInWithCredential(credential);
        final user = userCredential.user;
        if (user == null) return null;

        final uid = user.uid;
        final firestore = _firestore;

        final String name = user.displayName ?? googleUser.displayName ?? googleUser.email.split('@').first;
        final String email = user.email ?? googleUser.email;
        final String photoUrl = user.photoURL ?? googleUser.photoUrl ?? '';
        final String role = email.toLowerCase().contains('admin') ? 'admin' : 'user';

        final existingProfile = await getUserProfile(uid);

        if (existingProfile != null) {
          final updatedUser = UserModel(
            uid: uid,
            name: existingProfile.name.isNotEmpty ? existingProfile.name : name,
            email: email,
            photoUrl: existingProfile.photoUrl.isNotEmpty ? existingProfile.photoUrl : photoUrl,
            provider: 'google',
            isGuest: false,
            profileImageType: existingProfile.profileImageType,
            profileAvatarId: existingProfile.profileAvatarId,
            role: existingProfile.role,
            createdAt: existingProfile.createdAt ?? DateTime.now(),
            lastLoginAt: DateTime.now(),
            updatedAt: DateTime.now(),
            isActive: true,
          );

          if (firestore != null) {
            await firestore.collection('users').doc(uid).update({
              'lastLoginAt': DateTime.now().toIso8601String(),
              'updatedAt': DateTime.now().toIso8601String(),
              'photoUrl': updatedUser.photoUrl,
              'provider': 'google',
              'isGuest': false,
            }).catchError((_) {});
          }
          return updatedUser;
        } else {
          final newUser = UserModel(
            uid: uid,
            name: name,
            email: email,
            photoUrl: photoUrl,
            provider: 'google',
            isGuest: false,
            role: role,
            createdAt: DateTime.now(),
            lastLoginAt: DateTime.now(),
            updatedAt: DateTime.now(),
            isActive: true,
          );

          if (firestore != null) {
            await firestore.collection('users').doc(uid).set(newUser.toMap()).catchError((_) {});
          }
          return newUser;
        }
      } else {
        final uid = 'google_${googleUser.id}';
        return UserModel(
          uid: uid,
          name: googleUser.displayName ?? googleUser.email.split('@').first,
          email: googleUser.email,
          photoUrl: googleUser.photoUrl ?? '',
          provider: 'google',
          isGuest: false,
          role: googleUser.email.toLowerCase().contains('admin') ? 'admin' : 'user',
          createdAt: DateTime.now(),
          lastLoginAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('AuthRepository signInWithGoogle FirebaseAuthException: ${e.code} - ${e.message}');
      throw Exception(_mapFirebaseAuthException(e));
    } catch (e) {
      debugPrint('AuthRepository signInWithGoogle error: $e');
      rethrow;
    }
  }

  /// Sign In Anonymously (Continue as Guest)
  Future<UserModel> signInAnonymously() async {
    final auth = _auth;
    if (auth == null) {
      final guestId = 'guest_${DateTime.now().millisecondsSinceEpoch}';
      return UserModel(
        uid: guestId,
        name: 'Guest Listener',
        email: '$guestId@retrovibes.com',
        provider: 'anonymous',
        isGuest: true,
        role: 'user',
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }

    try {
      final credential = await auth.signInAnonymously();
      final user = credential.user!;
      final uid = user.uid;
      final firestore = _firestore;

      final existingProfile = await getUserProfile(uid);
      if (existingProfile != null) {
        return existingProfile;
      }

      final guestUser = UserModel(
        uid: uid,
        name: 'Guest Listener',
        email: 'guest_${uid.substring(0, min(6, uid.length))}@retrovibes.com',
        provider: 'anonymous',
        isGuest: true,
        role: 'user',
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (firestore != null) {
        await firestore.collection('users').doc(uid).set(guestUser.toMap()).catchError((_) {});
      }
      return guestUser;
    } on FirebaseAuthException catch (e) {
      debugPrint('AuthRepository signInAnonymously FirebaseAuthException: ${e.code} - ${e.message}');
      throw Exception(_mapFirebaseAuthException(e));
    } catch (e) {
      debugPrint('AuthRepository signInAnonymously error: $e');
      rethrow;
    }
  }

  /// Link Guest account to Email & Password
  Future<UserModel> linkGuestToEmailPassword({
    required String email,
    required String password,
    required String name,
  }) async {
    final auth = _auth;
    final user = auth?.currentUser;

    if (user != null && user.isAnonymous) {
      try {
        final credential = EmailAuthProvider.credential(email: email, password: password);
        final userCredential = await user.linkWithCredential(credential);
        final uid = userCredential.user!.uid;

        await userCredential.user?.updateDisplayName(name).catchError((_) {});

        final updatedUser = UserModel(
          uid: uid,
          name: name,
          email: email,
          provider: 'email',
          isGuest: false,
          role: email.toLowerCase().contains('admin') ? 'admin' : 'user',
          createdAt: DateTime.now(),
          lastLoginAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final firestore = _firestore;
        if (firestore != null) {
          await firestore.collection('users').doc(uid).set(updatedUser.toMap(), SetOptions(merge: true)).catchError((_) {});
        }
        return updatedUser;
      } on FirebaseAuthException catch (e) {
        debugPrint('AuthRepository linkGuestToEmailPassword Exception: ${e.code}');
        throw Exception(_mapFirebaseAuthException(e));
      }
    } else {
      // If not anonymous, proceed with normal sign up
      return signUp(name: name, email: email, password: password);
    }
  }

  /// Send Email Verification Link
  Future<void> sendEmailVerification() async {
    final user = _auth?.currentUser;
    if (user != null) {
      await user.sendEmailVerification();
    }
  }

  /// Check if user has verified their email address
  Future<bool> checkEmailVerified() async {
    final user = _auth?.currentUser;
    if (user != null) {
      await user.reload();
      return _auth?.currentUser?.emailVerified ?? false;
    }
    return false;
  }

  /// Send Password Reset Email
  Future<void> sendPasswordReset(String email) async {
    final auth = _auth;
    if (auth != null) {
      try {
        await auth.sendPasswordResetEmail(email: email);
      } on FirebaseAuthException catch (e) {
        throw Exception(_mapFirebaseAuthException(e));
      }
    }
  }

  /// Update Profile Display Name
  Future<void> updateProfileName({
    required String uid,
    required String name,
  }) async {
    final auth = _auth;
    final user = auth?.currentUser;
    if (user != null && user.uid == uid) {
      await user.updateDisplayName(name).catchError((_) {});
    }

    final firestore = _firestore;
    if (firestore != null) {
      try {
        await firestore.collection('users').doc(uid).update({
          'name': name,
          'updatedAt': DateTime.now().toIso8601String(),
        });
      } catch (e) {
        debugPrint('AuthRepository updateProfileName error: $e');
        rethrow;
      }
    }
  }

  /// Update Profile Image URL and Type
  Future<void> updateProfileImageInfo({
    required String uid,
    required String photoUrl,
    required String? profileImageType,
    required String? profileAvatarId,
  }) async {
    final auth = _auth;
    final user = auth?.currentUser;
    if (user != null && user.uid == uid && photoUrl.isNotEmpty) {
      await user.updatePhotoURL(photoUrl).catchError((_) {});
    }

    final firestore = _firestore;
    if (firestore != null) {
      try {
        await firestore.collection('users').doc(uid).update({
          'photoUrl': photoUrl,
          'profileImageType': profileImageType,
          'profileAvatarId': profileAvatarId,
          'updatedAt': DateTime.now().toIso8601String(),
        });
      } catch (e) {
        debugPrint('AuthRepository updateProfileImageInfo error: $e');
        rethrow;
      }
    }
  }

  /// Delete account permanently from Firestore and Firebase Auth
  Future<void> deleteAccount() async {
    final auth = _auth;
    final user = auth?.currentUser;
    final firestore = _firestore;

    if (user != null) {
      final uid = user.uid;
      if (firestore != null) {
        // Delete user's library document in Firestore
        await firestore.collection('users').doc(uid).collection('user_data').doc('library').delete().catchError((_) {});
        // Delete user's main profile document in Firestore
        await firestore.collection('users').doc(uid).delete().catchError((_) {});
      }
      try {
        await user.delete();
      } on FirebaseAuthException catch (e) {
        if (e.code == 'requires-recent-login') {
          throw Exception('Security notice: Please log out and log in again before deleting your account.');
        }
        throw Exception(_mapFirebaseAuthException(e));
      }
    }
  }

  /// Sign Out
  Future<void> logout() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    final auth = _auth;
    if (auth != null) {
      await auth.signOut();
    }
  }
}

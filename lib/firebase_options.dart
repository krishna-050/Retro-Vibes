import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        return android;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyA1dBliRrDPpugEO4pEkKyXlCLmjK53KkE',
    appId: '1:476478915784:web:04523c914e6e6a17ee8df7',
    messagingSenderId: '476478915784',
    projectId: 'retro-vibes-c52e7',
    authDomain: 'retro-vibes-c52e7.firebaseapp.com',
    storageBucket: 'retro-vibes-c52e7.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyA1dBliRrDPpugEO4pEkKyXlCLmjK53KkE',
    appId: '1:476478915784:android:ce152ad4847aa2970211fd',
    messagingSenderId: '476478915784',
    projectId: 'retro-vibes-c52e7',
    storageBucket: 'retro-vibes-c52e7.firebasestorage.app',
  );
}

// File generated by FlutterFire CLI.
// ignore_for_file: lines_longer_than_80_chars, avoid_classes_with_only_static_members
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyA5ZqL9Csot_0OwxWIzw1tJBvIzSH_C6mE',
    appId: '1:502965915123:web:783670f1a8aacd71249686',
    messagingSenderId: '502965915123',
    projectId: 'consumption-meter',
    authDomain: 'consumption-meter.firebaseapp.com',
    storageBucket: 'consumption-meter.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDtB6axw2y_TqenlBvMotwchVUuMqw-ZaI',
    appId: '1:502965915123:android:f600342d56c10efa249686',
    messagingSenderId: '502965915123',
    projectId: 'consumption-meter',
    storageBucket: 'consumption-meter.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAHumuJqwyuihAo9wYw5BdiqKGPo8ig4XQ',
    appId: '1:502965915123:ios:7605f0429af6fc30249686',
    messagingSenderId: '502965915123',
    projectId: 'consumption-meter',
    storageBucket: 'consumption-meter.appspot.com',
    iosBundleId: 'com.example.consumption',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyAHumuJqwyuihAo9wYw5BdiqKGPo8ig4XQ',
    appId: '1:502965915123:ios:2d1898e3441886dd249686',
    messagingSenderId: '502965915123',
    projectId: 'consumption-meter',
    storageBucket: 'consumption-meter.appspot.com',
    iosBundleId: 'com.example.consumption.RunnerTests',
  );
}

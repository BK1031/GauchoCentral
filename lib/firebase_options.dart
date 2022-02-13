// File generated by FlutterFire CLI.
// ignore_for_file: lines_longer_than_80_chars
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
    // ignore: missing_enum_constant_in_switch
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
    }

    throw UnsupportedError(
      'DefaultFirebaseOptions are not supported for this platform.',
    );
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyD2IHuPuLVX3VbKhIcyEYkgh5OKqe4hP1o',
    appId: '1:464569478608:web:9098a2423fec63483d5dd5',
    messagingSenderId: '464569478608',
    projectId: 'storke-central',
    authDomain: 'storke-central.firebaseapp.com',
    storageBucket: 'storke-central.appspot.com',
    measurementId: 'G-HQ09GV8PLB',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBEuqsM6Mb1ZCxX5PQsIOk_U0fRLV-v_6c',
    appId: '1:464569478608:android:c91ba064d9971d213d5dd5',
    messagingSenderId: '464569478608',
    projectId: 'storke-central',
    storageBucket: 'storke-central.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyD5kW1KDb4twuUAHUUD9gnWy19jsx8_dK4',
    appId: '1:464569478608:ios:615737dc42318e293d5dd5',
    messagingSenderId: '464569478608',
    projectId: 'storke-central',
    storageBucket: 'storke-central.appspot.com',
    androidClientId: '464569478608-msoktm0bpa65m42sglahlq17vuavsusi.apps.googleusercontent.com',
    iosClientId: '464569478608-rlfdordhfuerh2bd28j65ab2m0r7djh1.apps.googleusercontent.com',
    iosBundleId: 'com.example.storkeCentral',
  );
}

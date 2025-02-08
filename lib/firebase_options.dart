// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
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
        return windows;
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
    apiKey: 'AIzaSyBvVJDrp8IDNZ237zXKORC3eQqz__BcpDg',
    appId: '1:237231491580:web:c8a2cef6203efeb7218a79',
    messagingSenderId: '237231491580',
    projectId: 'inoventory-2c550',
    authDomain: 'inoventory-2c550.firebaseapp.com',
    storageBucket: 'inoventory-2c550.firebasestorage.app',
    measurementId: 'G-PNZX98TBXR',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDxG_27qj86fDPc-RjVDIMfvwqQhq9HPGs',
    appId: '1:237231491580:android:3bd09b0bf684ccae218a79',
    messagingSenderId: '237231491580',
    projectId: 'inoventory-2c550',
    storageBucket: 'inoventory-2c550.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCziH7e2fWMS_LB_1RM1LiGX6vM01SIHOk',
    appId: '1:237231491580:ios:79f6d5ea659656a4218a79',
    messagingSenderId: '237231491580',
    projectId: 'inoventory-2c550',
    storageBucket: 'inoventory-2c550.firebasestorage.app',
    iosBundleId: 'com.railabouni.inoventoryUi',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCziH7e2fWMS_LB_1RM1LiGX6vM01SIHOk',
    appId: '1:237231491580:ios:79f6d5ea659656a4218a79',
    messagingSenderId: '237231491580',
    projectId: 'inoventory-2c550',
    storageBucket: 'inoventory-2c550.firebasestorage.app',
    iosBundleId: 'com.railabouni.inoventoryUi',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyBvVJDrp8IDNZ237zXKORC3eQqz__BcpDg',
    appId: '1:237231491580:web:53fd55510c50b542218a79',
    messagingSenderId: '237231491580',
    projectId: 'inoventory-2c550',
    authDomain: 'inoventory-2c550.firebaseapp.com',
    storageBucket: 'inoventory-2c550.firebasestorage.app',
    measurementId: 'G-3ZG1M7CHTC',
  );

}
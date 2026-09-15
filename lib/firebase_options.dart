// Generado manualmente a partir de google-services.json (proyecto harvest-monitoring-7b2ad).
// Solo incluye configuración para Android, que es la plataforma objetivo del APK.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions no ha sido configurado para web.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions no soporta esta plataforma: '
          '$defaultTargetPlatform',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBkdiPNWLq8iBOagYOieKw_geU4AOseOEE',
    appId: '1:914647704295:android:b3d16566e038b019f67842',
    messagingSenderId: '914647704295',
    projectId: 'harvest-monitoring-7b2ad',
    storageBucket: 'harvest-monitoring-7b2ad.firebasestorage.app',
  );
}

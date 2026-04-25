import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final firebaseBootstrapProvider = Provider<FirebaseBootstrap>((ref) {
  throw UnimplementedError('firebaseBootstrapProvider not overridden');
});

class FirebaseBootstrap {
  final bool isReady;
  final Object? error;

  const FirebaseBootstrap._({required this.isReady, this.error});

  static Future<FirebaseBootstrap> init() async {
    try {
      await Firebase.initializeApp();
      return const FirebaseBootstrap._(isReady: true);
    } catch (e) {
      return FirebaseBootstrap._(isReady: false, error: e);
    }
  }
}


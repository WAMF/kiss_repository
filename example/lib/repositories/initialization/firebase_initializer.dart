import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'repository_initializer.dart';
import '../../utils/logger.dart' as logger;

class FirebaseInitializer implements RepositoryInitializer {
  bool _initialized = false;

  @override
  Future<void> init() async {
    if (_initialized) {
      return;
    }

    try {
      // Initialize Firebase
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: 'AIzaSyC_l_test_api_key_for_emulator',
          appId: '1:123456789:web:123456789abcdef',
          messagingSenderId: '123456789',
          projectId: 'kiss-test-project',
        ),
      );
      _initialized = true;
      try {
        firestore.FirebaseFirestore.instance.useFirestoreEmulator('0.0.0.0', 8080);
        logger.log('🔥 Using Firestore emulator at 0.0.0.0:8080');
      } catch (e) {
        logger.log('⚠️ Could not connect to Firestore emulator: $e');
        logger.log('💡 Make sure to run: firebase emulators:start --only firestore');
      }

      logger.log('✅ Firebase initialized successfully');
    } catch (e) {
      logger.log('⚠️ Firebase initialization error: $e');
    }
  }

  @override
  bool get isInitialized => _initialized;
}

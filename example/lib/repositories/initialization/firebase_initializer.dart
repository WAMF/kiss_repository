import 'package:firebase_core/firebase_core.dart';
import 'repository_initializer.dart';

class FirebaseInitializer implements RepositoryInitializer {
  bool _initialized = false;
  String _statusMessage = 'Not initialized';

  @override
  Future<bool> init(Map<String, dynamic>? config) async {
    if (_initialized) {
      _statusMessage = 'Already initialized';
      return true;
    }

    try {
      final projectId = config?['projectId'] as String?;
      await Firebase.initializeApp(
        options: FirebaseOptions(
          apiKey: "demo-api-key",
          authDomain: "${projectId ?? 'demo-project'}.firebaseapp.com",
          projectId: projectId ?? "demo-project",
          storageBucket: "${projectId ?? 'demo-project'}.appspot.com",
          messagingSenderId: "123456789",
          appId: "1:123456789:web:demo-app-id",
        ),
      );
      _initialized = true;
      _statusMessage = 'Firebase initialized successfully';
      return true;
    } catch (e) {
      _statusMessage = 'Failed to initialize Firebase: $e';
      return false;
    }
  }

  @override
  bool get isInitialized => _initialized;

  @override
  String get statusMessage => _statusMessage;
}

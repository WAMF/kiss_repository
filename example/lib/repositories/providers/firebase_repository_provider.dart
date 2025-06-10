import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:firebase_core/firebase_core.dart';
import 'package:kiss_firebase_repository/kiss_firebase_repository.dart';

import '../../models/user.dart';
import '../../utils/logger.dart' as logger;
import '../query_builders/firebase_user_query_builder.dart';
import '../repository_provider.dart';

class FirebaseRepositoryProvider extends RepositoryProvider<User> {
  Repository<User>? _repository;
  bool _firebaseInitialized = false;

  @override
  Future<void> initialize() async {
    if (_repository != null) return;

    if (!_firebaseInitialized) {
      try {
        await Firebase.initializeApp(
          options: const FirebaseOptions(
            apiKey: 'AIzaSyC_l_test_api_key_for_emulator',
            appId: '1:123456789:web:123456789abcdef',
            messagingSenderId: '123456789',
            projectId: 'kiss-test-project',
          ),
        );

        try {
          firestore.FirebaseFirestore.instance.useFirestoreEmulator('0.0.0.0', 8080);
          logger.log('🔥 Using Firestore emulator at 0.0.0.0:8080');
        } catch (e) {
          logger.log('⚠️ Could not connect to Firestore emulator: $e');
          logger.log('💡 Make sure to run: firebase emulators:start --only firestore');
        }

        _firebaseInitialized = true;
        logger.log('✅ Firebase initialized successfully');
      } catch (e) {
        logger.log('⚠️ Firebase initialization error: $e');
        rethrow;
      }
    }

    _repository = RepositoryFirestore<User>(
      path: 'users',
      toFirestore: (user) => {
        'id': user.id,
        'name': user.name,
        'email': user.email,
        'createdAt': user.createdAt,
      },
      fromFirestore: (ref, data) => User(
        id: ref.id,
        name: data['name'] ?? '',
        email: data['email'] ?? '',
        createdAt: data['createdAt'] as DateTime,
      ),
      queryBuilder: FirestoreUserQueryBuilder('users'),
    );
  }

  @override
  Repository<User> get repository {
    if (_repository == null) {
      throw StateError('Repository not initialized. Call initialize() first.');
    }
    return _repository!;
  }

  @override
  bool get isInitialized => _repository != null;

  @override
  void dispose() {
    _repository?.dispose();
    _repository = null;
  }
}

import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:firebase_core/firebase_core.dart';
import 'package:kiss_firebase_repository/kiss_firebase_repository.dart';

import '../../models/product_model.dart';
import '../../utils/logger.dart' as logger;
import '../query_builders/firebase_product_query_builder.dart';
import '../repository_provider.dart';

class FirebaseRepositoryProvider implements RepositoryProvider<ProductModel> {
  Repository<ProductModel>? _repository;
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

    _repository = RepositoryFirestore<ProductModel>(
      path: 'products',
      toFirestore: (product) => {
        'id': product.id,
        'name': product.name,
        'price': product.price,
        'description': product.description,
        'created': product.created,
      },
      fromFirestore: (ref, data) => ProductModel(
        id: ref.id,
        name: data['name'] ?? '',
        price: (data['price'] ?? 0.0).toDouble(),
        description: data['description'] ?? '',
        created: data['created'] as DateTime,
      ),
      queryBuilder: FirestoreProductQueryBuilder('products'),
    );
  }

  @override
  Repository<ProductModel> get repository {
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

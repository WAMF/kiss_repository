import 'package:kiss_dependencies/kiss_dependencies.dart';

import 'models/product_model.dart';
import 'repositories/providers/firebase_repository_provider.dart';
import 'repositories/providers/inmemory_repository_provider.dart';
import 'repositories/providers/pocketbase_repository_provider.dart';
import 'repositories/repository_provider.dart';

class Dependencies {
  static bool _isInitialized = false;

  static Future<void> init() async {
    if (_isInitialized) return;

    registerLazy<RepositoryProvider<ProductModel>>(
      () => FirebaseRepositoryProvider(),
      identifier: 'firebase_product_provider',
    );

    registerLazy<RepositoryProvider<ProductModel>>(
      () => InMemoryRepositoryProvider(),
      identifier: 'inmemory_product_provider',
    );

    registerLazy<RepositoryProvider<ProductModel>>(
      () => PocketBaseRepositoryProvider(),
      identifier: 'pocketbase_product_provider',
    );

    _isInitialized = true;
  }
}

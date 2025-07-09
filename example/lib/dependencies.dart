import 'package:example/models/product_model.dart';
import 'package:example/repositories/providers/firebase_repository_provider.dart';
import 'package:example/repositories/providers/inmemory_repository_provider.dart';
import 'package:example/repositories/providers/pocketbase_repository_provider.dart';
import 'package:example/repositories/repository_provider.dart';
import 'package:kiss_dependencies/kiss_dependencies.dart';

class Dependencies {
  static bool _isInitialized = false;

  static Future<void> init() async {
    if (_isInitialized) return;

    registerLazy<RepositoryProvider<ProductModel>>(
      FirebaseRepositoryProvider.new,
      identifier: 'firebase_product_provider',
    );

    registerLazy<RepositoryProvider<ProductModel>>(
      InMemoryRepositoryProvider.new,
      identifier: 'inmemory_product_provider',
    );

    registerLazy<RepositoryProvider<ProductModel>>(
      PocketBaseRepositoryProvider.new,
      identifier: 'pocketbase_product_provider',
    );

    _isInitialized = true;
  }
}

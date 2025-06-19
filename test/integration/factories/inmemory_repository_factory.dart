// ignore_for_file: avoid_print

import 'package:kiss_repository/kiss_repository.dart';
import 'package:kiss_repository_tests/kiss_repository_tests.dart';

import 'inmemory_query_builder.dart';

class InMemoryRepositoryFactory implements RepositoryFactory<ProductModel> {
  Repository<ProductModel>? _repository;
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;

    print('✅ InMemory repository initialized');
    _initialized = true;
  }

  @override
  Repository<ProductModel> createRepository() {
    if (!_initialized) {
      throw StateError('Factory not initialized. Call initialize() first.');
    }

    _repository = InMemoryRepository<ProductModel>(
      queryBuilder: InMemoryProductQueryBuilder(),
      path: 'products',
    );
    return _repository!;
  }

  @override
  Future<void> cleanup() async {
    if (_repository == null) {
      print('🧹 Cleanup: No repository to clean');
      return;
    }

    try {
      final allItems = await _repository!.query();
      print('🧹 Cleanup: Found ${allItems.length} items to delete');

      if (allItems.isNotEmpty) {
        // Extract IDs from items - assuming ProductModel has an id field
        final ids = allItems.map((item) => item.id).toList();
        await _repository!.deleteAll(ids);
        print('🧹 Cleanup: Deleted ${ids.length} items successfully');
      } else {
        print('🧹 Cleanup: Repository already empty');
      }
    } catch (e) {
      print('❌ Cleanup failed: $e');
    }
  }

  @override
  void dispose() {
    _repository?.dispose();
    _repository = null;
    _initialized = false;
  }
}

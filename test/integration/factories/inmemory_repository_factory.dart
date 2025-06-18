// ignore_for_file: avoid_print

import 'package:kiss_repository/kiss_repository.dart';
import '../../../../kiss_repository_tests/lib/test.dart';

import 'inmemory_query_builder.dart';

class InMemoryRepositoryFactory implements RepositoryFactory {
  Repository<ProductModel>? _repository;
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;

    // Reset global ID counter for clean tests
    _resetIdCounter();

    print('✅ InMemory repository initialized');
    _initialized = true;
  }

  // Access the private _idCounter from InMemoryRepository via reflection or reset method
  static void _resetIdCounter() {
    // This is a workaround for the global counter - ideally the InMemoryRepository
    // should provide a way to reset its counter, but for now we'll handle cleanup differently
    print('🔄 InMemory ID counter reset');
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
      // Get all items and delete them
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

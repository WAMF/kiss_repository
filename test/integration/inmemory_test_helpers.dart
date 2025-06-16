import 'package:kiss_repository/kiss_repository.dart';

import '../../shared_test_logic/data/product_model.dart';
import 'inmemory_query_builder.dart';

class InMemoryTestHelpers {
  static late InMemoryRepository<ProductModel> repository;

  static Future<void> setupIntegrationTests() async {
    repository = InMemoryRepository<ProductModel>(
      queryBuilder: TestInMemoryProductQueryBuilder(),
      path: 'products',
    );

    print('✅ InMemory repository initialized');
    print('🎯 Integration tests ready to run');
  }

  static Future<void> tearDownIntegrationTests() async {
    try {
      repository.dispose();
      print('✅ Integration test cleanup completed');
    } catch (e) {
      print('ℹ️ Cleanup error (may be harmless): $e');
    }
  }

  static Future<void> clearTestCollection() async {
    try {
      // Get all items and delete them
      final allItems = await repository.query();
      final ids = allItems.map((item) => item.id).toList();

      if (ids.isNotEmpty) {
        await repository.deleteAll(ids);
        print('🧹 Cleared ${ids.length} test records');
      }
    } catch (e) {
      print('ℹ️ Collection clear: $e');
    }
  }
}

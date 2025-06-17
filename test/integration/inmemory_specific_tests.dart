import 'package:test/test.dart';

import '../../shared_test_logic/data/product_model.dart';
import 'inmemory_test_helpers.dart';

void main() {
  setUpAll(() async {
    await InMemoryTestHelpers.setupIntegrationTests();
  });

  tearDownAll(() async {
    await InMemoryTestHelpers.tearDownIntegrationTests();
  });

  setUp(() async {
    await InMemoryTestHelpers.clearTestCollection();
  });

  group('InMemory-Specific Behavior', () {
    test('addAutoIdentified without updateObjectWithId does not change the object', () async {
      final repository = InMemoryTestHelpers.repository;
      final productModel = ProductModel.create(name: 'ProductX', price: 9.99);

      final addedObject = await repository.addAutoIdentified(productModel);

      expect(addedObject.id, isEmpty);
      expect(addedObject.name, equals('ProductX'));
      expect(addedObject.price, equals(9.99));

      // Note: The object is saved to memory with a client-generated ID,
      // but the returned object maintains the original (empty) ID because
      // no updateObjectWithId function was provided
    });
  });
}

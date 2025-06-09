import 'package:kiss_repository/kiss_repository.dart';

import 'data/product_model.dart';
import 'test_framework.dart';

/// Shared, framework-agnostic test logic for ID management functionality.
void runIdTests({
  required Repository<ProductModel> Function() repositoryFactory,
  required TestFramework framework,
}) {
  framework.group('ID Management & Auto-Generation', () {
    framework.test('should auto-generate IDs with autoIdentify', () async {
      final repository = repositoryFactory();
      final productModel = ProductModel.create(name: 'Auto User', price: 9.99);

      final autoIdentified = repository.autoIdentify(
        productModel,
        updateObjectWithId: (object, generatedId) => object.copyWith(id: generatedId),
      );

      framework.expect(autoIdentified.id, framework.isNotEmpty);
      framework.expect(autoIdentified.object.name, framework.equals('Auto User'));
      framework.expect(autoIdentified.object.id, framework.equals(autoIdentified.id));
      print('✅ Auto-generated ID with autoIdentify');
    });

    framework.test('should add items with auto-generated IDs using addAutoIdentified', () async {
      final repository = repositoryFactory();
      final productModel = ProductModel.create(name: 'Auto Added User', price: 9.99);

      final addedObject = await repository.addAutoIdentified(
        productModel,
        updateObjectWithId: (object, generatedId) => object.copyWith(id: generatedId),
      );

      framework.expect(addedObject.id, framework.isNotEmpty);
      framework.expect(addedObject.name, framework.equals('Auto Added User'));

      final retrieved = await repository.get(addedObject.id);
      framework.expect(retrieved.id, framework.equals(addedObject.id));
      framework.expect(retrieved.name, framework.equals('Auto Added User'));
      print('✅ Added item with auto-generated ID using addAutoIdentified');
    });

    framework.test('should handle multiple auto-generated IDs being unique', () async {
      final repository = repositoryFactory();
      final productModels = List.generate(
        5,
        (i) => ProductModel.create(name: 'User $i', price: 9.99),
      );

      final addedObjects = <ProductModel>[];
      for (final productModel in productModels) {
        final added = await repository.addAutoIdentified(
          productModel,
          updateObjectWithId: (object, generatedId) => object.copyWith(id: generatedId),
        );
        addedObjects.add(added);
      }

      // All IDs should be unique
      final ids = addedObjects.map((obj) => obj.id).toSet();
      framework.expect(ids.length, framework.equals(5));

      // All IDs should be non-empty
      for (final obj in addedObjects) {
        framework.expect(obj.id, framework.isNotEmpty);
      }

      // All objects should be retrievable
      for (final obj in addedObjects) {
        final retrieved = await repository.get(obj.id);
        framework.expect(retrieved.id, framework.equals(obj.id));
        framework.expect(retrieved.name, framework.equals(obj.name));
      }
      print('✅ Generated ${addedObjects.length} unique IDs');
    });

    framework.test('should work with autoIdentify then manual add', () async {
      final repository = repositoryFactory();
      final productModel = ProductModel.create(name: 'Manual Add User', price: 9.99);

      final autoIdentified = repository.autoIdentify(
        productModel,
        updateObjectWithId: (object, id) => object.copyWith(id: id),
      );

      final addedObject = await repository.add(autoIdentified);

      framework.expect(addedObject.id, framework.isNotEmpty);
      framework.expect(addedObject.name, framework.equals('Manual Add User'));

      final retrieved = await repository.get(addedObject.id);
      framework.expect(retrieved.id, framework.equals(addedObject.id));
      framework.expect(retrieved.name, framework.equals('Manual Add User'));
      print('✅ AutoIdentify + manual add workflow worked');
    });

    framework.test('should handle autoIdentify without updateObjectWithId (default behavior)', () async {
      final repository = repositoryFactory();
      final productModel = ProductModel.create(name: 'Default User', price: 9.99).copyWith(id: 'original-id');

      final autoIdentified = repository.autoIdentify(productModel);

      framework.expect(autoIdentified.id, framework.isNotEmpty);
      framework.expect(autoIdentified.id, framework.isNot('original-id'));

      // Object should retain original ID since no updateObjectWithId was provided
      framework.expect(autoIdentified.object.id, framework.equals('original-id'));
      framework.expect(autoIdentified.object.name, framework.equals('Default User'));
      print('✅ AutoIdentify default behavior handled correctly');
    });

    framework.test('should handle autoIdentify in batch operations', () async {
      final repository = repositoryFactory();
      final productModels = [
        ProductModel.create(name: 'Batch Product 1', price: 9.99),
        ProductModel.create(name: 'Batch Product 2', price: 9.99),
      ];

      final identifiedObjects = productModels
          .map((obj) => repository.autoIdentify(
                obj,
                updateObjectWithId: (object, id) => object.copyWith(id: id),
              ))
          .toList();

      final addedObjects = await repository.addAll(identifiedObjects);
      final addedObjectsList = addedObjects.toList();

      framework.expect(addedObjectsList.length, framework.equals(2));

      // Verify all IDs are unique and non-empty
      final ids = identifiedObjects.map((obj) => obj.id).toSet();
      framework.expect(ids.length, framework.equals(2));

      for (final identifiedObj in identifiedObjects) {
        framework.expect(identifiedObj.id, framework.isNotEmpty);
      }

      // Verify objects can be retrieved
      for (int i = 0; i < identifiedObjects.length; i++) {
        final retrieved = await repository.get(identifiedObjects[i].id);
        framework.expect(retrieved.name, framework.equals(productModels[i].name));
      }
      print('✅ AutoIdentify worked in batch operations');
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:kiss_repository/kiss_repository.dart';

import 'data/test_object.dart';

/// Run basic error handling integration tests on any Repository<TestObject> implementation
void runFlutterBasicErrorTests(Repository<TestObject> Function() repositoryFactory) {
  group('Basic Error Handling', () {
    test('should handle concurrent modifications', () async {
      final repository = repositoryFactory();

      final testObject = TestObject.create(name: 'Original', created: DateTime.now());
      final createdObject = await repository.addAutoIdentified(
        testObject,
        updateObjectWithId: (object, id) => object.copyWith(id: id),
      );

      final futures = [
        repository.update(
          createdObject.id,
          (current) => current.copyWith(name: 'Update 1'),
        ),
        repository.update(
          createdObject.id,
          (current) => current.copyWith(name: 'Update 2'),
        ),
        repository.update(
          createdObject.id,
          (current) => current.copyWith(name: 'Update 3'),
        ),
      ];

      final results = await Future.wait(futures);
      expect(results.length, 3);

      final finalObject = await repository.get(createdObject.id);
      expect(['Update 1', 'Update 2', 'Update 3'], contains(finalObject.name));
      print('✅ Handled concurrent modifications successfully');
    });

    test('should handle repository disposal', () async {
      final repository = repositoryFactory();

      final testObject = TestObject.create(name: 'Test Object', created: DateTime.now());
      final createdObject = await repository.addAutoIdentified(
        testObject,
        updateObjectWithId: (object, id) => object.copyWith(id: id),
      );

      repository.dispose();

      // Repository should still work after disposal for most implementations
      final retrieved = await repository.get(createdObject.id);
      expect(retrieved.name, 'Test Object');
      print('✅ Handled repository disposal successfully');
    });

    test('should handle large batch operations', () async {
      final repository = repositoryFactory();

      final objects = List.generate(
        30, // Reduced from 50 to make tests faster
        (i) => TestObject.create(
          name: 'Object $i',
          created: DateTime.now().subtract(Duration(days: i)),
        ),
      );

      // Add all objects using addAutoIdentified
      final createdObjects = <TestObject>[];
      for (final obj in objects) {
        final created = await repository.addAutoIdentified(
          obj,
          updateObjectWithId: (object, id) => object.copyWith(id: id),
        );
        createdObjects.add(created);
      }

      expect(createdObjects.length, 30);

      // Verify some random objects
      final retrieved1 = await repository.get(createdObjects[0].id);
      final retrieved15 = await repository.get(createdObjects[15].id);
      final retrieved29 = await repository.get(createdObjects[29].id);

      expect(retrieved1.name, 'Object 0');
      expect(retrieved15.name, 'Object 15');
      expect(retrieved29.name, 'Object 29');

      // Clean up
      final ids = createdObjects.map((obj) => obj.id).toList();
      await repository.deleteAll(ids);
      print('✅ Handled large batch operations successfully');
    });

    test('should handle operations on deleted documents', () async {
      final repository = repositoryFactory();

      final testObject = TestObject.create(name: 'To Be Deleted', created: DateTime.now());
      final createdObject = await repository.addAutoIdentified(
        testObject,
        updateObjectWithId: (object, id) => object.copyWith(id: id),
      );

      await repository.delete(createdObject.id);

      expect(
        () => repository.get(createdObject.id),
        throwsA(isA<RepositoryException>()),
      );

      expect(
        () => repository.update(createdObject.id, (obj) => obj.copyWith(name: 'Updated')),
        throwsA(isA<RepositoryException>()),
      );

      // Deleting non-existent record behavior may vary by implementation
      // Some throw, others silently succeed
      print('✅ Handled operations on deleted documents correctly');
    });

    test('should handle rapid consecutive operations', () async {
      final repository = repositoryFactory();

      final testObject = TestObject.create(name: 'Rapid Object', created: DateTime.now());
      final createdObject = await repository.addAutoIdentified(
        testObject,
        updateObjectWithId: (object, id) => object.copyWith(id: id),
      );

      for (int i = 0; i < 10; i++) {
        await repository.update(
          createdObject.id,
          (current) => current.copyWith(name: 'Update $i'),
        );
      }

      final finalObject = await repository.get(createdObject.id);
      expect(finalObject.name, 'Update 9');
      print('✅ Handled rapid consecutive operations successfully');
    });

    test('should handle duplicate ID attempts correctly', () async {
      final repository = repositoryFactory();

      final object1 = TestObject.create(name: 'First Object', created: DateTime.now());
      final createdObject1 = await repository.addAutoIdentified(
        object1,
        updateObjectWithId: (object, id) => object.copyWith(id: id),
      );

      final object2 = TestObject.create(name: 'Duplicate Object', created: DateTime.now());

      expect(
        () => repository.add(IdentifiedObject(createdObject1.id, object2.copyWith(id: createdObject1.id))),
        throwsA(isA<RepositoryException>()),
      );

      // Original object should still be retrievable
      final retrieved = await repository.get(createdObject1.id);
      expect(retrieved.name, 'First Object');
      print('✅ Handled duplicate ID attempts correctly');
    });

    test('should handle edge case query results', () async {
      final repository = repositoryFactory();

      // Test with no results
      final emptyResults = await repository.query();
      expect(emptyResults, isEmpty);

      // Add one object and test single result
      final testObject = TestObject.create(name: 'Solo Object', created: DateTime.now());
      final createdObject = await repository.addAutoIdentified(
        testObject,
        updateObjectWithId: (object, id) => object.copyWith(id: id),
      );

      final singleResult = await repository.query();
      expect(singleResult.length, 1);
      expect(singleResult.first.name, 'Solo Object');
      print('✅ Handled edge case query results successfully');
    });

    test('should handle autoIdentify edge cases', () async {
      final repository = repositoryFactory();

      final testObject = TestObject.create(name: 'Auto Object', created: DateTime.now());

      // Test autoIdentify method
      final identified = repository.autoIdentify(
        testObject,
        updateObjectWithId: (object, id) => object.copyWith(id: id),
      );
      expect(identified.id, isNotEmpty); // Should have generated ID

      // Test addAutoIdentified
      final added = await repository.addAutoIdentified(
        testObject,
        updateObjectWithId: (object, id) => object.copyWith(id: id),
      );
      expect(added.name, 'Auto Object');
      expect(added.id, isNotEmpty); // Should have generated ID
      print('✅ Handled autoIdentify edge cases successfully');
    });

    test('should handle get operations on non-existent items', () async {
      final repository = repositoryFactory();

      expect(
        () => repository.get('non_existent_id'),
        throwsA(isA<RepositoryException>()),
      );
      print('✅ Handled get operations on non-existent items correctly');
    });

    test('should handle update operations on non-existent items', () async {
      final repository = repositoryFactory();

      expect(
        () => repository.update(
          'non_existent_id',
          (current) => current.copyWith(name: 'Updated'),
        ),
        throwsA(isA<RepositoryException>()),
      );
      print('✅ Handled update operations on non-existent items correctly');
    });
  });
}

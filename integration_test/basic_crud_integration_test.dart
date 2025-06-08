import 'package:flutter_test/flutter_test.dart';
import 'package:kiss_repository/kiss_repository.dart';

import 'data/test_object.dart';

/// Run basic CRUD integration tests on any Repository<TestObject> implementation
void runFlutterBasicCrudTests(Repository<TestObject> Function() repositoryFactory) {
  group('Basic CRUD Operations', () {
    test('should perform complete CRUD lifecycle', () async {
      // Create test object
      final testObject = TestObject.create(
        name: 'Test Item',
        created: DateTime.now(),
      );

      // CREATE: Add object using auto-identified method
      final repository = repositoryFactory();
      final createdObject = await repository.addAutoIdentified(
        testObject,
        updateObjectWithId: (object, id) => object.copyWith(id: id),
      );
      expect(createdObject.id, isNotEmpty);
      expect(createdObject.name, equals('Test Item'));
      print('✅ Created object: ${createdObject.id}');

      // READ: Get object by ID
      final retrievedObject = await repository.get(createdObject.id);
      expect(retrievedObject.id, equals(createdObject.id));
      expect(retrievedObject.name, equals('Test Item'));
      print('✅ Retrieved object: ${retrievedObject.id}');

      // UPDATE: Modify object
      final savedObject = await repository.update(
        createdObject.id,
        (current) => current.copyWith(name: 'Updated Item'),
      );
      expect(savedObject.name, equals('Updated Item'));
      expect(savedObject.id, equals(createdObject.id)); // ID should remain same
      print('✅ Updated object: ${savedObject.id}');

      // DELETE: Remove object
      await repository.delete(savedObject.id);
      print('✅ Deleted object: ${savedObject.id}');

      // Verify deletion
      expect(
        () => repository.get(savedObject.id),
        throwsA(isA<RepositoryException>()),
      );
      print('✅ Verified deletion');
    });

    test('should handle non-existent records gracefully', () async {
      final repository = repositoryFactory();
      expect(
        () => repository.get('non_existent_id'),
        throwsA(isA<RepositoryException>()),
      );

      expect(
        () => repository.update(
          'non_existent_id',
          (current) => current.copyWith(name: 'Updated'),
        ),
        throwsA(isA<RepositoryException>()),
      );

      expect(
        () => repository.delete('non_existent_id'),
        throwsA(isA<RepositoryException>()),
      );
    });

    test('should handle multiple sequential operations', () async {
      final repository = repositoryFactory();
      final objects = [
        TestObject.create(name: 'Object 1', created: DateTime.now()),
        TestObject.create(name: 'Object 2', created: DateTime.now()),
        TestObject.create(name: 'Object 3', created: DateTime.now()),
      ];

      final createdObjects = <TestObject>[];
      for (final obj in objects) {
        final created = await repository.addAutoIdentified(
          obj,
          updateObjectWithId: (object, id) => object.copyWith(id: id),
        );
        createdObjects.add(created);
        expect(created.id, isNotEmpty);
      }

      print('✅ Created ${createdObjects.length} objects');

      for (final obj in createdObjects) {
        final retrieved = await repository.get(obj.id);
        expect(retrieved.id, equals(obj.id));
      }

      print('✅ Retrieved all objects successfully');

      for (final obj in createdObjects) {
        await repository.delete(obj.id);
      }

      print('✅ Cleaned up all test objects');
    });
  });
}

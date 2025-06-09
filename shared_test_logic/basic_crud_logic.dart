import 'package:kiss_repository/kiss_repository.dart';

import 'data/test_object.dart';
import 'test_framework.dart';

/// Shared, framework-agnostic test logic for basic CRUD operations.
void runBasicCrudLogic({
  required Repository<TestObject> Function() repositoryFactory,
  required TestFramework framework,
}) {
  framework.group('Basic CRUD Operations', () {
    framework.test('should perform complete CRUD lifecycle', () async {
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
      framework.expect(createdObject.id, framework.isNotEmpty);
      framework.expect(createdObject.name, framework.equals('Test Item'));
      print('✅ Created object: ${createdObject.id}');

      // READ: Get object by ID
      final retrievedObject = await repository.get(createdObject.id);
      framework.expect(retrievedObject.id, framework.equals(createdObject.id));
      framework.expect(retrievedObject.name, framework.equals('Test Item'));
      print('✅ Retrieved object: ${retrievedObject.id}');

      // UPDATE: Modify object
      final savedObject = await repository.update(
        createdObject.id,
        (current) => current.copyWith(name: 'Updated Item'),
      );
      framework.expect(savedObject.name, framework.equals('Updated Item'));
      framework.expect(savedObject.id, framework.equals(createdObject.id));
      print('✅ Updated object: ${savedObject.id}');

      // DELETE: Remove object
      await repository.delete(savedObject.id);
      print('✅ Deleted object: ${savedObject.id}');

      // Verify deletion
      framework.expect(
        () => repository.get(savedObject.id),
        framework.throwsA(framework.isA<RepositoryException>()),
      );
      print('✅ Verified deletion');
    });

    framework.test('should handle non-existent records gracefully', () async {
      final repository = repositoryFactory();
      framework.expect(
        () => repository.get('non_existent_id'),
        framework.throwsA(framework.isA<RepositoryException>()),
      );

      framework.expect(
        () => repository.update(
          'non_existent_id',
          (current) => current.copyWith(name: 'Updated'),
        ),
        framework.throwsA(framework.isA<RepositoryException>()),
      );

      framework.expect(
        () => repository.delete('non_existent_id'),
        framework.throwsA(framework.isA<RepositoryException>()),
      );
    });

    framework.test('should handle multiple sequential operations', () async {
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
        framework.expect(created.id, framework.isNotEmpty);
      }

      print('✅ Created ${createdObjects.length} objects');

      for (final obj in createdObjects) {
        final retrieved = await repository.get(obj.id);
        framework.expect(retrieved.id, framework.equals(obj.id));
      }

      print('✅ Retrieved all objects successfully');

      for (final obj in createdObjects) {
        await repository.delete(obj.id);
      }

      print('✅ Cleaned up all test objects');
    });
  });
}

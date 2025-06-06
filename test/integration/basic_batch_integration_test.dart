import 'package:test/test.dart';
import 'package:kiss_repository/kiss_repository.dart';

import '../data/test_object.dart';

/// Run basic batch operations integration tests on any Repository<TestObject> implementation
void runBasicBatchTests(Repository<TestObject> Function() repositoryFactory) {
  group('Basic Batch Operations', () {
    test('should add multiple items with addAll', () async {
      final repository = repositoryFactory();
      final objects = [
        TestObject.create(name: 'Batch Object 1', created: DateTime.now()),
        TestObject.create(name: 'Batch Object 2', created: DateTime.now()),
        TestObject.create(name: 'Batch Object 3', created: DateTime.now()),
      ];

      final identifiedObjects = objects
          .map((obj) => repository.autoIdentify(
                obj,
                updateObjectWithId: (object, id) => object.copyWith(id: id),
              ))
          .toList();

      final addedObjects = await repository.addAll(identifiedObjects);

      final addedObjectsList = addedObjects.toList();

      expect(addedObjectsList.length, 3);
      for (int i = 0; i < objects.length; i++) {
        expect(addedObjectsList[i].id, identifiedObjects[i].id);
        expect(addedObjectsList[i].name, objects[i].name);

        final retrieved = await repository.get(identifiedObjects[i].id);
        expect(retrieved.id, identifiedObjects[i].id);
        expect(retrieved.name, objects[i].name);
      }
      print('✅ Added ${addedObjectsList.length} objects with addAll');
    });

    test('should update multiple items with updateAll', () async {
      final repository = repositoryFactory();
      final objects = [
        TestObject.create(name: 'Update Object 1', created: DateTime.now()),
        TestObject.create(name: 'Update Object 2', created: DateTime.now()),
        TestObject.create(name: 'Update Object 3', created: DateTime.now()),
      ];

      // First add the objects
      final createdObjects = <TestObject>[];
      for (final obj in objects) {
        final created = await repository.addAutoIdentified(
          obj,
          updateObjectWithId: (object, id) => object.copyWith(id: id),
        );
        createdObjects.add(created);
      }

      // Create updated versions
      final updatedObjectsList = createdObjects.map((obj) => obj.copyWith(name: '${obj.name} Updated')).toList();
      final identifiedUpdates = updatedObjectsList.map((obj) => IdentifiedObject(obj.id, obj)).toList();

      final updatedObjects = await repository.updateAll(identifiedUpdates);

      final updatedObjectsResult = updatedObjects.toList();

      expect(updatedObjectsResult.length, 3);
      for (int i = 0; i < createdObjects.length; i++) {
        expect(updatedObjectsResult[i].id, createdObjects[i].id);
        expect(updatedObjectsResult[i].name, '${objects[i].name} Updated');

        final retrieved = await repository.get(createdObjects[i].id);
        expect(retrieved.name, '${objects[i].name} Updated');
      }
      print('✅ Updated ${updatedObjectsResult.length} objects with updateAll');
    });

    test('should delete multiple items with deleteAll', () async {
      final repository = repositoryFactory();
      final objects = [
        TestObject.create(name: 'Delete Object 1', created: DateTime.now()),
        TestObject.create(name: 'Delete Object 2', created: DateTime.now()),
        TestObject.create(name: 'Delete Object 3', created: DateTime.now()),
      ];

      // First add the objects
      final createdObjects = <TestObject>[];
      for (final obj in objects) {
        final created = await repository.addAutoIdentified(
          obj,
          updateObjectWithId: (object, id) => object.copyWith(id: id),
        );
        createdObjects.add(created);
      }

      // Verify they exist first
      for (final obj in createdObjects) {
        final retrieved = await repository.get(obj.id);
        expect(retrieved.id, obj.id);
      }

      final deleteIds = createdObjects.map((obj) => obj.id).toList();
      await repository.deleteAll(deleteIds);

      // Verify deletion
      for (final obj in createdObjects) {
        expect(
          () => repository.get(obj.id),
          throwsA(isA<RepositoryException>()),
        );
      }
      print('✅ Deleted ${deleteIds.length} objects with deleteAll');
    });

    test('should handle empty batch operations', () async {
      final repository = repositoryFactory();

      final emptyAddResult = await repository.addAll(
        <IdentifiedObject<TestObject>>[],
      );
      expect(emptyAddResult, isEmpty);

      final emptyUpdateResult = await repository.updateAll(
        <IdentifiedObject<TestObject>>[],
      );
      expect(emptyUpdateResult, isEmpty);

      await repository.deleteAll(<String>[]);
      print('✅ Handled empty batch operations gracefully');
    });

    test('should handle batch operations with some failures', () async {
      final repository = repositoryFactory();

      // First create an existing object
      final existingObject = TestObject.create(
        name: 'Existing Object',
        created: DateTime.now(),
      );
      final createdExisting = await repository.addAutoIdentified(
        existingObject,
        updateObjectWithId: (object, id) => object.copyWith(id: id),
      );

      // Try to add a batch that includes the existing ID
      final batchObjects = [
        TestObject.create(name: 'New Object 1', created: DateTime.now()),
        createdExisting, // This should cause a failure
        TestObject.create(name: 'New Object 2', created: DateTime.now()),
      ];

      final identifiedBatch = batchObjects.map((obj) => IdentifiedObject(obj.id, obj)).toList();

      expect(
        () => repository.addAll(identifiedBatch),
        throwsA(isA<RepositoryException>()),
      );

      // Verify the original object is still there
      final retrieved = await repository.get(createdExisting.id);
      expect(retrieved.name, 'Existing Object');
      print('✅ Handled batch operations with failures correctly');
    });
  });
}

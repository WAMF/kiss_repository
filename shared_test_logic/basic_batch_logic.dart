import 'package:kiss_repository/kiss_repository.dart';

import 'data/test_object.dart';
import 'test_framework.dart';

/// Shared, framework-agnostic test logic for basic batch operations.
void runBasicBatchLogic({
  required Repository<TestObject> Function() repositoryFactory,
  required TestFramework framework,
}) {
  framework.group('Basic Batch Operations', () {
    framework.test('should add multiple items with addAll', () async {
      final repository = repositoryFactory();
      final objects = [
        TestObject.create(name: 'Batch Object 1'),
        TestObject.create(name: 'Batch Object 2'),
        TestObject.create(name: 'Batch Object 3'),
      ];

      final identifiedObjects = objects
          .map((obj) => repository.autoIdentify(
                obj,
                updateObjectWithId: (object, id) => object.copyWith(id: id),
              ))
          .toList();

      final addedObjects = await repository.addAll(identifiedObjects);
      final addedObjectsList = addedObjects.toList();

      framework.expect(addedObjectsList.length, framework.equals(3));
      for (int i = 0; i < objects.length; i++) {
        framework.expect(addedObjectsList[i].id, framework.equals(identifiedObjects[i].id));
        framework.expect(addedObjectsList[i].name, framework.equals(objects[i].name));

        final retrieved = await repository.get(identifiedObjects[i].id);
        framework.expect(retrieved.id, framework.equals(identifiedObjects[i].id));
        framework.expect(retrieved.name, framework.equals(objects[i].name));
      }
      print('✅ Added ${addedObjectsList.length} objects with addAll');
    });

    framework.test('should update multiple items with updateAll', () async {
      final repository = repositoryFactory();
      final objects = [
        TestObject.create(name: 'Update Object 1'),
        TestObject.create(name: 'Update Object 2'),
        TestObject.create(name: 'Update Object 3'),
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

      framework.expect(updatedObjectsResult.length, framework.equals(3));
      for (int i = 0; i < createdObjects.length; i++) {
        framework.expect(updatedObjectsResult[i].id, framework.equals(createdObjects[i].id));
        framework.expect(updatedObjectsResult[i].name, framework.equals('${objects[i].name} Updated'));

        final retrieved = await repository.get(createdObjects[i].id);
        framework.expect(retrieved.name, framework.equals('${objects[i].name} Updated'));
      }
      print('✅ Updated ${updatedObjectsResult.length} objects with updateAll');
    });

    framework.test('should delete multiple items with deleteAll', () async {
      final repository = repositoryFactory();
      final objects = [
        TestObject.create(name: 'Delete Object 1'),
        TestObject.create(name: 'Delete Object 2'),
        TestObject.create(name: 'Delete Object 3'),
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
        framework.expect(retrieved.id, framework.equals(obj.id));
      }

      final deleteIds = createdObjects.map((obj) => obj.id).toList();
      await repository.deleteAll(deleteIds);

      // Verify deletion
      for (final obj in createdObjects) {
        framework.expect(
          () => repository.get(obj.id),
          framework.throwsA(framework.isA<RepositoryException>()),
        );
      }
      print('✅ Deleted ${deleteIds.length} objects with deleteAll');
    });

    framework.test('should handle empty batch operations', () async {
      final repository = repositoryFactory();
      final emptyAddResult = await repository.addAll(<IdentifiedObject<TestObject>>[]);
      framework.expect(emptyAddResult, framework.isEmpty);

      final emptyUpdateResult = await repository.updateAll(<IdentifiedObject<TestObject>>[]);
      framework.expect(emptyUpdateResult, framework.isEmpty);

      await repository.deleteAll(<String>[]);
      print('✅ Handled empty batch operations gracefully');
    });

    framework.test('should handle batch operations with some failures', () async {
      final repository = repositoryFactory();

      // First create an existing object
      final existingObject = TestObject.create(
        name: 'Existing Object',
      );
      final createdExisting = await repository.addAutoIdentified(
        existingObject,
        updateObjectWithId: (object, id) => object.copyWith(id: id),
      );

      // Try to add a batch that includes the existing ID
      final batchObjects = [
        TestObject.create(name: 'New Object 1'),
        createdExisting, // This should cause a failure
        TestObject.create(name: 'New Object 2'),
      ];

      final identifiedBatch = batchObjects.map((obj) => IdentifiedObject(obj.id, obj)).toList();

      framework.expect(
        () => repository.addAll(identifiedBatch),
        framework.throwsA(framework.isA<RepositoryException>()),
      );

      // Verify the original object is still there
      final retrieved = await repository.get(createdExisting.id);
      framework.expect(retrieved.name, framework.equals('Existing Object'));
      print('✅ Handled batch operations with failures correctly');
    });
  });
}

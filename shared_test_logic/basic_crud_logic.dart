import 'package:kiss_repository/kiss_repository.dart';

import 'data/test_object.dart';
import 'test_framework.dart';

void testCrudLogic({
  required Repository<TestObject> Function() repositoryFactory,
  required TestFramework framework,
}) {
  framework.group('Basic CRUD Operations', () {
    framework.test('should perform complete CRUD lifecycle', () async {
      final repository = repositoryFactory();
      final testObject = TestObject.create(name: 'Test Item');

      // CREATE
      final createdObject = await repository.addAutoIdentified(
        testObject,
        updateObjectWithId: (object, id) => object.copyWith(id: id),
      );
      framework.expect(createdObject.id, framework.isNotEmpty);
      framework.expect(createdObject.name, framework.equals('Test Item'));

      // READ
      final retrievedObject = await repository.get(createdObject.id);
      framework.expect(retrievedObject.id, framework.equals(createdObject.id));
      framework.expect(retrievedObject.name, framework.equals('Test Item'));

      // UPDATE
      final savedObject = await repository.update(
        createdObject.id,
        (current) => current.copyWith(name: 'Updated Item'),
      );
      framework.expect(savedObject.name, framework.equals('Updated Item'));
      framework.expect(savedObject.id, framework.equals(createdObject.id));

      // DELETE
      await repository.delete(savedObject.id);
      framework.expect(
        () => repository.get(savedObject.id),
        framework.throwsA(framework.isA<RepositoryException>()),
      );
    });

    framework.test('should throw exception when getting non-existent record', () async {
      final repository = repositoryFactory();
      framework.expect(
        () => repository.get('non_existent_id'),
        framework.throwsA(framework.isA<RepositoryException>()),
      );
    });

    framework.test('should throw exception when updating non-existent record', () async {
      final repository = repositoryFactory();
      framework.expect(
        () => repository.update(
          'non_existent_id',
          (current) => current.copyWith(name: 'Updated'),
        ),
        framework.throwsA(framework.isA<RepositoryException>()),
      );
    });

    framework.test('should allow deleting non-existent record without error', () async {
      final repository = repositoryFactory();
      // Delete should succeed gracefully for non-existent records
      await repository.delete('non_existent_id');
    });

    framework.test('should handle deleteAll with mix of existing and non-existent IDs', () async {
      final repository = repositoryFactory();

      // Create a test object
      final testObject = TestObject.create(name: 'Test Object');
      final createdObject = await repository.addAutoIdentified(
        testObject,
        updateObjectWithId: (object, id) => object.copyWith(id: id),
      );

      // Delete mix of existing and non-existing IDs - should succeed gracefully
      await repository.deleteAll([
        createdObject.id, // exists
        'non_existent_1', // doesn't exist
        'non_existent_2', // doesn't exist
      ]);

      // Verify the existing object was actually deleted
      framework.expect(
        () => repository.get(createdObject.id),
        framework.throwsA(framework.isA<RepositoryException>()),
      );
    });
  });
}

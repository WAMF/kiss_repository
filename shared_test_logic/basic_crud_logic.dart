import 'package:kiss_repository/kiss_repository.dart';

import 'data/test_object.dart';
import 'test_framework.dart';

void testCrudLogic({
  required Repository<TestObject> Function() repositoryFactory,
  required TestFramework framework,
}) {
  final repository = repositoryFactory();

  framework.group('Basic CRUD Operations', () {
    framework.test('should perform complete CRUD lifecycle', () async {
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
      framework.expect(
        () => repository.get('non_existent_id'),
        framework.throwsA(framework.isA<RepositoryException>()),
      );
    });

    framework.test('should throw exception when updating non-existent record', () async {
      framework.expect(
        () => repository.update(
          'non_existent_id',
          (current) => current.copyWith(name: 'Updated'),
        ),
        framework.throwsA(framework.isA<RepositoryException>()),
      );
    });

    framework.test('should allow deleting non-existent record without error', () async {
      // Delete should succeed gracefully for non-existent records
      await repository.delete('non_existent_id');
    });
  });
}

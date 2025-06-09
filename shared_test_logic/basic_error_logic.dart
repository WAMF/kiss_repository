import 'package:kiss_repository/kiss_repository.dart';

import 'data/test_object.dart';
import 'test_framework.dart';

/// Shared, framework-agnostic test logic for basic error handling.
void runBasicErrorLogic({
  required Repository<TestObject> Function() repositoryFactory,
  required TestFramework framework,
}) {
  framework.group('Basic Error Handling', () {
    framework.test('should handle concurrent modifications', () async {
      final repository = repositoryFactory();
      final testObject = TestObject.create(name: 'Original', created: DateTime.now());
      final createdObject = await repository.addAutoIdentified(
        testObject,
        updateObjectWithId: (object, id) => object.copyWith(id: id),
      );
      final futures = [
        repository.update(createdObject.id, (current) => current.copyWith(name: 'Update 1')),
        repository.update(createdObject.id, (current) => current.copyWith(name: 'Update 2')),
        repository.update(createdObject.id, (current) => current.copyWith(name: 'Update 3')),
      ];
      final results = await Future.wait(futures);
      framework.expect(results.length, framework.equals(3));
      final finalObject = await repository.get(createdObject.id);
      framework.expect(['Update 1', 'Update 2', 'Update 3'], framework.contains(finalObject.name));
      print('✅ Handled concurrent modifications successfully');
    });

    framework.test('should handle repository disposal', () async {
      final repository = repositoryFactory();
      final testObject = TestObject.create(name: 'Test Object', created: DateTime.now());
      final createdObject = await repository.addAutoIdentified(
        testObject,
        updateObjectWithId: (object, id) => object.copyWith(id: id),
      );
      repository.dispose();
      final retrieved = await repository.get(createdObject.id);
      framework.expect(retrieved.name, framework.equals('Test Object'));
      print('✅ Handled repository disposal successfully');
    });

    framework.test('should handle large batch operations', () async {
      final repository = repositoryFactory();
      final objects = List.generate(
        30,
        (i) => TestObject.create(name: 'Object $i', created: DateTime.now().subtract(Duration(days: i))),
      );
      final createdObjects = <TestObject>[];
      for (final obj in objects) {
        final created = await repository.addAutoIdentified(
          obj,
          updateObjectWithId: (object, id) => object.copyWith(id: id),
        );
        createdObjects.add(created);
      }
      framework.expect(createdObjects.length, framework.equals(30));
      final retrieved1 = await repository.get(createdObjects[0].id);
      final retrieved15 = await repository.get(createdObjects[15].id);
      final retrieved29 = await repository.get(createdObjects[29].id);
      framework.expect(retrieved1.name, framework.equals('Object 0'));
      framework.expect(retrieved15.name, framework.equals('Object 15'));
      framework.expect(retrieved29.name, framework.equals('Object 29'));
      final ids = createdObjects.map((obj) => obj.id).toList();
      await repository.deleteAll(ids);
      print('✅ Handled large batch operations successfully');
    });

    framework.test('should handle operations on deleted documents', () async {
      final repository = repositoryFactory();
      final testObject = TestObject.create(name: 'To Be Deleted', created: DateTime.now());
      final createdObject = await repository.addAutoIdentified(
        testObject,
        updateObjectWithId: (object, id) => object.copyWith(id: id),
      );
      await repository.delete(createdObject.id);
      framework.expect(() => repository.get(createdObject.id), framework.throwsA(framework.isA<RepositoryException>()));
      framework.expect(() => repository.update(createdObject.id, (obj) => obj.copyWith(name: 'Updated')),
          framework.throwsA(framework.isA<RepositoryException>()));
      print('✅ Handled operations on deleted documents correctly');
    });

    framework.test('should handle rapid consecutive operations', () async {
      final repository = repositoryFactory();
      final testObject = TestObject.create(name: 'Rapid Object', created: DateTime.now());
      final createdObject = await repository.addAutoIdentified(
        testObject,
        updateObjectWithId: (object, id) => object.copyWith(id: id),
      );
      for (int i = 0; i < 10; i++) {
        await repository.update(createdObject.id, (current) => current.copyWith(name: 'Update $i'));
      }
      final finalObject = await repository.get(createdObject.id);
      framework.expect(finalObject.name, framework.equals('Update 9'));
      print('✅ Handled rapid consecutive operations successfully');
    });

    framework.test('should handle duplicate ID attempts correctly', () async {
      final repository = repositoryFactory();
      final object1 = TestObject.create(name: 'First Object', created: DateTime.now());
      final createdObject1 = await repository.addAutoIdentified(
        object1,
        updateObjectWithId: (object, id) => object.copyWith(id: id),
      );
      final object2 = TestObject.create(name: 'Duplicate Object', created: DateTime.now());
      framework.expect(
        () => repository.add(IdentifiedObject(createdObject1.id, object2.copyWith(id: createdObject1.id))),
        framework.throwsA(framework.isA<RepositoryException>()),
      );
      final retrieved = await repository.get(createdObject1.id);
      framework.expect(retrieved.name, framework.equals('First Object'));
      print('✅ Handled duplicate ID attempts correctly');
    });

    framework.test('should handle edge case query results', () async {
      final repository = repositoryFactory();
      final emptyResults = await repository.query();
      framework.expect(emptyResults, framework.isEmpty);
      final testObject = TestObject.create(name: 'Solo Object', created: DateTime.now());
      await repository.addAutoIdentified(
        testObject,
        updateObjectWithId: (object, id) => object.copyWith(id: id),
      );
      final singleResult = await repository.query();
      framework.expect(singleResult.length, framework.equals(1));
      framework.expect(singleResult.first.name, framework.equals('Solo Object'));
      print('✅ Handled edge case query results successfully');
    });

    framework.test('should handle autoIdentify edge cases', () async {
      final repository = repositoryFactory();
      final testObject = TestObject.create(name: 'Auto Object', created: DateTime.now());
      final identified = repository.autoIdentify(
        testObject,
        updateObjectWithId: (object, id) => object.copyWith(id: id),
      );
      framework.expect(identified.id, framework.isNotEmpty);
      final added = await repository.addAutoIdentified(
        testObject,
        updateObjectWithId: (object, id) => object.copyWith(id: id),
      );
      framework.expect(added.name, framework.equals('Auto Object'));
      framework.expect(added.id, framework.isNotEmpty);
      print('✅ Handled autoIdentify edge cases successfully');
    });

    framework.test('should handle get operations on non-existent items', () async {
      final repository = repositoryFactory();
      framework.expect(
          () => repository.get('non_existent_id'), framework.throwsA(framework.isA<RepositoryException>()));
      print('✅ Handled get operations on non-existent items correctly');
    });

    framework.test('should handle update operations on non-existent items', () async {
      final repository = repositoryFactory();
      framework.expect(
        () => repository.update('non_existent_id', (current) => current.copyWith(name: 'Updated')),
        framework.throwsA(framework.isA<RepositoryException>()),
      );
      print('✅ Handled update operations on non-existent items correctly');
    });
  });
}

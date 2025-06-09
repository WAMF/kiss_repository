import 'package:kiss_repository/kiss_repository.dart';

import 'data/queries.dart';
import 'data/test_object.dart';
import 'test_framework.dart';

/// Shared, framework-agnostic test logic for basic query operations.
void runBasicQueryLogic({
  required Repository<TestObject> Function() repositoryFactory,
  required TestFramework framework,
}) {
  framework.group('Basic Query Operations', () {
    framework.test('should query all items with AllQuery (default)', () async {
      final repository = repositoryFactory();

      // Add test data with specific timing to control creation order
      final objects = [
        TestObject.create(name: 'First Object', created: DateTime(2024, 1, 1)),
        TestObject.create(name: 'Second Object', created: DateTime(2024, 1, 2)),
        TestObject.create(name: 'Third Object', created: DateTime(2024, 1, 3)),
      ];

      final createdObjects = <TestObject>[];
      for (final obj in objects) {
        final created = await repository.addAutoIdentified(
          obj,
          updateObjectWithId: (object, id) => object.copyWith(id: id),
        );
        createdObjects.add(created);
        await Future.delayed(Duration(milliseconds: 10)); // Ensure different timestamps
      }

      final allObjects = await repository.query();
      framework.expect(allObjects.length, framework.equals(3));

      // Should be sorted by creation date descending (newest first)
      framework.expect(allObjects.first.name, framework.equals('Third Object'));
      framework.expect(allObjects.last.name, framework.equals('First Object'));
      print('✅ Queried all objects with default AllQuery');
    });

    framework.test('should return empty list when querying empty collection', () async {
      final repository = repositoryFactory();

      final emptyResults = await repository.query();
      framework.expect(emptyResults, framework.isEmpty);
      print('✅ Handled empty collection query correctly');
    });

    framework.test('should query by name prefix', () async {
      final repository = repositoryFactory();

      // Add test objects with various names
      final objects = [
        TestObject.create(name: 'Apple Item', created: DateTime.now()),
        TestObject.create(name: 'Banana Item', created: DateTime.now()),
        TestObject.create(name: 'Apple Product', created: DateTime.now()),
        TestObject.create(name: 'Cherry Item', created: DateTime.now()),
      ];

      for (final obj in objects) {
        await repository.addAutoIdentified(
          obj,
          updateObjectWithId: (object, id) => object.copyWith(id: id),
        );
        await Future.delayed(Duration(milliseconds: 10));
      }

      final appleObjects = await repository.query(query: QueryByName('Apple'));
      framework.expect(appleObjects.length, framework.equals(2));

      final names = appleObjects.map((obj) => obj.name).toList();
      framework.expect(names, framework.contains('Apple Item'));
      framework.expect(names, framework.contains('Apple Product'));
      print('✅ Queried objects by name prefix successfully');
    });

    framework.test('should query by created after date', () async {
      final repository = repositoryFactory();
      final cutoffDate = DateTime(2024, 6, 15);
      final objects = [
        TestObject.create(name: 'Old Object 1', created: DateTime(2024, 6, 10)),
        TestObject.create(name: 'Old Object 2', created: DateTime(2024, 6, 14)),
        TestObject.create(name: 'New Object 1', created: DateTime(2024, 6, 16)),
        TestObject.create(name: 'New Object 2', created: DateTime(2024, 6, 20)),
      ];

      for (final obj in objects) {
        await repository.addAutoIdentified(
          obj,
          updateObjectWithId: (object, id) => object.copyWith(id: id),
        );
        await Future.delayed(Duration(milliseconds: 10));
      }

      final recentObjects = await repository.query(query: QueryByCreatedAfter(cutoffDate));
      framework.expect(recentObjects.length, framework.equals(2));

      final names = recentObjects.map((obj) => obj.name).toSet();
      framework.expect(names, framework.contains('New Object 1'));
      framework.expect(names, framework.contains('New Object 2'));

      for (final obj in recentObjects) {
        framework.expect(obj.created.isAfter(cutoffDate), framework.isTrue);
      }
      print('✅ Queried objects by created after date successfully');
    });

    framework.test('should query by created before date', () async {
      final repository = repositoryFactory();
      final cutoffDate = DateTime(2024, 6, 15);
      final objects = [
        TestObject.create(name: 'Old Object 1', created: DateTime(2024, 6, 10)),
        TestObject.create(name: 'Old Object 2', created: DateTime(2024, 6, 14)),
        TestObject.create(name: 'New Object 1', created: DateTime(2024, 6, 16)),
        TestObject.create(name: 'New Object 2', created: DateTime(2024, 6, 20)),
      ];

      for (final obj in objects) {
        await repository.addAutoIdentified(
          obj,
          updateObjectWithId: (object, id) => object.copyWith(id: id),
        );
        await Future.delayed(Duration(milliseconds: 10));
      }

      final oldObjects = await repository.query(query: QueryByCreatedBefore(cutoffDate));
      framework.expect(oldObjects.length, framework.equals(2));

      final names = oldObjects.map((obj) => obj.name).toSet();
      framework.expect(names, framework.contains('Old Object 1'));
      framework.expect(names, framework.contains('Old Object 2'));

      for (final obj in oldObjects) {
        framework.expect(obj.created.isBefore(cutoffDate), framework.isTrue);
      }
      print('✅ Queried objects by created before date successfully');
    });

    framework.test('should handle query with no results', () async {
      final repository = repositoryFactory();
      final objects = [
        TestObject.create(name: 'Test Object', created: DateTime(2024, 1, 1)),
        TestObject.create(name: 'Another Object', created: DateTime(2024, 1, 2)),
      ];
      for (final obj in objects) {
        await repository.addAutoIdentified(
          obj,
          updateObjectWithId: (object, id) => object.copyWith(id: id),
        );
      }
      final noResults = await repository.query(query: QueryByName('NonExistent'));
      framework.expect(noResults, framework.isEmpty);
      print('✅ Handled query with no results correctly');
    });

    framework.test('should query all items when using AllQuery explicitly', () async {
      final repository = repositoryFactory();
      final objects = [
        TestObject.create(name: 'Object A', created: DateTime.now()),
        TestObject.create(name: 'Object B', created: DateTime.now()),
        TestObject.create(name: 'Object C', created: DateTime.now()),
      ];
      for (final obj in objects) {
        await repository.addAutoIdentified(
          obj,
          updateObjectWithId: (object, id) => object.copyWith(id: id),
        );
        await Future.delayed(Duration(milliseconds: 10));
      }
      final allObjects = await repository.query(query: AllQuery());
      framework.expect(allObjects.length, framework.equals(3));

      final names = allObjects.map((obj) => obj.name).toSet();
      framework.expect(names, framework.contains('Object A'));
      framework.expect(names, framework.contains('Object B'));
      framework.expect(names, framework.contains('Object C'));
      print('✅ Queried all objects using explicit AllQuery');
    });
  });
}

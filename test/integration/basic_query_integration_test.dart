import 'package:test/test.dart';
import 'package:kiss_repository/kiss_repository.dart';

import '../data/test_object.dart';
import '../data/queries.dart';

/// Run basic query filtering integration tests on any Repository<TestObject> implementation
void runBasicQueryTests(Repository<TestObject> Function() repositoryFactory) {
  group('Basic Query Operations', () {
    test('should query all items with AllQuery (default)', () async {
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
      expect(allObjects.length, 3);

      // Should be sorted by creation date descending (newest first)
      expect(allObjects.first.name, 'Third Object');
      expect(allObjects.last.name, 'First Object');
      print('✅ Queried all objects with default AllQuery');
    });

    test('should return empty list when querying empty collection', () async {
      final repository = repositoryFactory();

      final emptyResults = await repository.query();
      expect(emptyResults, isEmpty);
      print('✅ Handled empty collection query correctly');
    });

    test('should query by name prefix', () async {
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
      expect(appleObjects.length, 2);

      final names = appleObjects.map((obj) => obj.name).toList();
      expect(names, contains('Apple Item'));
      expect(names, contains('Apple Product'));
      print('✅ Queried objects by name prefix successfully');
    });

    test('should query by created after date', () async {
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
      expect(recentObjects.length, 2);

      final names = recentObjects.map((obj) => obj.name).toSet();
      expect(names, contains('New Object 1'));
      expect(names, contains('New Object 2'));

      // Verify all returned objects are after cutoff date
      for (final obj in recentObjects) {
        expect(obj.created.isAfter(cutoffDate), isTrue);
      }
      print('✅ Queried objects by created after date successfully');
    });

    test('should query by created before date', () async {
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
      expect(oldObjects.length, 2);

      final names = oldObjects.map((obj) => obj.name).toSet();
      expect(names, contains('Old Object 1'));
      expect(names, contains('Old Object 2'));

      // Verify all returned objects are before cutoff date
      for (final obj in oldObjects) {
        expect(obj.created.isBefore(cutoffDate), isTrue);
      }
      print('✅ Queried objects by created before date successfully');
    });

    test('should handle query with no results', () async {
      final repository = repositoryFactory();

      // Add some test data
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

      // Query for something that doesn't exist
      final noResults = await repository.query(query: QueryByName('NonExistent'));
      expect(noResults, isEmpty);
      print('✅ Handled query with no results correctly');
    });

    test('should query all items when using AllQuery explicitly', () async {
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
      expect(allObjects.length, 3);

      final names = allObjects.map((obj) => obj.name).toSet();
      expect(names, contains('Object A'));
      expect(names, contains('Object B'));
      expect(names, contains('Object C'));
      print('✅ Queried all objects using explicit AllQuery');
    });
  });
}

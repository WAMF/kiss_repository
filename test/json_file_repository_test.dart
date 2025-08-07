import 'dart:io';

import 'package:kiss_repository/src/in_memory_repository.dart';
import 'package:kiss_repository/src/json_file_repository.dart';
import 'package:kiss_repository/src/repository.dart';
import 'package:test/test.dart';

import 'shared_repository_tests.dart';

class TestQueryBuilder extends QueryBuilder<InMemoryFilterQuery<TestObject>> {
  @override
  InMemoryFilterQuery<TestObject> build(Query query) {
    if (query is AllQuery) {
      return InMemoryFilterQuery<TestObject>((item) => true);
    }
    throw UnimplementedError('Query type not supported: $query');
  }
}

void main() {
  late File testFile;

  setUp(() {
    testFile = File('test_data.json');
    if (testFile.existsSync()) {
      testFile.deleteSync();
    }
  });

  tearDown(() {
    if (testFile.existsSync()) {
      testFile.deleteSync();
    }
  });

  runRepositoryTests(
    'JsonFileRepository',
    () => JsonFileRepository<TestObject>(
      queryBuilder: TestQueryBuilder(),
      path: 'test_objects',
      file: testFile,
      fromJson: TestObject.fromJson,
      toJson: (obj) => obj.toJson(),
    ),
    () {
      if (testFile.existsSync()) {
        testFile.deleteSync();
      }
    },
  );

  group('JsonFileRepository specific tests', () {
    test('persists data across repository instances', () async {
      final repo1 = JsonFileRepository<TestObject>(
        queryBuilder: TestQueryBuilder(),
        path: 'test_objects',
        file: testFile,
        fromJson: TestObject.fromJson,
        toJson: (obj) => obj.toJson(),
      );

      const object = TestObject(name: 'Persistent', value: 42);
      await repo1.add(IdentifiedObject('persist-1', object));
      repo1.dispose();

      final repo2 = JsonFileRepository<TestObject>(
        queryBuilder: TestQueryBuilder(),
        path: 'test_objects',
        file: testFile,
        fromJson: TestObject.fromJson,
        toJson: (obj) => obj.toJson(),
      );

      final retrieved = await repo2.get('persist-1');
      expect(retrieved.name, equals('Persistent'));
      expect(retrieved.value, equals(42));
      repo2.dispose();
    });

    test('handles corrupted JSON file gracefully', () {
      testFile.writeAsStringSync('not valid json');

      expect(
        () => JsonFileRepository<TestObject>(
          queryBuilder: TestQueryBuilder(),
          path: 'test_objects',
          file: testFile,
          fromJson: TestObject.fromJson,
          toJson: (obj) => obj.toJson(),
        ),
        throwsA(
          isA<RepositoryException>()
              .having((e) => e.message, 'message', contains('Failed to load')),
        ),
      );
    });

    test('creates new file if it does not exist', () async {
      expect(testFile.existsSync(), isFalse);

      final repo = JsonFileRepository<TestObject>(
        queryBuilder: TestQueryBuilder(),
        path: 'test_objects',
        file: testFile,
        fromJson: TestObject.fromJson,
        toJson: (obj) => obj.toJson(),
      );

      await repo.add(
        IdentifiedObject('new-1', const TestObject(name: 'New', value: 1)),
      );

      expect(testFile.existsSync(), isTrue);
      repo.dispose();
    });

    test('persists and loads 50 items correctly', () async {
      final repo1 = JsonFileRepository<TestObject>(
        queryBuilder: TestQueryBuilder(),
        path: 'test_objects',
        file: testFile,
        fromJson: TestObject.fromJson,
        toJson: (obj) => obj.toJson(),
      );

      const itemCount = 50;
      final items = <IdentifiedObject<TestObject>>[];

      for (var i = 0; i < itemCount; i++) {
        items.add(
          IdentifiedObject(
            'bulk-$i',
            TestObject(name: 'Item $i', value: i * 10),
          ),
        );
      }

      await repo1.addAll(items);

      final allItemsInRepo1 = await repo1.query();
      expect(allItemsInRepo1.length, equals(itemCount));

      repo1.dispose();

      final repo2 = JsonFileRepository<TestObject>(
        queryBuilder: TestQueryBuilder(),
        path: 'test_objects',
        file: testFile,
        fromJson: TestObject.fromJson,
        toJson: (obj) => obj.toJson(),
      );

      final allItemsInRepo2 = await repo2.query();
      expect(allItemsInRepo2.length, equals(itemCount));

      for (var i = 0; i < itemCount; i++) {
        final retrieved = await repo2.get('bulk-$i');
        expect(retrieved.name, equals('Item $i'));
        expect(retrieved.value, equals(i * 10));
      }

      repo2.dispose();
    });

    test('handles batch operations with 50+ items efficiently', () async {
      final repo = JsonFileRepository<TestObject>(
        queryBuilder: TestQueryBuilder(),
        path: 'test_objects',
        file: testFile,
        fromJson: TestObject.fromJson,
        toJson: (obj) => obj.toJson(),
      );

      const batchSize = 50;
      final addItems = <IdentifiedObject<TestObject>>[];

      for (var i = 0; i < batchSize; i++) {
        addItems.add(
          IdentifiedObject(
            'batch-$i',
            TestObject(name: 'Original $i', value: i),
          ),
        );
      }

      await repo.addAll(addItems);

      final updateItems = <IdentifiedObject<TestObject>>[];
      for (var i = 0; i < batchSize; i++) {
        updateItems.add(
          IdentifiedObject(
            'batch-$i',
            TestObject(name: 'Updated $i', value: i * 2),
          ),
        );
      }

      await repo.updateAll(updateItems);

      for (var i = 0; i < batchSize; i++) {
        final item = await repo.get('batch-$i');
        expect(item.name, equals('Updated $i'));
        expect(item.value, equals(i * 2));
      }

      final deleteIds = <String>[];
      for (var i = 0; i < 25; i++) {
        deleteIds.add('batch-$i');
      }

      await repo.deleteAll(deleteIds);

      final remaining = await repo.query();
      expect(remaining.length, equals(25));

      for (var i = 25; i < batchSize; i++) {
        final item = await repo.get('batch-$i');
        expect(item.name, equals('Updated $i'));
      }

      repo.dispose();
    });
  });
}

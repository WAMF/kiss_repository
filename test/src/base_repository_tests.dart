import 'package:kiss_repository/kiss_repository.dart';
import 'package:kiss_repository/src/in_memory_repository.dart'; // Import the implementation
import 'package:test/test.dart';

class InMemoryQueryBuilder
    implements QueryBuilder<InMemoryFilterQuery<TestObject>> {
  @override
  InMemoryFilterQuery<TestObject> build(Query query) {
    if (query is QueryByName) {
      return InMemoryQueryByNameFilter(query);
    }
    return InMemoryFilterQuery<TestObject>((item) => true);
  }
}

class InMemoryQueryByNameFilter extends InMemoryFilterQuery<TestObject> {
  final QueryByName query;
  InMemoryQueryByNameFilter(this.query)
      : super((item) => item.name == query.name);
}

class QueryByName implements Query {
  final String name;
  QueryByName(this.name);
}

// Simple class for testing
class TestObject {
  final String id;
  final String name;
  TestObject({required this.id, required this.name});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TestObject &&
          runtimeType == other.runtimeType &&
          name == other.name;

  @override
  int get hashCode => name.hashCode;

  @override
  String toString() => 'TestObject{name: $name}';
}

int _nextId = 0;
String generateId() {
  return 'mem_${_nextId++}';
}

void main() {
  group('InMemoryRepository Tests', () {
    late Repository<TestObject> repository;
    late InMemoryQueryBuilder queryBuilder;

    setUp(() {
      queryBuilder = InMemoryQueryBuilder();
      repository = InMemoryRepository<TestObject>(
        queryBuilder: queryBuilder,
        path: 'test_objects',
      );
    });

    tearDown(() {
      repository.dispose();
    });

    test('add and get single item', () async {
      final id = generateId();
      final item = TestObject(id: id, name: 'Test 1');
      final addedItem = await repository.add(IdentifedObject(id, item));
      final retrievedItem = await repository.get(id);

      expect(addedItem, item);
      expect(retrievedItem, item);
    });

    test('addWithId and get single item', () async {
      final id = generateId();
      final item = TestObject(id: id, name: 'Test A');
      await repository.add(IdentifedObject(id, item));
      final retrievedItem = await repository.get(id);

      expect(retrievedItem, item);
    });

    test('get throws notFound for non-existent item', () async {
      expect(
        () => repository.get('non_existent_id'),
        throwsA(isA<RepositoryException>()
            .having((e) => e.code, 'code', RepositoryErrorCode.notFound)),
      );
    });

    test('add throws alreadyExists for existing id', () async {
      final id = generateId();
      final item1 = TestObject(id: id, name: 'Test B');
      await repository.add(IdentifedObject(id, item1));

      final item2 = TestObject(id: id, name: 'Test C');
      expect(
        () => repository.add(IdentifedObject(id, item2)),
        throwsA(isA<RepositoryException>()
            .having((e) => e.code, 'code', RepositoryErrorCode.alreadyExists)),
      );
    });

    test('update existing item', () async {
      final id = generateId();
      final initialItem = TestObject(id: id, name: 'Initial');
      await repository.add(IdentifedObject(id, initialItem));

      final updatedItem = await repository.update(id, (current) {
        expect(current, initialItem);
        return TestObject(id: id, name: 'Updated');
      });

      final retrievedItem = await repository.get(id);
      expect(updatedItem.name, 'Updated');
      expect(retrievedItem.name, 'Updated');
      expect(retrievedItem, updatedItem);
    });

    test('update throws notFound for non-existent item', () async {
      expect(
        () => repository.update('non_existent_id',
            (current) => TestObject(id: 'Wont Happen', name: 'Wont Happen')),
        throwsA(isA<RepositoryException>()
            .having((e) => e.code, 'code', RepositoryErrorCode.notFound)),
      );
    });

    test('delete existing item', () async {
      final id = generateId();
      final item = TestObject(id: id, name: 'Delete Me');
      await repository.add(IdentifedObject(id, item));

      // Ensure it exists first
      expect(await repository.get(id), item);

      await repository.delete(id);

      // Ensure it's gone
      expect(
        () => repository.get(id),
        throwsA(isA<RepositoryException>()
            .having((e) => e.code, 'code', RepositoryErrorCode.notFound)),
      );
    });

    test('delete throws notFound for non-existent item', () async {
      // Note: The implementation in the attached file throws, so we test that.
      // If silent failure was desired, this test would change.
      expect(
        () => repository.delete('non_existent_id'),
        throwsA(isA<RepositoryException>()
            .having((e) => e.code, 'code', RepositoryErrorCode.notFound)),
      );
    });

    // --- Query Tests ---

    test('query AllQuery returns all items', () async {
      final id1 = generateId();
      final id2 = generateId();
      final item1 = TestObject(id: id1, name: 'All 1');
      final item2 = TestObject(id: id2, name: 'All 2');
      await repository.add(IdentifedObject(id1, item1));
      await repository.add(IdentifedObject(id2, item2));

      final results = await repository.query(); // Default is AllQuery
      expect(results, containsAll([item1, item2]));
      expect(results.length, 2);
    });

    test('query returns filtered items', () async {
      final id1 = generateId();
      final id2 = generateId();
      final id3 = generateId();
      final item1 = TestObject(id: id1, name: 'Filter 1');
      final item2 = TestObject(id: id2, name: 'Keep Me');
      final item3 = TestObject(id: id3, name: 'Filter 3');
      await repository.add(IdentifedObject(id1, item1));
      await repository.add(IdentifedObject(id2, item2));
      await repository.add(IdentifedObject(id3, item3));

      final query = QueryByName('Keep Me');
      final results = await repository.query(query: query);

      expect(results, [item2]);
      expect(results.length, 1);
    });

    // --- Stream Tests ---

    test('stream emits existing item and updates', () async {
      final id = generateId();
      final initialItem = TestObject(id: id, name: 'Stream Initial');
      await repository.add(IdentifedObject(id, initialItem));

      final stream = repository.stream(id);
      final updatedItem = TestObject(id: id, name: 'Stream Updated');

      expect(
          stream,
          emitsInOrder([
            initialItem,
            updatedItem,
          ]));

      await Future.delayed(Duration.zero);

      // Trigger update
      await repository.update(id, (_) => updatedItem);
    });

    test('stream emits notFound error for non-existent item', () async {
      final stream = repository.stream('non_existent_stream_id');

      expect(
        stream,
        emitsError(isA<RepositoryException>()
            .having((e) => e.code, 'code', RepositoryErrorCode.notFound)),
      );
    });

    test('stream emits update after initial notFound error', () async {
      final id = generateId();
      final stream = repository.stream(id);
      final itemToAdd = TestObject(id: id, name: 'Added Late');

      expect(
          stream,
          emitsInOrder([
            // First emits error because item doesn't exist
            emitsError(isA<RepositoryException>()
                .having((e) => e.code, 'code', RepositoryErrorCode.notFound)),
            // Then emits the item when it's added
            itemToAdd,
          ]));

      await Future.delayed(Duration.zero);

      await repository.add(IdentifedObject(id, itemToAdd));
    });

    test('stream emits notFound error after deletion', () async {
      final id = generateId();
      final item = TestObject(id: id, name: 'Stream Delete');
      await repository.add(IdentifedObject(id, item));

      final stream = repository.stream(id);

      expect(
          stream,
          emitsInOrder([
            item, // Initial emit
            // Then emits error because item is deleted
            emitsError(isA<RepositoryException>()
                .having((e) => e.code, 'code', RepositoryErrorCode.notFound)),
            // emitsDone // Stream should also close after delete notification
          ]));

      await Future.delayed(Duration.zero);

      await repository.delete(id);

      await Future.delayed(Duration.zero);
    });

    test('streamQuery AllQuery emits initial list and updates', () async {
      final id1 = generateId();
      final id2 = generateId();
      final item1 = TestObject(id: id1, name: 'QStream 1');
      final item2 = TestObject(id: id2, name: 'QStream 2');

      final stream = repository.streamQuery(); // Default is AllQuery

      expect(
          stream,
          emitsInOrder([
            <TestObject>[], // Initial empty list
            [item1], // After adding item1
            [item1, item2], // After adding item2
          ]));

      // Add items after stream subscription
      await repository.add(IdentifedObject(item1.id, item1));
      await repository.add(IdentifedObject(item2.id, item2));
    });

    test('streamQuery with FilterQuery emits initial filtered list and updates',
        () async {
      final id1 = generateId();
      final id2 = generateId();
      final id3 = generateId();
      final filterQuery = QueryByName('Keep');
      final itemToKeep1 = TestObject(id: id1, name: 'Keep');
      final itemToFilter = TestObject(id: id2, name: 'Filter Me');
      final itemToKeep2 = TestObject(id: id3, name: 'Keep');

      final stream = repository.streamQuery(query: filterQuery);

      expect(
          stream,
          emitsInOrder([
            <TestObject>[], // Initial empty (filtered) list
            [itemToKeep1], // After adding Keep 1
            [itemToKeep1], // After adding Filter Me (filtered list unchanged)
            [itemToKeep1, itemToKeep2], // After adding Keep 2
          ]));

      // Add items after stream subscription
      await repository.add(IdentifedObject(itemToKeep1.id, itemToKeep1));
      await repository.add(IdentifedObject(itemToFilter.id, itemToFilter));
      await repository.add(IdentifedObject(itemToKeep2.id, itemToKeep2));
    });

    test('streamQuery handles deletion correctly', () async {
      final id1 = generateId();
      final id2 = generateId();
      final item1 = TestObject(id: id1, name: 'QS Del 1');
      final item2 = TestObject(id: id2, name: 'QS Del 2');
      await repository.add(IdentifedObject(id1, item1));
      await repository.add(IdentifedObject(id2, item2));

      final stream = repository.streamQuery(); // AllQuery

      expect(
          stream,
          emitsInOrder([
            [item1, item2], // Initial list
            [item2], // After deleting item1
            [], // After deleting item2
          ]));

      // Delete items after stream subscription
      await repository.delete(id1);
      await repository.delete(id2);
    });

    // --- Batch Operation Tests ---

    test('addAll adds multiple items and returns them', () async {
      final id1 = generateId();
      final id2 = generateId();
      final itemsToAdd = [
        IdentifedObject(id1, TestObject(id: id1, name: 'Batch 1')),
        IdentifedObject(id2, TestObject(id: id2, name: 'Batch 2')),
      ];
      final addedItems = await repository.addAll(itemsToAdd);

      expect(addedItems, containsAll(itemsToAdd.map((e) => e.object)));
      expect(addedItems.length, itemsToAdd.length);

      final results = await repository.query();
      expect(results, containsAll(itemsToAdd.map((e) => e.object)));
      expect(results.length, 2);
      // Check specific IDs if generator is predictable
      expect(await repository.get(id1), itemsToAdd[0].object);
      expect(await repository.get(id2), itemsToAdd[1].object);
    });

    test('updateAll updates multiple items', () async {
      final id1 = generateId();
      final id2 = generateId();
      final item1 = TestObject(id: id1, name: 'UpdateAll 1 Initial');
      final item2 = TestObject(id: id2, name: 'UpdateAll 2 Initial');
      await repository.add(IdentifedObject(id1, item1));
      await repository.add(IdentifedObject(id2, item2));

      final updates = [
        IdentifedObject(id1, TestObject(id: id1, name: 'UpdateAll 1 Updated')),
        IdentifedObject(id2, TestObject(id: id2, name: 'UpdateAll 2 Updated')),
      ];

      final updatedItems = await repository.updateAll(updates);

      expect(updatedItems.length, 2);
      expect(updatedItems.map((e) => e.name),
          containsAll(['UpdateAll 1 Updated', 'UpdateAll 2 Updated']));

      expect((await repository.get(id1)).name, 'UpdateAll 1 Updated');
      expect((await repository.get(id2)).name, 'UpdateAll 2 Updated');
    });

    test('updateAll throws notFound if any item doesnt exist', () async {
      final id1 = generateId();
      final item1 = TestObject(id: id1, name: 'UpdateAll Exists');
      await repository.add(IdentifedObject(id1, item1));

      final updates = [
        IdentifedObject(
            id1, TestObject(id: id1, name: 'UpdateAll Exists Updated')),
        IdentifedObject('non_existent',
            TestObject(id: 'non_existent', name: 'UpdateAll NonExistent')),
      ];

      expect(
        () => repository.updateAll(updates),
        throwsA(isA<RepositoryException>()
            .having((e) => e.code, 'code', RepositoryErrorCode.notFound)
            .having((e) => e.message, 'message', contains('non_existent'))),
      );

      // Check that the valid item wasn't updated (atomic failure)
      expect((await repository.get(id1)).name, 'UpdateAll Exists');
    });

    test('deleteAll removes multiple items', () async {
      final id1 = generateId();
      final id2 = generateId();
      final id3 = generateId();
      final item1 = TestObject(id: id1, name: 'DeleteAll 1');
      final item2 = TestObject(id: id2, name: 'DeleteAll 2');
      final item3 = TestObject(id: id3, name: 'DeleteAll 3');
      await repository.add(IdentifedObject(id1, item1));
      await repository.add(IdentifedObject(id2, item2));
      await repository.add(IdentifedObject(id3, item3));

      await repository.deleteAll([id1, id3]);

      final results = await repository.query();
      expect(results, [item2]); // Only item2 should remain
      expect(results.length, 1);

      // Verify deletion
      expect(() => repository.get(id1), throwsA(isA<RepositoryException>()));
      expect(() => repository.get(id3), throwsA(isA<RepositoryException>()));
    });
  });
}

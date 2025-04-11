import 'package:kiss_repository/kiss_repository.dart';
import 'package:kiss_repository/src/in_memory_repository.dart'; // Import the implementation
import 'package:test/test.dart';

// Simple mock QueryBuilder for testing purposes
class MockQueryBuilder<T> implements QueryBuilder<InMemoryFilterQuery<T>> {
  @override
  InMemoryFilterQuery<T> build(Query query) {
    if (query is InMemoryFilterQuery<T>) {
      return query; // Pass through if it's already the correct type
    }
    // For testing, assume any other query translates to a filter that accepts all
    // You might want more sophisticated mock logic depending on your query types
    return InMemoryFilterQuery<T>((item) => true);
  }
}

// Simple class for testing
class TestObject {
  final String name;
  TestObject(this.name);

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

void main() {
  group('InMemoryRepository Tests', () {
    late InMemoryRepository<TestObject> repository;
    late MockQueryBuilder<TestObject> mockQueryBuilder;

    setUp(() {
      mockQueryBuilder = MockQueryBuilder<TestObject>();
      // Using a base path for testing, mirroring the constructor requirement
      repository = InMemoryRepository<TestObject>(
        queryBuilder: mockQueryBuilder,
        path: 'test_objects',
      );
    });

    tearDown(() {
      repository.dispose(); // Ensure streams are closed after each test
    });

    test('add and get single item', () async {
      final item = TestObject('Test 1');
      final addedItem = await repository.add(item);
      // Assuming add returns the item itself, and _generateId creates 'mem_0'
      final retrievedItem = await repository.get('mem_0');

      expect(addedItem, item); // Check if the returned item is the same
      expect(retrievedItem, item);
      // Check internal state (optional, based on visibility/need)
      // expect(repository._items['test_objects/mem_0'], item);
    });

    test('addWithId and get single item', () async {
      final item = TestObject('Test A');
      final id = 'custom_id_1';
      await repository.addWithId(id, item);
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
      final item1 = TestObject('Test B');
      final id = 'duplicate_id';
      await repository.addWithId(id, item1);

      final item2 = TestObject('Test C');
      expect(
        () => repository.addWithId(id, item2),
        throwsA(isA<RepositoryException>()
            .having((e) => e.code, 'code', RepositoryErrorCode.alreadyExists)),
      );
    });

    test('update existing item', () async {
      final initialItem = TestObject('Initial');
      final id = 'update_id';
      await repository.addWithId(id, initialItem);

      final updatedItem = await repository.update(id, (current) {
        expect(current, initialItem);
        return TestObject('Updated');
      });

      final retrievedItem = await repository.get(id);
      expect(updatedItem.name, 'Updated');
      expect(retrievedItem.name, 'Updated');
      expect(retrievedItem, updatedItem);
    });

    test('update throws notFound for non-existent item', () async {
      expect(
        () => repository.update(
            'non_existent_id', (current) => TestObject('Wont Happen')),
        throwsA(isA<RepositoryException>()
            .having((e) => e.code, 'code', RepositoryErrorCode.notFound)),
      );
    });

    test('delete existing item', () async {
      final item = TestObject('Delete Me');
      final id = 'delete_id';
      await repository.addWithId(id, item);

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
      final item1 = TestObject('All 1');
      final item2 = TestObject('All 2');
      await repository.add(item1); // id: mem_0
      await repository.add(item2); // id: mem_1

      final results = await repository.query(); // Default is AllQuery
      expect(results, containsAll([item1, item2]));
      expect(results.length, 2);
    });

    test('query with InMemoryFilterQuery returns filtered items', () async {
      final item1 = TestObject('Filter 1');
      final item2 = TestObject('Keep Me');
      final item3 = TestObject('Filter 3');
      await repository.add(item1);
      await repository.add(item2);
      await repository.add(item3);

      final query =
          InMemoryFilterQuery<TestObject>((item) => item.name == 'Keep Me');
      final results = await repository.query(query: query);

      expect(results, [item2]);
      expect(results.length, 1);
    });

    // --- Stream Tests ---

    test('stream emits existing item and updates', () async {
      final id = 'stream_id_1';
      final initialItem = TestObject('Stream Initial');
      await repository.addWithId(id, initialItem);

      final stream = repository.stream(id);
      final updatedItem = TestObject('Stream Updated');

      expect(
          stream,
          emitsInOrder([
            initialItem, // Initial value
            updatedItem, // Updated value
            // emitsDone // Stream shouldn't close here unless dispose is called
          ]));

      // Wait for the initial emit if necessary (sometimes helps with timing)
      await Future.delayed(Duration.zero);

      // Trigger update
      await repository.update(id, (_) => updatedItem);

      // Optionally: Test closing the stream upon deletion
      // await repository.delete(id);
      // await Future.delayed(Duration.zero); // Allow stream event to propagate
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
      final id = 'stream_late_add';
      final stream = repository.stream(id);
      final itemToAdd = TestObject('Added Late');

      expect(
          stream,
          emitsInOrder([
            // First emits error because item doesn't exist
            emitsError(isA<RepositoryException>()
                .having((e) => e.code, 'code', RepositoryErrorCode.notFound)),
            // Then emits the item when it's added
            itemToAdd,
          ]));

      // Wait for the error event to potentially process
      await Future.delayed(Duration.zero);

      // Add the item
      await repository.addWithId(id, itemToAdd);
    });

    test('stream emits notFound error after deletion', () async {
      final id = 'stream_delete_id';
      final item = TestObject('Stream Delete');
      await repository.addWithId(id, item);

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

      // Wait for initial emit
      await Future.delayed(Duration.zero);
      // Delete the item
      await repository.delete(id);
      // Wait for delete event
      await Future.delayed(Duration.zero);
      // At this point, the controller should be closed by the delete logic.
      // Further testing could involve checking if the stream `isDone`.
    });

    test('streamQuery AllQuery emits initial list and updates', () async {
      final item1 = TestObject('QStream 1');
      final item2 = TestObject('QStream 2');

      final stream = repository.streamQuery(); // Default is AllQuery

      expect(
          stream,
          emitsInOrder([
            <TestObject>[], // Initial empty list
            [item1], // After adding item1
            [item1, item2], // After adding item2
          ]));

      // Add items after stream subscription
      await repository.add(item1);
      await repository.add(item2);
    });

    test('streamQuery with FilterQuery emits initial filtered list and updates',
        () async {
      final filterQuery = InMemoryFilterQuery<TestObject>(
          (item) => item.name.startsWith('Keep'));
      final itemToKeep1 = TestObject('Keep 1');
      final itemToFilter = TestObject('Filter Me');
      final itemToKeep2 = TestObject('Keep 2');

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
      await repository.add(itemToKeep1);
      await repository.add(itemToFilter);
      await repository.add(itemToKeep2);
    });

    test('streamQuery handles deletion correctly', () async {
      final item1 = TestObject('QS Del 1');
      final item2 = TestObject('QS Del 2');
      final id1 =
          await repository.add(item1).then((_) => 'mem_0'); // Get generated ID
      final id2 =
          await repository.add(item2).then((_) => 'mem_1'); // Get generated ID

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
      final itemsToAdd = [TestObject('Batch 1'), TestObject('Batch 2')];
      final addedItems = await repository.addAll(itemsToAdd);

      expect(addedItems, containsAll(itemsToAdd));
      expect(addedItems.length, itemsToAdd.length);

      final results = await repository.query();
      expect(results, containsAll(itemsToAdd));
      expect(results.length, 2);
      // Check specific IDs if generator is predictable
      expect(await repository.get('mem_0'), itemsToAdd[0]);
      expect(await repository.get('mem_1'), itemsToAdd[1]);
    });

    test('updateAll updates multiple items', () async {
      final item1 = TestObject('UpdateAll 1 Initial');
      final item2 = TestObject('UpdateAll 2 Initial');
      final id1 = await repository.add(item1).then((_) => 'mem_0');
      final id2 = await repository.add(item2).then((_) => 'mem_1');

      final updates = [
        IdentifedObject(id1, TestObject('UpdateAll 1 Updated')),
        IdentifedObject(id2, TestObject('UpdateAll 2 Updated')),
      ];

      final updatedItems = await repository.updateAll(updates);

      expect(updatedItems.length, 2);
      expect(updatedItems.map((e) => e.name),
          containsAll(['UpdateAll 1 Updated', 'UpdateAll 2 Updated']));

      expect((await repository.get(id1)).name, 'UpdateAll 1 Updated');
      expect((await repository.get(id2)).name, 'UpdateAll 2 Updated');
    });

    test('updateAll throws notFound if any item doesnt exist', () async {
      final item1 = TestObject('UpdateAll Exists');
      final id1 = await repository.add(item1).then((_) => 'mem_0');

      final updates = [
        IdentifedObject(id1, TestObject('UpdateAll Exists Updated')),
        IdentifedObject('non_existent', TestObject('UpdateAll NonExistent')),
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
      final item1 = TestObject('DeleteAll 1');
      final item2 = TestObject('DeleteAll 2');
      final item3 = TestObject('DeleteAll 3');
      final id1 = await repository.add(item1).then((_) => 'mem_0');
      final _ = await repository.add(item2).then((_) => 'mem_1');
      final id3 = await repository.add(item3).then((_) => 'mem_2');

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

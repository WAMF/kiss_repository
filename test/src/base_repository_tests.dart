import 'package:kiss_repository/kiss_repository.dart';
import 'package:test/test.dart';

class InMemoryQueryBuilder
    implements QueryBuilder<InMemoryFilterQuery<ProductModel>> {
  @override
  InMemoryFilterQuery<ProductModel> build(Query query) {
    if (query is QueryByName) {
      return InMemoryQueryByNameFilter(query);
    }
    return InMemoryFilterQuery<ProductModel>((item) => true);
  }
}

class InMemoryQueryByNameFilter extends InMemoryFilterQuery<ProductModel> {
  final QueryByName query;
  InMemoryQueryByNameFilter(this.query)
      : super((item) => item.name == query.name);
}

class QueryByName implements Query {
  final String name;
  QueryByName(this.name);
}

// Simple class for testing
class ProductModel {
  final String id;
  final String name;
  ProductModel({
    required this.id,
    required this.name,
  });

  // Add copyWith method to support updating with generated ID
  ProductModel copyWith({
    String? id,
    String? name,
  }) {
    return ProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProductModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name;

  @override
  int get hashCode => Object.hash(id, name);

  @override
  String toString() => 'ProductModel{name: $name}';
}

void main() {
  group('InMemoryRepository Tests', () {
    late Repository<ProductModel> repository;
    late InMemoryQueryBuilder queryBuilder;

    setUp(() {
      queryBuilder = InMemoryQueryBuilder();
      repository = InMemoryRepository<ProductModel>(
        queryBuilder: queryBuilder,
        path: 'products',
      );
    });

    tearDown(() {
      repository.dispose();
    });

    test('add and get single item', () async {
      final item = ProductModel(id: '', name: 'Test 1');
      final addedItem = await repository.addAutoIdentified(
        item,
        updateObjectWithId: (obj, id) => obj.copyWith(id: id),
      );
      final retrievedItem = await repository.get(addedItem.id);

      expect(addedItem.name, 'Test 1');
      expect(addedItem.id, isNotEmpty);
      expect(retrievedItem, addedItem);
    });

    test('add with specific ID and get single item', () async {
      final item = ProductModel(id: 'specific_id', name: 'Test A');
      final addedItem =
          await repository.add(IdentifiedObject('specific_id', item));
      final retrievedItem = await repository.get('specific_id');

      expect(retrievedItem, addedItem);
    });

    test('get throws notFound for non-existent item', () async {
      expect(
        () => repository.get('non_existent_id'),
        throwsA(isA<RepositoryException>()
            .having((e) => e.code, 'code', RepositoryErrorCode.notFound)),
      );
    });

    test('add throws alreadyExists for existing id', () async {
      final item1 = ProductModel(id: '', name: 'Test B');
      final addedItem1 = await repository.addAutoIdentified(
        item1,
        updateObjectWithId: (obj, id) => obj.copyWith(id: id),
      );

      final item2 = ProductModel(id: addedItem1.id, name: 'Test C');
      expect(
        () => repository.add(IdentifiedObject(addedItem1.id, item2)),
        throwsA(isA<RepositoryException>()
            .having((e) => e.code, 'code', RepositoryErrorCode.alreadyExists)),
      );
    });

    test('update existing item', () async {
      final item = ProductModel(id: '', name: 'Initial');
      final addedItem = await repository.addAutoIdentified(
        item,
        updateObjectWithId: (obj, id) => obj.copyWith(id: id),
      );

      final updatedItem = await repository.update(addedItem.id, (current) {
        expect(current, addedItem);
        return current.copyWith(name: 'Updated');
      });

      final retrievedItem = await repository.get(addedItem.id);
      expect(updatedItem.name, 'Updated');
      expect(retrievedItem.name, 'Updated');
      expect(retrievedItem, updatedItem);
    });

    test('update throws notFound for non-existent item', () async {
      expect(
        () => repository.update('non_existent_id',
            (current) => ProductModel(id: 'Wont Happen', name: 'Wont Happen')),
        throwsA(isA<RepositoryException>()
            .having((e) => e.code, 'code', RepositoryErrorCode.notFound)),
      );
    });

    test('delete existing item', () async {
      final item = ProductModel(id: '', name: 'Delete Me');
      final addedItem = await repository.addAutoIdentified(
        item,
        updateObjectWithId: (obj, id) => obj.copyWith(id: id),
      );

      // Ensure it exists first
      expect(await repository.get(addedItem.id), addedItem);

      await repository.delete(addedItem.id);

      // Ensure it's gone
      expect(
        () => repository.get(addedItem.id),
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
      final item1 = ProductModel(id: '', name: 'All 1');
      final item2 = ProductModel(id: '', name: 'All 2');
      final addedItem1 = await repository.addAutoIdentified(
        item1,
        updateObjectWithId: (obj, id) => obj.copyWith(id: id),
      );
      final addedItem2 = await repository.addAutoIdentified(
        item2,
        updateObjectWithId: (obj, id) => obj.copyWith(id: id),
      );

      final results = await repository.query(); // Default is AllQuery
      expect(results, containsAll([addedItem1, addedItem2]));
      expect(results.length, 2);
    });

    test('query returns filtered items', () async {
      final item1 = ProductModel(id: '', name: 'Filter 1');
      final item2 = ProductModel(id: '', name: 'Keep Me');
      final item3 = ProductModel(id: '', name: 'Filter 3');

      await repository.addAutoIdentified(
        item1,
        updateObjectWithId: (obj, id) => obj.copyWith(id: id),
      );
      final addedItem2 = await repository.addAutoIdentified(
        item2,
        updateObjectWithId: (obj, id) => obj.copyWith(id: id),
      );
      await repository.addAutoIdentified(
        item3,
        updateObjectWithId: (obj, id) => obj.copyWith(id: id),
      );

      final query = QueryByName('Keep Me');
      final results = await repository.query(query: query);

      expect(results, [addedItem2]);
      expect(results.length, 1);
    });

    // --- Stream Tests ---

    test('stream emits existing item and updates', () async {
      final item = ProductModel(id: '', name: 'Stream Initial');
      final addedItem = await repository.addAutoIdentified(
        item,
        updateObjectWithId: (obj, id) => obj.copyWith(id: id),
      );

      final stream = repository.stream(addedItem.id);
      final updatedItem = addedItem.copyWith(name: 'Stream Updated');

      expect(
          stream,
          emitsInOrder([
            addedItem,
            updatedItem,
          ]));

      await Future.delayed(Duration.zero);

      // Trigger update
      await repository.update(addedItem.id, (_) => updatedItem);
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
      final stream = repository.stream('future_item_id');
      final itemToAdd = ProductModel(id: 'future_item_id', name: 'Added Late');

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

      await repository.add(IdentifiedObject('future_item_id', itemToAdd));
    });

    test('stream emits notFound error after deletion', () async {
      final item = ProductModel(id: '', name: 'Stream Delete');
      final addedItem = await repository.addAutoIdentified(
        item,
        updateObjectWithId: (obj, id) => obj.copyWith(id: id),
      );

      final stream = repository.stream(addedItem.id);

      expect(
          stream,
          emitsInOrder([
            addedItem, // Initial emit
            // Then emits error because item is deleted
            emitsError(isA<RepositoryException>()
                .having((e) => e.code, 'code', RepositoryErrorCode.notFound)),
            // emitsDone // Stream should also close after delete notification
          ]));

      await Future.delayed(Duration.zero);

      await repository.delete(addedItem.id);

      await Future.delayed(Duration.zero);
    });

    test('streamQuery AllQuery emits initial list and updates', () async {
      final item1 = ProductModel(id: '', name: 'QStream 1');
      final item2 = ProductModel(id: '', name: 'QStream 2');

      final stream = repository.streamQuery(); // Default is AllQuery

      expect(
          stream,
          emitsInOrder([
            <ProductModel>[], // Initial empty list
            emits(predicate<List<ProductModel>>((list) =>
                list.length == 1 &&
                list.first.name == 'QStream 1')), // After adding item1
            emits(predicate<List<ProductModel>>((list) =>
                list.length == 2 &&
                list.any((item) => item.name == 'QStream 1') &&
                list.any(
                    (item) => item.name == 'QStream 2'))), // After adding item2
          ]));

      // Add items after stream subscription
      await repository.addAutoIdentified(
        item1,
        updateObjectWithId: (obj, id) => obj.copyWith(id: id),
      );
      await repository.addAutoIdentified(
        item2,
        updateObjectWithId: (obj, id) => obj.copyWith(id: id),
      );
    });

    test('streamQuery with FilterQuery emits initial filtered list and updates',
        () async {
      final filterQuery = QueryByName('Keep');
      final itemToKeep1 = ProductModel(id: '', name: 'Keep');
      final itemToFilter = ProductModel(id: '', name: 'Filter Me');
      final itemToKeep2 = ProductModel(id: '', name: 'Keep');

      final stream = repository.streamQuery(query: filterQuery);

      expect(
          stream,
          emitsInOrder([
            <ProductModel>[], // Initial empty (filtered) list
            emits(predicate<List<ProductModel>>((list) =>
                list.length == 1 &&
                list.first.name == 'Keep')), // After adding Keep 1
            emits(predicate<List<ProductModel>>((list) =>
                list.length == 1 &&
                list.first.name ==
                    'Keep')), // After adding Filter Me (filtered list unchanged)
            emits(predicate<List<ProductModel>>((list) =>
                list.length == 2 &&
                list.every(
                    (item) => item.name == 'Keep'))), // After adding Keep 2
          ]));

      // Add items after stream subscription
      await repository.addAutoIdentified(
        itemToKeep1,
        updateObjectWithId: (obj, id) => obj.copyWith(id: id),
      );
      await repository.addAutoIdentified(
        itemToFilter,
        updateObjectWithId: (obj, id) => obj.copyWith(id: id),
      );
      await repository.addAutoIdentified(
        itemToKeep2,
        updateObjectWithId: (obj, id) => obj.copyWith(id: id),
      );
    });

    test('streamQuery handles deletion correctly', () async {
      final item1 = ProductModel(id: '', name: 'QS Del 1');
      final item2 = ProductModel(id: '', name: 'QS Del 2');
      final addedItem1 = await repository.addAutoIdentified(
        item1,
        updateObjectWithId: (obj, id) => obj.copyWith(id: id),
      );
      final addedItem2 = await repository.addAutoIdentified(
        item2,
        updateObjectWithId: (obj, id) => obj.copyWith(id: id),
      );

      final stream = repository.streamQuery(); // AllQuery

      expect(
          stream,
          emitsInOrder([
            emits(predicate<List<ProductModel>>((list) =>
                list.length == 2 &&
                list.any((item) => item.name == 'QS Del 1') &&
                list.any((item) => item.name == 'QS Del 2'))), // Initial list
            emits(predicate<List<ProductModel>>((list) =>
                list.length == 1 &&
                list.first.name == 'QS Del 2')), // After deleting item1
            <ProductModel>[], // After deleting item2
          ]));

      // Delete items after stream subscription
      await repository.delete(addedItem1.id);
      await repository.delete(addedItem2.id);
    });

    // --- Batch Operation Tests ---

    test('addAll adds multiple items and returns them', () async {
      final item1 = ProductModel(id: '', name: 'Batch 1');
      final item2 = ProductModel(id: '', name: 'Batch 2');

      final identifiedItem1 = repository.autoIdentify(
        item1,
        updateObjectWithId: (obj, id) => obj.copyWith(id: id),
      );
      final identifiedItem2 = repository.autoIdentify(
        item2,
        updateObjectWithId: (obj, id) => obj.copyWith(id: id),
      );

      final itemsToAdd = [identifiedItem1, identifiedItem2];
      final addedItems = await repository.addAll(itemsToAdd);

      expect(addedItems, containsAll(itemsToAdd.map((e) => e.object)));
      expect(addedItems.length, itemsToAdd.length);

      final results = await repository.query();
      expect(results, containsAll(itemsToAdd.map((e) => e.object)));
      expect(results.length, 2);
      // Check specific IDs
      expect(await repository.get(identifiedItem1.id), identifiedItem1.object);
      expect(await repository.get(identifiedItem2.id), identifiedItem2.object);
    });

    test('updateAll updates multiple items', () async {
      final item1 = ProductModel(id: '', name: 'UpdateAll 1 Initial');
      final item2 = ProductModel(id: '', name: 'UpdateAll 2 Initial');
      final addedItem1 = await repository.addAutoIdentified(
        item1,
        updateObjectWithId: (obj, id) => obj.copyWith(id: id),
      );
      final addedItem2 = await repository.addAutoIdentified(
        item2,
        updateObjectWithId: (obj, id) => obj.copyWith(id: id),
      );

      final updates = [
        IdentifiedObject(
            addedItem1.id, addedItem1.copyWith(name: 'UpdateAll 1 Updated')),
        IdentifiedObject(
            addedItem2.id, addedItem2.copyWith(name: 'UpdateAll 2 Updated')),
      ];

      final updatedItems = await repository.updateAll(updates);

      expect(updatedItems.length, 2);
      expect(updatedItems.map((e) => e.name),
          containsAll(['UpdateAll 1 Updated', 'UpdateAll 2 Updated']));

      expect((await repository.get(addedItem1.id)).name, 'UpdateAll 1 Updated');
      expect((await repository.get(addedItem2.id)).name, 'UpdateAll 2 Updated');
    });

    test('updateAll throws notFound if any item doesnt exist', () async {
      final item1 = ProductModel(id: '', name: 'UpdateAll Exists');
      final addedItem1 = await repository.addAutoIdentified(
        item1,
        updateObjectWithId: (obj, id) => obj.copyWith(id: id),
      );

      final updates = [
        IdentifiedObject(addedItem1.id,
            addedItem1.copyWith(name: 'UpdateAll Exists Updated')),
        IdentifiedObject('non_existent',
            ProductModel(id: 'non_existent', name: 'UpdateAll NonExistent')),
      ];

      expect(
        () => repository.updateAll(updates),
        throwsA(isA<RepositoryException>()
            .having((e) => e.code, 'code', RepositoryErrorCode.notFound)
            .having((e) => e.message, 'message', contains('non_existent'))),
      );

      // Check that the valid item wasn't updated (atomic failure)
      expect((await repository.get(addedItem1.id)).name, 'UpdateAll Exists');
    });

    test('deleteAll removes multiple items', () async {
      final item1 = ProductModel(id: '', name: 'DeleteAll 1');
      final item2 = ProductModel(id: '', name: 'DeleteAll 2');
      final item3 = ProductModel(id: '', name: 'DeleteAll 3');
      final addedItem1 = await repository.addAutoIdentified(
        item1,
        updateObjectWithId: (obj, id) => obj.copyWith(id: id),
      );
      final addedItem2 = await repository.addAutoIdentified(
        item2,
        updateObjectWithId: (obj, id) => obj.copyWith(id: id),
      );
      final addedItem3 = await repository.addAutoIdentified(
        item3,
        updateObjectWithId: (obj, id) => obj.copyWith(id: id),
      );

      await repository.deleteAll([addedItem1.id, addedItem3.id]);

      final results = await repository.query();
      expect(results, [addedItem2]); // Only item2 should remain
      expect(results.length, 1);

      // Verify deletion
      expect(() => repository.get(addedItem1.id),
          throwsA(isA<RepositoryException>()));
      expect(() => repository.get(addedItem3.id),
          throwsA(isA<RepositoryException>()));
    });

    // --- Auto-Identify Tests ---

    test('autoIdentify creates IdentifiedObject with generated ID', () async {
      final item = ProductModel(id: '', name: 'Auto Identify Test');
      final identifiedObject = repository.autoIdentify(
        item,
        updateObjectWithId: (obj, id) => obj.copyWith(id: id),
      );

      expect(identifiedObject.id, isNotEmpty);
      expect(identifiedObject.object.id, identifiedObject.id);
      expect(identifiedObject.object.name, 'Auto Identify Test');
    });

    test('addAutoIdentified adds item with generated ID', () async {
      final item = ProductModel(id: '', name: 'Auto Add Test');
      final addedItem = await repository.addAutoIdentified(
        item,
        updateObjectWithId: (obj, id) => obj.copyWith(id: id),
      );

      expect(addedItem.id, isNotEmpty);
      expect(addedItem.name, 'Auto Add Test');

      final retrievedItem = await repository.get(addedItem.id);
      expect(retrievedItem, addedItem);
    });

    test('can fetch object created with autoIdentify', () async {
      final originalItem = ProductModel(id: '', name: 'Fetch Sample Product');

      // Create identified object using autoIdentify
      final identifiedObject = repository.autoIdentify(
        originalItem,
        updateObjectWithId: (obj, id) => obj.copyWith(id: id),
      );

      // Add it to the repository
      final addedItem = await repository.add(identifiedObject);

      // Fetch it back using the generated ID
      final fetchedItem = await repository.get(identifiedObject.id);

      // Verify the fetched item matches expectations
      expect(fetchedItem.id, identifiedObject.id);
      expect(fetchedItem.name, 'Fetch Sample Product');
      expect(fetchedItem, addedItem);
      expect(fetchedItem, identifiedObject.object);
    });
  });
}

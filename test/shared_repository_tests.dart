import 'dart:async';

import 'package:kiss_repository/src/repository.dart';
import 'package:test/test.dart';

class TestObject {
  const TestObject({required this.name, required this.value, this.id});

  factory TestObject.fromJson(Map<String, dynamic> json) {
    return TestObject(
      id: json['id'] as String?,
      name: json['name'] as String,
      value: json['value'] as int,
    );
  }
  
  final String? id;
  final String name;
  final int value;

  TestObject copyWith({String? id, String? name, int? value}) {
    return TestObject(
      id: id ?? this.id,
      name: name ?? this.name,
      value: value ?? this.value,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'value': value,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TestObject &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          value == other.value;

  @override
  int get hashCode => Object.hash(id, name, value);
}

void runRepositoryTests<T extends Repository<TestObject>>(
  String description,
  T Function() createRepository,
  void Function()? cleanup,
) {
  group(description, () {
    late T repository;

    setUp(() {
      repository = createRepository();
    });

    tearDown(() {
      repository.dispose();
      cleanup?.call();
    });

    group('CRUD Operations', () {
      test('add and get an item', () async {
        final object = TestObject(name: 'Test Item', value: 42);
        final identified = IdentifiedObject('test-1', object);
        
        final added = await repository.add(identified);
        expect(added, equals(object));
        
        final retrieved = await repository.get('test-1');
        expect(retrieved, equals(object));
      });

      test('add with auto-identification', () async {
        final object = TestObject(name: 'Auto ID Item', value: 99);
        
        final added = await repository.addAutoIdentified(
          object,
          updateObjectWithId: (obj, id) => obj.copyWith(id: id),
        );
        
        expect(added.id, isNotNull);
        expect(added.name, equals('Auto ID Item'));
        expect(added.value, equals(99));
      });

      test('throws when getting non-existent item', () async {
        expect(
          () => repository.get('non-existent'),
          throwsA(
            isA<RepositoryException>()
                .having((e) => e.code, 'code', RepositoryErrorCode.notFound)
                .having((e) => e.message, 'message', contains('non-existent')),
          ),
        );
      });

      test('throws when adding duplicate item', () async {
        final object = TestObject(name: 'Duplicate', value: 1);
        await repository.add(IdentifiedObject('dup-1', object));
        
        expect(
          () => repository.add(IdentifiedObject('dup-1', object)),
          throwsA(
            isA<RepositoryException>()
                .having(
                  (e) => e.code,
                  'code',
                  RepositoryErrorCode.alreadyExists,
                )
                .having((e) => e.message, 'message', contains('dup-1')),
          ),
        );
      });

      test('update an item', () async {
        final original = TestObject(name: 'Original', value: 1);
        await repository.add(IdentifiedObject('update-1', original));
        
        final updated = await repository.update(
          'update-1',
          (current) => current.copyWith(name: 'Updated', value: 2),
        );
        
        expect(updated.name, equals('Updated'));
        expect(updated.value, equals(2));
        
        final retrieved = await repository.get('update-1');
        expect(retrieved, equals(updated));
      });

      test('throws when updating non-existent item', () async {
        expect(
          () => repository.update(
            'non-existent',
            (current) => current.copyWith(name: 'Never'),
          ),
          throwsA(
            isA<RepositoryException>()
                .having((e) => e.code, 'code', RepositoryErrorCode.notFound),
          ),
        );
      });

      test('delete an item', () async {
        final object = TestObject(name: 'To Delete', value: 1);
        await repository.add(IdentifiedObject('delete-1', object));
        
        await repository.delete('delete-1');
        
        expect(
          () => repository.get('delete-1'),
          throwsA(isA<RepositoryException>()),
        );
      });

      test('throws when deleting non-existent item', () async {
        expect(
          () => repository.delete('non-existent'),
          throwsA(
            isA<RepositoryException>()
                .having((e) => e.code, 'code', RepositoryErrorCode.notFound),
          ),
        );
      });
    });

    group('Batch Operations', () {
      test('addAll adds multiple items', () async {
        final items = [
          IdentifiedObject('batch-1', TestObject(name: 'Item 1', value: 1)),
          IdentifiedObject('batch-2', TestObject(name: 'Item 2', value: 2)),
          IdentifiedObject('batch-3', TestObject(name: 'Item 3', value: 3)),
        ];
        
        final added = await repository.addAll(items);
        expect(added.length, equals(3));
        
        final item1 = await repository.get('batch-1');
        expect(item1.name, equals('Item 1'));
        
        final item2 = await repository.get('batch-2');
        expect(item2.name, equals('Item 2'));
        
        final item3 = await repository.get('batch-3');
        expect(item3.name, equals('Item 3'));
      });

      test('addAll throws if any item already exists', () async {
        await repository.add(
          IdentifiedObject('existing', TestObject(name: 'Existing', value: 0)),
        );
        
        final items = [
          IdentifiedObject('new-1', TestObject(name: 'New 1', value: 1)),
          IdentifiedObject('existing', TestObject(name: 'Duplicate', value: 2)),
        ];
        
        expect(
          () => repository.addAll(items),
          throwsA(isA<RepositoryException>()),
        );
      });

      test('updateAll updates multiple items', () async {
        final items = [
          IdentifiedObject('up-1', TestObject(name: 'Item 1', value: 1)),
          IdentifiedObject('up-2', TestObject(name: 'Item 2', value: 2)),
        ];
        await repository.addAll(items);
        
        final updates = [
          IdentifiedObject('up-1', TestObject(name: 'Updated 1', value: 10)),
          IdentifiedObject('up-2', TestObject(name: 'Updated 2', value: 20)),
        ];
        
        final updated = await repository.updateAll(updates);
        expect(updated.length, equals(2));
        
        final item1 = await repository.get('up-1');
        expect(item1.name, equals('Updated 1'));
        expect(item1.value, equals(10));
        
        final item2 = await repository.get('up-2');
        expect(item2.name, equals('Updated 2'));
        expect(item2.value, equals(20));
      });

      test('updateAll throws if any item does not exist', () async {
        await repository.add(
          IdentifiedObject('exists', TestObject(name: 'Exists', value: 1)),
        );
        
        final updates = [
          IdentifiedObject('exists', TestObject(name: 'Update', value: 2)),
          IdentifiedObject('missing', TestObject(name: 'Missing', value: 3)),
        ];
        
        expect(
          () => repository.updateAll(updates),
          throwsA(isA<RepositoryException>()),
        );
      });

      test('deleteAll deletes multiple items', () async {
        final items = [
          IdentifiedObject('del-1', TestObject(name: 'Item 1', value: 1)),
          IdentifiedObject('del-2', TestObject(name: 'Item 2', value: 2)),
          IdentifiedObject('del-3', TestObject(name: 'Item 3', value: 3)),
        ];
        await repository.addAll(items);
        
        await repository.deleteAll(['del-1', 'del-3']);
        
        expect(
          () => repository.get('del-1'),
          throwsA(isA<RepositoryException>()),
        );
        expect(await repository.get('del-2'), isNotNull);
        expect(
          () => repository.get('del-3'),
          throwsA(isA<RepositoryException>()),
        );
      });

      test('deleteAll silently ignores non-existent items', () async {
        await repository.add(
          IdentifiedObject('exists', TestObject(name: 'Exists', value: 1)),
        );
        
        await expectLater(
          repository.deleteAll(['exists', 'missing-1', 'missing-2']),
          completes,
        );
        
        expect(
          () => repository.get('exists'),
          throwsA(isA<RepositoryException>()),
        );
      });
    });

    group('Query Operations', () {
      setUp(() async {
        final items = [
          IdentifiedObject('q-1', TestObject(name: 'Apple', value: 10)),
          IdentifiedObject('q-2', TestObject(name: 'Banana', value: 20)),
          IdentifiedObject('q-3', TestObject(name: 'Cherry', value: 30)),
          IdentifiedObject('q-4', TestObject(name: 'Date', value: 40)),
        ];
        await repository.addAll(items);
      });

      test('query returns all items with AllQuery', () async {
        final results = await repository.query();
        expect(results.length, equals(4));
      });

      test('query returns all items when no query specified', () async {
        final results = await repository.query();
        expect(results.length, equals(4));
      });
    });

    group('Stream Operations', () {
      test('stream emits current value immediately', () async {
        final object = TestObject(name: 'Stream Test', value: 1);
        await repository.add(IdentifiedObject('stream-1', object));
        
        final stream = repository.stream('stream-1');
        final firstValue = await stream.first;
        
        expect(firstValue, equals(object));
      });

      test('stream emits updates', () async {
        final original = TestObject(name: 'Original', value: 1);
        await repository.add(IdentifiedObject('stream-2', original));
        
        final stream = repository.stream('stream-2');
        final values = <TestObject>[];
        final subscription = stream.listen(values.add);
        
        await Future<void>.delayed(const Duration(milliseconds: 10));
        
        await repository.update(
          'stream-2',
          (current) => current.copyWith(name: 'Updated'),
        );
        
        await Future<void>.delayed(const Duration(milliseconds: 10));
        
        expect(values.length, equals(2));
        expect(values[0].name, equals('Original'));
        expect(values[1].name, equals('Updated'));
        
        await subscription.cancel();
      });

      test('stream closes on delete', () async {
        final object = TestObject(name: 'To Delete', value: 1);
        await repository.add(IdentifiedObject('stream-3', object));
        
        final stream = repository.stream('stream-3');
        final completer = Completer<void>();
        
        stream.listen(
          (_) {},
          onDone: completer.complete,
        );
        
        await repository.delete('stream-3');
        
        await expectLater(completer.future, completes);
      });

      test('stream emits error for non-existent item', () async {
        final stream = repository.stream('non-existent');
        
        expect(
          stream,
          emitsError(
            isA<RepositoryException>()
                .having((e) => e.code, 'code', RepositoryErrorCode.notFound),
          ),
        );
      });

      test('streamQuery emits all items initially', () async {
        final items = [
          IdentifiedObject('sq-1', TestObject(name: 'Item 1', value: 1)),
          IdentifiedObject('sq-2', TestObject(name: 'Item 2', value: 2)),
        ];
        await repository.addAll(items);
        
        final stream = repository.streamQuery();
        final firstBatch = await stream.first;
        
        expect(firstBatch.length, greaterThanOrEqualTo(2));
      });

      test('streamQuery updates when items change', () async {
        final stream = repository.streamQuery();
        final values = <List<TestObject>>[];
        final subscription = stream.listen(values.add);
        
        await Future<void>.delayed(const Duration(milliseconds: 10));
        
        await repository.add(
          IdentifiedObject('sq-3', TestObject(name: 'New Item', value: 99)),
        );
        
        await Future<void>.delayed(const Duration(milliseconds: 10));
        
        expect(values.length, greaterThanOrEqualTo(2));
        expect(
          values.last.any((item) => item.name == 'New Item'),
          isTrue,
        );
        
        await subscription.cancel();
      });
    });

    group('Auto-identification', () {
      test('autoIdentify generates unique IDs', () {
        final object1 = TestObject(name: 'Object 1', value: 1);
        final object2 = TestObject(name: 'Object 2', value: 2);
        
        final identified1 = repository.autoIdentify(object1);
        final identified2 = repository.autoIdentify(object2);
        
        expect(identified1.id, isNotNull);
        expect(identified2.id, isNotNull);
        expect(identified1.id, isNot(equals(identified2.id)));
      });

      test('autoIdentify with updateObjectWithId', () {
        final object = TestObject(name: 'Test', value: 1);
        
        final identified = repository.autoIdentify(
          object,
          updateObjectWithId: (obj, id) => obj.copyWith(id: id),
        );
        
        expect(identified.id, isNotNull);
        expect(identified.object.id, equals(identified.id));
      });
    });
  });
}

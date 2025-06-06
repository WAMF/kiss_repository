import 'package:test/test.dart';
import 'package:kiss_repository/kiss_repository.dart';

import '../data/test_object.dart';

/// Run basic streaming integration tests on any Repository<TestObject> implementation
void runBasicStreamingTests(Repository<TestObject> Function() repositoryFactory) {
  group('Basic Streaming Operations', () {
    test('should stream single document changes', () async {
      final repository = repositoryFactory();

      // Create an object first
      final testObject = TestObject.create(
        name: 'Initial Name',
        created: DateTime.now(),
      );

      final createdObject = await repository.addAutoIdentified(
        testObject,
        updateObjectWithId: (object, id) => object.copyWith(id: id),
      );

      final stream = repository.stream(createdObject.id);
      final streamFuture = stream.take(3).toList();

      // Make updates
      await repository.update(
        createdObject.id,
        (current) => current.copyWith(name: 'Updated Name 1'),
      );
      await repository.update(
        createdObject.id,
        (current) => current.copyWith(name: 'Updated Name 2'),
      );

      final emissions = await streamFuture.timeout(Duration(seconds: 15));

      expect(emissions.length, 3);
      expect(emissions[0].name, 'Initial Name');
      expect(emissions[1].name, 'Updated Name 1');
      expect(emissions[2].name, 'Updated Name 2');
      print('✅ Streamed single document changes successfully');
    });

    test('should stream query results changes', () async {
      final repository = repositoryFactory();

      final stream = repository.streamQuery();
      final streamFuture = stream.take(4).toList();

      await Future.delayed(Duration(milliseconds: 200));

      // Add first object
      final object1 = TestObject.create(name: 'Object 1', created: DateTime.now());
      final createdObject1 = await repository.addAutoIdentified(
        object1,
        updateObjectWithId: (object, id) => object.copyWith(id: id),
      );

      // Add second object
      final object2 = TestObject.create(name: 'Object 2', created: DateTime.now());
      await repository.addAutoIdentified(
        object2,
        updateObjectWithId: (object, id) => object.copyWith(id: id),
      );

      // Update first object
      await repository.update(
        createdObject1.id,
        (current) => current.copyWith(name: 'Updated Object 1'),
      );

      final emissions = await streamFuture.timeout(Duration(seconds: 15));

      expect(emissions.length, 4);
      expect(emissions[0].length, 0); // Initial empty state
      expect(emissions[1].length, 1); // After first add
      expect(emissions[1][0].name, 'Object 1');
      expect(emissions[2].length, 2); // After second add
      expect(emissions[3].length, 2); // After update
      expect(
        emissions[3].firstWhere((obj) => obj.id == createdObject1.id).name,
        'Updated Object 1',
      );
      print('✅ Streamed query results changes successfully');
    });

    test('should handle multiple concurrent streams', () async {
      final repository = repositoryFactory();

      // Create two objects
      final object1 = TestObject.create(name: 'Object 1', created: DateTime.now());
      final createdObject1 = await repository.addAutoIdentified(
        object1,
        updateObjectWithId: (object, id) => object.copyWith(id: id),
      );

      final object2 = TestObject.create(name: 'Object 2', created: DateTime.now());
      final createdObject2 = await repository.addAutoIdentified(
        object2,
        updateObjectWithId: (object, id) => object.copyWith(id: id),
      );

      final stream1 = repository.stream(createdObject1.id);
      final stream2 = repository.stream(createdObject2.id);
      final queryStream = repository.streamQuery();

      final stream1Future = stream1.take(2).toList();
      final stream2Future = stream2.take(2).toList();
      final queryStreamFuture = queryStream.take(3).toList();

      // Update both objects
      await repository.update(
        createdObject1.id,
        (current) => current.copyWith(name: 'Updated Object 1'),
      );
      await repository.update(
        createdObject2.id,
        (current) => current.copyWith(name: 'Updated Object 2'),
      );

      final stream1Emissions = await stream1Future.timeout(Duration(seconds: 15));
      final stream2Emissions = await stream2Future.timeout(Duration(seconds: 15));
      final queryEmissions = await queryStreamFuture.timeout(Duration(seconds: 15));

      expect(stream1Emissions.length, 2);
      expect(stream1Emissions[0].name, 'Object 1');
      expect(stream1Emissions[1].name, 'Updated Object 1');

      expect(stream2Emissions.length, 2);
      expect(stream2Emissions[0].name, 'Object 2');
      expect(stream2Emissions[1].name, 'Updated Object 2');

      expect(queryEmissions.length, 3);
      expect(queryEmissions[0].length, 2); // Initial state with both objects
      expect(queryEmissions[2].length, 2); // After both updates
      print('✅ Handled multiple concurrent streams successfully');
    });

    test('should handle streaming initially non-existent document', () async {
      final repository = repositoryFactory();

      // Create a placeholder object to get a valid ID format
      final placeholderObject = TestObject.create(name: 'Placeholder', created: DateTime.now());
      final placeholder = await repository.addAutoIdentified(
        placeholderObject,
        updateObjectWithId: (object, id) => object.copyWith(id: id),
      );
      final testId = placeholder.id;

      // Delete the placeholder so we can test streaming non-existent
      await repository.delete(testId);

      final stream = repository.stream(testId);

      // Create the object after starting the stream
      final testObject = TestObject.create(name: 'Created Later', created: DateTime.now());
      final streamFuture = stream.take(1).toList();

      // Add the object with the specific ID
      await repository.add(IdentifiedObject(testId, testObject.copyWith(id: testId)));

      final emissions = await streamFuture.timeout(Duration(seconds: 15));

      expect(emissions.length, 1);
      expect(emissions[0].name, 'Created Later');
      expect(emissions[0].id, testId);
      print('✅ Handled streaming initially non-existent document');
    });

    test('should stop emitting when document is deleted', () async {
      final repository = repositoryFactory();

      final testObject = TestObject.create(name: 'To Be Deleted', created: DateTime.now());
      final createdObject = await repository.addAutoIdentified(
        testObject,
        updateObjectWithId: (object, id) => object.copyWith(id: id),
      );

      final stream = repository.stream(createdObject.id);
      final emissions = <TestObject>[];

      final subscription = stream.listen((obj) {
        emissions.add(obj);
      });

      await Future.delayed(Duration(milliseconds: 500));

      await repository.delete(createdObject.id);

      await Future.delayed(Duration(milliseconds: 500));

      await subscription.cancel();

      expect(emissions.length, 1);
      expect(emissions[0].name, 'To Be Deleted');
      print('✅ Stopped emitting when document was deleted');
    });

    test('should emit initial data immediately on stream subscription', () async {
      final repository = repositoryFactory();

      final testObject = TestObject.create(name: 'Immediate Object', created: DateTime.now());
      final createdObject = await repository.addAutoIdentified(
        testObject,
        updateObjectWithId: (object, id) => object.copyWith(id: id),
      );

      final stream = repository.stream(createdObject.id);
      final firstEmission = await stream.first.timeout(Duration(seconds: 10));

      expect(firstEmission.name, 'Immediate Object');
      expect(firstEmission.id, createdObject.id);
      print('✅ Emitted initial data immediately on subscription');
    });
  });
}

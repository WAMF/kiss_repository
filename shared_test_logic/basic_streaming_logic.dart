import 'package:kiss_repository/kiss_repository.dart';

import 'data/test_object.dart';
import 'test_framework.dart';

/// Shared, framework-agnostic test logic for basic streaming operations.
void runBasicStreamingLogic({
  required Repository<TestObject> Function() repositoryFactory,
  required TestFramework framework,
}) {
  framework.group('Basic Streaming Operations', () {
    framework.test('should stream single document changes', () async {
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

      // Give time for the subscription to be fully established
      await Future.delayed(Duration(milliseconds: 500));

      // Make updates with delays to ensure they are processed separately
      await repository.update(
        createdObject.id,
        (current) => current.copyWith(name: 'Updated Name 1'),
      );

      await Future.delayed(Duration(milliseconds: 200));

      await repository.update(
        createdObject.id,
        (current) => current.copyWith(name: 'Updated Name 2'),
      );

      final emissions = await streamFuture.timeout(Duration(seconds: 15));

      framework.expect(emissions.length, framework.equals(3));
      framework.expect(emissions[0].name, framework.equals('Initial Name'));
      framework.expect(emissions[1].name, framework.equals('Updated Name 1'));
      framework.expect(emissions[2].name, framework.equals('Updated Name 2'));
      print('✅ Streamed single document changes successfully');
    });

    framework.test('should stream query results changes', () async {
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

      framework.expect(emissions.length, framework.equals(4));
      framework.expect(emissions[0].length, framework.equals(0));
      framework.expect(emissions[1].length, framework.equals(1));
      framework.expect(emissions[1][0].name, framework.equals('Object 1'));
      framework.expect(emissions[2].length, framework.equals(2));
      framework.expect(emissions[3].length, framework.equals(2));
      framework.expect(
        emissions[3].firstWhere((obj) => obj.id == createdObject1.id).name,
        framework.equals('Updated Object 1'),
      );
      print('✅ Streamed query results changes successfully');
    });

    framework.test('should handle multiple concurrent streams', () async {
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

      // Give time for all subscriptions to be fully established
      await Future.delayed(Duration(milliseconds: 500));

      // Update both objects with delays
      await repository.update(
        createdObject1.id,
        (current) => current.copyWith(name: 'Updated Object 1'),
      );

      await Future.delayed(Duration(milliseconds: 200));

      await repository.update(
        createdObject2.id,
        (current) => current.copyWith(name: 'Updated Object 2'),
      );

      final stream1Emissions = await stream1Future.timeout(Duration(seconds: 15));
      final stream2Emissions = await stream2Future.timeout(Duration(seconds: 15));
      final queryEmissions = await queryStreamFuture.timeout(Duration(seconds: 15));

      framework.expect(stream1Emissions.length, framework.equals(2));
      framework.expect(stream1Emissions[0].name, framework.equals('Object 1'));
      framework.expect(stream1Emissions[1].name, framework.equals('Updated Object 1'));

      framework.expect(stream2Emissions.length, framework.equals(2));
      framework.expect(stream2Emissions[0].name, framework.equals('Object 2'));
      framework.expect(stream2Emissions[1].name, framework.equals('Updated Object 2'));

      framework.expect(queryEmissions.length, framework.equals(3));
      framework.expect(queryEmissions[0].length, framework.equals(2));
      framework.expect(queryEmissions[2].length, framework.equals(2));
      print('✅ Handled multiple concurrent streams successfully');
    });

    framework.test('should emit error for non-existent document', () async {
      final repository = repositoryFactory();

      // Generate a properly formatted ID using the repository's interface, but don't add it
      final autoIdentified = repository.autoIdentify(
        TestObject.create(name: 'Dummy', created: DateTime.now()),
        updateObjectWithId: (object, id) => object.copyWith(id: id),
      );
      final nonExistentId = autoIdentified.id; 

      final stream = repository.stream(nonExistentId);

      // Should emit error immediately for non-existent document (consistent with get() behavior)
      framework.expect(
        () => stream.first,
        framework.throwsA(framework.isA<RepositoryException>()),
      );

      print('✅ Emitted error for non-existent document');
    });

    framework.test('should stop emitting when document is deleted', () async {
      final repository = repositoryFactory();
      final testObject = TestObject.create(name: 'To Be Deleted', created: DateTime.now());
      final createdObject = await repository.addAutoIdentified(
        testObject,
        updateObjectWithId: (object, id) => object.copyWith(id: id),
      );
      final stream = repository.stream(createdObject.id);
      final emissions = <TestObject>[];
      final subscription = stream.listen((obj) => emissions.add(obj));
      await Future.delayed(Duration(milliseconds: 500));
      await repository.delete(createdObject.id);
      await Future.delayed(Duration(milliseconds: 500));
      await subscription.cancel();

      framework.expect(emissions.length, framework.equals(1));
      framework.expect(emissions[0].name, framework.equals('To Be Deleted'));
      print('✅ Stopped emitting when document was deleted');
    });

    framework.test('should emit initial data immediately on stream subscription', () async {
      final repository = repositoryFactory();
      final testObject = TestObject.create(name: 'Immediate Object', created: DateTime.now());
      final createdObject = await repository.addAutoIdentified(
        testObject,
        updateObjectWithId: (object, id) => object.copyWith(id: id),
      );
      final stream = repository.stream(createdObject.id);
      final firstEmission = await stream.first.timeout(Duration(seconds: 10));

      framework.expect(firstEmission.name, framework.equals('Immediate Object'));
      framework.expect(firstEmission.id, framework.equals(createdObject.id));
      print('✅ Emitted initial data immediately on subscription');
    });
  });
}

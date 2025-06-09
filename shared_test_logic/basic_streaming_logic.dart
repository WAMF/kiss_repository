import 'package:kiss_repository/kiss_repository.dart';

import 'data/test_object.dart';
import 'test_framework.dart';

void runStreamingTests({
  required Repository<TestObject> Function() repositoryFactory,
  required TestFramework framework,
}) {
  framework.group('Basic Streaming Operations', () {
    framework.test('should stream single document changes', () async {
      final repository = repositoryFactory();

      // Create an object first
      final testObject = TestObject.create(name: 'Initial Name');

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
      final object1 = TestObject.create(name: 'Object 1');
      final createdObject1 = await repository.addAutoIdentified(
        object1,
        updateObjectWithId: (object, id) => object.copyWith(id: id),
      );

      // Add second object
      final object2 = TestObject.create(name: 'Object 2');
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

    framework.test('should emit error for non-existent document', () async {
      final repository = repositoryFactory();

      // Generate a properly formatted ID using the repository's interface, but don't add it
      final autoIdentified = repository.autoIdentify(
        TestObject.create(name: 'Dummy'),
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
      final testObject = TestObject.create(name: 'To Be Deleted');
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
      final testObject = TestObject.create(name: 'Immediate Object');
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

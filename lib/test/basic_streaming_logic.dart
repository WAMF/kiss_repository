import 'package:kiss_repository/kiss_repository.dart';
import 'package:kiss_repository/test.dart';

void runStreamingTests({
  required Repository<ProductModel> Function() repositoryFactory,
  required TestFramework framework,
}) {
  framework.group('Basic Streaming Operations', () {
    framework.test('should stream single document changes', () async {
      final repository = repositoryFactory();

      // Create an object first
      final productModel = ProductModel.create(name: 'Initial Name', price: 9.99);

      final createdObject = await repository.addAutoIdentified(
        productModel,
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
      final object1 = ProductModel.create(name: 'Product 1', price: 9.99);
      final createdObject1 = await repository.addAutoIdentified(
        object1,
        updateObjectWithId: (object, id) => object.copyWith(id: id),
      );

      // Add second object
      final object2 = ProductModel.create(name: 'Product 2', price: 9.99);
      await repository.addAutoIdentified(
        object2,
        updateObjectWithId: (object, id) => object.copyWith(id: id),
      );

      // Update first object
      await repository.update(
        createdObject1.id,
        (current) => current.copyWith(name: 'Updated Product 1'),
      );

      final emissions = await streamFuture.timeout(Duration(seconds: 15));

      framework.expect(emissions.length, framework.equals(4));
      framework.expect(emissions[0].length, framework.equals(0));
      framework.expect(emissions[1].length, framework.equals(1));
      framework.expect(emissions[1][0].name, framework.equals('Product 1'));
      framework.expect(emissions[2].length, framework.equals(2));
      framework.expect(emissions[3].length, framework.equals(2));
      framework.expect(
        emissions[3].firstWhere((obj) => obj.id == createdObject1.id).name,
        framework.equals('Updated Product 1'),
      );
      print('✅ Streamed query results changes successfully');
    });

    framework.test('should emit error for non-existent document', () async {
      final repository = repositoryFactory();

      // Generate a properly formatted ID using the repository's interface, but don't add it
      final autoIdentified = repository.autoIdentify(
        ProductModel.create(name: 'Dummy', price: 9.99),
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
      final productModel = ProductModel.create(name: 'To Be Deleted', price: 9.99);
      final createdObject = await repository.addAutoIdentified(
        productModel,
        updateObjectWithId: (object, id) => object.copyWith(id: id),
      );
      final stream = repository.stream(createdObject.id);
      final emissions = <ProductModel>[];
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
      final productModel = ProductModel.create(name: 'Immediate Object', price: 9.99);
      final createdObject = await repository.addAutoIdentified(
        productModel,
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

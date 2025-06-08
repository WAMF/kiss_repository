import 'package:kiss_repository/kiss_repository.dart';

class RepositoryContractTestConfig<T> {
  final Repository<T> Function() repositoryFactory;

  final T Function() createTestObject;

  final String Function(T object) extractId;

  final T Function(T object, String id) updateObjectWithId;

  final Future<void> Function()? setUp;

  final Future<void> Function()? tearDown;

  final Future<void> Function()? setUpAll;

  final Future<void> Function()? tearDownAll;

  const RepositoryContractTestConfig({
    required this.repositoryFactory,
    required this.createTestObject,
    required this.extractId,
    required this.updateObjectWithId,
    this.setUp,
    this.tearDown,
    this.setUpAll,
    this.tearDownAll,
  });
}

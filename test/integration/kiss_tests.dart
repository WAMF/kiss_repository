import 'package:kiss_repository_tests/kiss_repository_tests.dart';

import 'factories/inmemory_repository_factory.dart';

void main() {
  runRepositoryTests(
    implementationName: 'InMemory',
    factoryProvider: InMemoryRepositoryFactory.new,
    cleanup: () {},
  );
}

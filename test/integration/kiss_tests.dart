import 'package:kiss_repository_tests/kiss_repository_tests.dart';
import 'package:test/test.dart';

import 'factories/inmemory_repository_factory.dart';

void main() {
  setUpAll(() async {
    await InMemoryRepositoryFactory.initialize();
  });


  runRepositoryTests(
    implementationName: 'InMemory',
    factoryProvider: InMemoryRepositoryFactory.new,
    cleanup: () {},
  );
}

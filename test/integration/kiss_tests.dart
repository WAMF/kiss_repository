import 'package:kiss_repository_tests/test.dart';
import 'package:test/test.dart';

import 'factories/inmemory_repository_factory.dart';

void main() {
  setUpAll(() async {
    await InMemoryRepositoryFactory.initialize();
  });

  final factory = InMemoryRepositoryFactory();
  final tester = RepositoryTester('InMemory', factory, () {});

  // ignore: cascade_invocations
  tester.run();
}

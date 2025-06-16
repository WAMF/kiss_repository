import 'package:test/test.dart';

import 'inmemory_test_helpers.dart';
import 'kiss_dart_tests.dart';

void main() {
  setUpAll(() async {
    await InMemoryTestHelpers.setupIntegrationTests();
  });

  tearDownAll(() async {
    await InMemoryTestHelpers.tearDownIntegrationTests();
  });

  setUp(() async {
    await InMemoryTestHelpers.clearTestCollection();
  });

  group('InMemory Repository - Centralized CRUD Tests', () {
    runDartCrudTests(() => InMemoryTestHelpers.repository);
  });

  group('Batch Operations Tests', () {
    runDartBatchTests(() => InMemoryTestHelpers.repository);
  });

  group('Query Filtering Tests', () {
    runDartQueryTests(() => InMemoryTestHelpers.repository);
  });

  group('Streaming Tests', () {
    runDartStreamingTests(() => InMemoryTestHelpers.repository);
  });

  group('ID Management Tests', () {
    runDartIdTests(() => InMemoryTestHelpers.repository);
  });
}

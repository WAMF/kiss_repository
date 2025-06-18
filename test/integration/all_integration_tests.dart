import 'package:test/test.dart';

import 'kiss_tests.dart' as kiss_tests;

void main() {
  group('All InMemory Integration Tests', () {
    // KISS Repository Tests using Factory Pattern
    group('KISS Repository Tests (Factory Pattern)', kiss_tests.main);
  });
}

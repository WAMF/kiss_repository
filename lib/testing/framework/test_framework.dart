import 'package:kiss_repository/testing.dart';

typedef TestFunction = Future<void> Function();
typedef GroupFunction = void Function();

typedef RepositoryCleanup = void Function();

typedef RepositoryFactoryProvider = RepositoryFactory Function();

abstract class TestFramework {
  void group(String description, GroupFunction body);
  void test(String description, TestFunction body);
  void setUp(TestFunction body);
  void tearDown(TestFunction body);
  void expect(dynamic actual, dynamic matcher);

  // Matchers used in shared tests
  dynamic get isNotEmpty;
  dynamic get isEmpty;
  dynamic equals(dynamic expected);
  dynamic contains(dynamic value);
  dynamic throwsA(dynamic matcher);
  dynamic isA<T>();
  dynamic get isTrue;
  dynamic isNot(dynamic matcher);
}

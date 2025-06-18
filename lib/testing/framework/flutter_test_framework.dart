import 'package:flutter_test/flutter_test.dart' as flutter_test_pkg;
import 'package:kiss_repository/testing.dart';

class FlutterTestFramework implements TestFramework {
  @override
  void group(String description, GroupFunction body) {
    return flutter_test_pkg.group(description, body);
  }

  @override
  void test(String description, TestFunction body) {
    return flutter_test_pkg.test(description, body);
  }

  @override
  void setUp(TestFunction body) {
    return flutter_test_pkg.setUp(body);
  }

  @override
  void tearDown(TestFunction body) {
    return flutter_test_pkg.tearDown(body);
  }

  @override
  void expect(actual, matcher) {
    return flutter_test_pkg.expect(actual, matcher);
  }

  // Matchers
  @override
  dynamic get isNotEmpty => flutter_test_pkg.isNotEmpty;

  @override
  dynamic get isEmpty => flutter_test_pkg.isEmpty;

  @override
  dynamic equals(expected) => flutter_test_pkg.equals(expected);

  @override
  dynamic contains(value) => flutter_test_pkg.contains(value);

  @override
  dynamic throwsA(matcher) => flutter_test_pkg.throwsA(matcher);

  @override
  dynamic isA<T>() => flutter_test_pkg.isA<T>();

  @override
  dynamic get isTrue => flutter_test_pkg.isTrue;

  @override
  dynamic isNot(matcher) => flutter_test_pkg.isNot(matcher);
}

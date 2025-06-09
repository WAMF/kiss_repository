import 'package:test/test.dart' as test_pkg;
import '../../shared_test_logic/test_framework.dart';

class DartTestFramework implements TestFramework {
  @override
  void group(String description, GroupFunction body) {
    return test_pkg.group(description, body);
  }

  @override
  void test(String description, TestFunction body) {
    return test_pkg.test(description, body);
  }

  @override
  void expect(actual, matcher) {
    return test_pkg.expect(actual, matcher);
  }

  // Matchers
  @override
  dynamic get isNotEmpty => test_pkg.isNotEmpty;

  @override
  dynamic get isEmpty => test_pkg.isEmpty;

  @override
  dynamic equals(expected) => test_pkg.equals(expected);

  @override
  dynamic contains(value) => test_pkg.contains(value);

  @override
  dynamic throwsA(matcher) => test_pkg.throwsA(matcher);

  @override
  dynamic isA<T>() => test_pkg.isA<T>();

  @override
  dynamic get isTrue => test_pkg.isTrue;
}

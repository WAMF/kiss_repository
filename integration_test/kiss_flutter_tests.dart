library kiss_flutter_tests;

import 'package:kiss_repository/kiss_repository.dart';

import '../shared_test_logic/basic_batch_logic.dart';
import '../shared_test_logic/basic_crud_logic.dart';
import '../shared_test_logic/basic_error_logic.dart';
import '../shared_test_logic/basic_query_logic.dart';
import '../shared_test_logic/basic_streaming_logic.dart';
import '../shared_test_logic/data/test_object.dart';
import 'flutter_test_framework.dart';

final _framework = FlutterTestFramework();

void runBasicCrudTests(Repository<TestObject> Function() repositoryFactory) {
  runBasicCrudLogic(
    repositoryFactory: repositoryFactory,
    framework: _framework,
  );
}

void runBasicBatchTests(Repository<TestObject> Function() repositoryFactory) {
  runBasicBatchLogic(
    repositoryFactory: repositoryFactory,
    framework: _framework,
  );
}

void runBasicQueryTests(Repository<TestObject> Function() repositoryFactory) {
  runBasicQueryLogic(
    repositoryFactory: repositoryFactory,
    framework: _framework,
  );
}

void runBasicStreamingTests(Repository<TestObject> Function() repositoryFactory) {
  runBasicStreamingLogic(
    repositoryFactory: repositoryFactory,
    framework: _framework,
  );
}

void runBasicErrorTests(Repository<TestObject> Function() repositoryFactory) {
  runBasicErrorLogic(
    repositoryFactory: repositoryFactory,
    framework: _framework,
  );
}

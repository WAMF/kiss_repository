library kiss_dart_tests;

import 'package:kiss_repository/kiss_repository.dart';

import '../../shared_test_logic/basic_batch_logic.dart' as kiss;
import '../../shared_test_logic/basic_crud_logic.dart' as kiss;
import '../../shared_test_logic/basic_id_logic.dart' as kiss;
import '../../shared_test_logic/basic_query_logic.dart' as kiss;
import '../../shared_test_logic/basic_streaming_logic.dart' as kiss;
import '../../shared_test_logic/data/test_object.dart';
import 'dart_test_framework.dart';

final _framework = DartTestFramework();

void runDartCrudTests(Repository<TestObject> Function() repositoryFactory) {
  kiss.runCrudTests(
    repositoryFactory: repositoryFactory,
    framework: _framework,
  );
}

void runDartBatchTests(Repository<TestObject> Function() repositoryFactory) {
  kiss.runBatchTests(
    repositoryFactory: repositoryFactory,
    framework: _framework,
  );
}

void runDartQueryTests(Repository<TestObject> Function() repositoryFactory) {
  kiss.runQueryTests(
    repositoryFactory: repositoryFactory,
    framework: _framework,
  );
}

void runDartStreamingTests(Repository<TestObject> Function() repositoryFactory) {
  kiss.runStreamingTests(
    repositoryFactory: repositoryFactory,
    framework: _framework,
  );
}

void runDartIdTests(Repository<TestObject> Function() repositoryFactory) {
  kiss.runIdTests(
    repositoryFactory: repositoryFactory,
    framework: _framework,
  );
}

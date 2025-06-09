library;

import 'package:kiss_repository/kiss_repository.dart';

import '../shared_test_logic/basic_batch_logic.dart' as kiss;
import '../shared_test_logic/basic_crud_logic.dart' as kiss;
import '../shared_test_logic/basic_id_logic.dart' as kiss;
import '../shared_test_logic/basic_query_logic.dart' as kiss;
import '../shared_test_logic/basic_streaming_logic.dart' as kiss;
import '../shared_test_logic/data/test_object.dart';
import 'flutter_test_framework.dart';

final _framework = FlutterTestFramework();

void runFlutterCrudTests(Repository<TestObject> Function() repositoryFactory) {
  kiss.runCrudTests(
    repositoryFactory: repositoryFactory,
    framework: _framework,
  );
}

void runFlutterBatchTests(Repository<TestObject> Function() repositoryFactory) {
  kiss.runBatchTests(
    repositoryFactory: repositoryFactory,
    framework: _framework,
  );
}

void runFlutterQueryTests(Repository<TestObject> Function() repositoryFactory) {
  kiss.runQueryTests(
    repositoryFactory: repositoryFactory,
    framework: _framework,
  );
}

void runFlutterStreamingTests(Repository<TestObject> Function() repositoryFactory) {
  kiss.runStreamingTests(
    repositoryFactory: repositoryFactory,
    framework: _framework,
  );
}

void runFlutterIdTests(Repository<TestObject> Function() repositoryFactory) {
  kiss.runIdTests(
    repositoryFactory: repositoryFactory,
    framework: _framework,
  );
}

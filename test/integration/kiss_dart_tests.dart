library kiss_dart_tests;

import 'package:kiss_repository/kiss_repository.dart';

import '../../shared_test_logic/basic_batch_logic.dart' as kiss;
import '../../shared_test_logic/basic_crud_logic.dart' as kiss;
import '../../shared_test_logic/basic_id_logic.dart' as kiss;
import '../../shared_test_logic/basic_query_logic.dart' as kiss;
import '../../shared_test_logic/basic_streaming_logic.dart' as kiss;
import '../../shared_test_logic/data/product_model.dart';
import 'dart_test_framework.dart';

final _framework = DartTestFramework();

void runDartCrudTests(Repository<ProductModel> Function() repositoryFactory) {
  kiss.runCrudTests(
    repositoryFactory: repositoryFactory,
    framework: _framework,
  );
}

void runDartBatchTests(Repository<ProductModel> Function() repositoryFactory) {
  kiss.runBatchTests(
    repositoryFactory: repositoryFactory,
    framework: _framework,
  );
}

void runDartQueryTests(Repository<ProductModel> Function() repositoryFactory) {
  kiss.runQueryTests(
    repositoryFactory: repositoryFactory,
    framework: _framework,
  );
}

void runDartStreamingTests(Repository<ProductModel> Function() repositoryFactory) {
  kiss.runStreamingTests(
    repositoryFactory: repositoryFactory,
    framework: _framework,
  );
}

void runDartIdTests(Repository<ProductModel> Function() repositoryFactory) {
  kiss.runIdTests(
    repositoryFactory: repositoryFactory,
    framework: _framework,
  );
}

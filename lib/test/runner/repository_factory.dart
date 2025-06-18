import 'package:kiss_repository/kiss_repository.dart';
import 'package:kiss_repository/test.dart';

/// Factory interface that each repository implementation must provide
/// to run the shared integration tests.
abstract class RepositoryFactory {
  Repository<ProductModel> createRepository();

  Future<void> cleanup();

  void dispose();
}

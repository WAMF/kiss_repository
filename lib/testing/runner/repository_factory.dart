import 'package:kiss_repository/kiss_repository.dart';
import 'package:kiss_repository/testing.dart';

/// Factory interface that each repository implementation must provide
/// to run the shared integration tests.
abstract class RepositoryFactory {
  /// Create a fresh repository instance for testing
  Repository<ProductModel> createRepository();

  /// Clean up any resources (called after each test group)
  Future<void> cleanup();

  /// Dispose all resources (called at the end of all tests)
  void dispose();
}

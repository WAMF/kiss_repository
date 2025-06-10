import 'package:kiss_repository/kiss_repository.dart';

abstract class RepositoryProvider<T> {
  Future<void> initialize();

  Repository<T> get repository;

  bool get isInitialized;

  void dispose();
}

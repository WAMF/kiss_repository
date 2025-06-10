import 'package:flutter/material.dart';
import 'package:kiss_repository/kiss_repository.dart';

abstract class RepositoryProvider<T> {
  Future<void> initialize();

  Future<void> authenticate(BuildContext context) async {}

  Repository<T> get repository;

  bool get isInitialized;

  void dispose();
}

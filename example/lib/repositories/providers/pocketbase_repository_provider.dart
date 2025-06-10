import 'package:flutter/material.dart';
import 'package:kiss_pocketbase_repository/kiss_pocketbase_repository.dart';
// ignore: depend_on_referenced_packages
import 'package:pocketbase/pocketbase.dart';

import '../../models/product_model.dart';
import '../../utils/logger.dart' as logger;
import '../../widgets/auth_dialog.dart';
import '../query_builders/pocketbase_product_query_builder.dart';
import '../repository_provider.dart';

class PocketBaseRepositoryProvider implements RepositoryProvider<ProductModel> {
  Repository<ProductModel>? _repository;
  final String serverUrl;

  static const String testUserEmail = 'testuser@example.com';
  static const String testUserPassword = 'testuser123';

  late PocketBase _client;

  PocketBaseRepositoryProvider({this.serverUrl = 'http://localhost:8090'});

  @override
  Future<void> authenticate(BuildContext context) async {
    final credentials = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AuthDialog(email: testUserEmail, password: testUserPassword),
    );

    if (credentials == null) return;

    try {
      await _client.collection('users').authWithPassword(testUserEmail, testUserPassword);
      logger.log('🔐 Authenticated as test user: $testUserEmail');
    } catch (e) {
      throw Exception(
        'Failed to authenticate test user. Make sure user exists:\n'
        'Email: $testUserEmail\n'
        'Error: $e',
      );
    }
  }

  @override
  Future<void> initialize() async {
    if (_repository != null) return;

    _client = PocketBase(serverUrl);

    try {
      _repository = RepositoryPocketBase<ProductModel>(
        client: _client,
        collection: 'products',
        fromPocketBase: (record) => ProductModel(
          id: record.id,
          name: record.data['name'] ?? '',
          price: (record.data['price'] ?? 0.0).toDouble(),
          description: record.data['description'] ?? '',
          created: DateTime.parse(record.get<String>('created')),
        ),
        toPocketBase: (product) => {
          'name': product.name,
          'price': product.price,
          'description': product.description,
        },
        queryBuilder: PocketBaseProductQueryBuilder(),
      );

      logger.log('✅ PocketBase repository initialized for $serverUrl');
    } catch (e) {
      logger.log('⚠️ PocketBase initialization error: $e');
      rethrow;
    }
  }

  @override
  Repository<ProductModel> get repository {
    if (_repository == null) {
      throw StateError('Repository not initialized. Call initialize() first.');
    }
    return _repository!;
  }

  @override
  bool get isInitialized => _repository != null;

  @override
  void dispose() {
    _repository?.dispose();
    _repository = null;
  }
}

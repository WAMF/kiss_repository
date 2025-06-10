import 'package:flutter/material.dart';
import 'package:kiss_pocketbase_repository/kiss_pocketbase_repository.dart';
// ignore: depend_on_referenced_packages
import 'package:pocketbase/pocketbase.dart';

import '../../models/user.dart';
import '../../utils/logger.dart' as logger;
import '../../widgets/auth_dialog.dart';
import '../query_builders/pocketbase_user_query_builder.dart';
import '../repository_provider.dart';

class PocketBaseRepositoryProvider implements RepositoryProvider<User> {
  Repository<User>? _repository;
  final String serverUrl;

  static const String testUserEmail = 'testuser@example.com';
  static const String testUserPassword = 'testuser123';

  late PocketBase pocketbaseClient;

  PocketBaseRepositoryProvider({this.serverUrl = 'http://localhost:8090'});

  @override
  Future<void> authenticate(BuildContext context) async {
    final credentials = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AuthDialog(email: testUserEmail, password: testUserPassword),
    );

    if (credentials == null) return;

    try {
      await pocketbaseClient.collection('users').authWithPassword(testUserEmail, testUserPassword);
      print('🔐 Authenticated as test user: $testUserEmail');
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

    pocketbaseClient = PocketBase(serverUrl);

    try {
      _repository = RepositoryPocketBase<User>(
        client: pocketbaseClient,
        collection: 'users',
        fromPocketBase: (record) => User(
          id: record.id,
          name: record.data['name'] ?? '',
          email: record.data['email'] ?? '',
          createdAt: DateTime.parse(record.get<String>('created')),
        ),
        toPocketBase: (user) => {
          'name': user.name,
          'email': user.email,
        },
        queryBuilder: PocketBaseUserQueryBuilder(),
      );

      logger.log('✅ PocketBase repository initialized for $serverUrl');
    } catch (e) {
      logger.log('⚠️ PocketBase initialization error: $e');
      rethrow;
    }
  }

  @override
  Repository<User> get repository {
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

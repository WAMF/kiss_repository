// KISS Repository Example App
//
// This example app demonstrates the capabilities of the kiss_repository
// package with multiple repository implementations:
//
// 1. InMemory Repository for quick testing
// 2. Firebase Repository with real-time streaming
// 3. PocketBase Repository for self-hosted backend
//
// Features demonstrated:
// - Repository pattern with multiple backends
// - Auto-generated IDs using createWithAutoId()
// - Real-time streaming with streamQuery()
// - Full CRUD operations (Create, Read, Update, Delete)
// - Error handling and user feedback
// - Custom Query system with QueryBuilder and search functionality
//
// To run the app:
//   cd example && flutter run -d web
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:kiss_repository/kiss_repository.dart';

import 'dependencies.dart';
import 'models/user.dart';
import 'repositories/repository_factory.dart';
import 'repositories/repository_type.dart';
import 'widgets/add_user_form.dart';
import 'widgets/user_list_widget.dart';
import 'widgets/search_tab.dart';
import 'widgets/recent_users_tab.dart';
import 'widgets/repository_info_widget.dart';
import 'widgets/repository_selector.dart';

void _log(String message) {
  // ignore: avoid_print
  print(message);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize Firebase
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: 'AIzaSyC_l_test_api_key_for_emulator',
        appId: '1:123456789:web:123456789abcdef',
        messagingSenderId: '123456789',
        projectId: 'kiss-test-project',
      ),
    );
    try {
      firestore.FirebaseFirestore.instance.useFirestoreEmulator('0.0.0.0', 8080);
      _log('🔥 Using Firestore emulator at 0.0.0.0:8080');
    } catch (e) {
      _log('⚠️ Could not connect to Firestore emulator: $e');
      _log('💡 Make sure to run: firebase emulators:start --only firestore');
    }

    _log('✅ Firebase initialized successfully');
  } catch (e) {
    _log('⚠️ Firebase initialization error: $e');
  }

  // Initialize dependencies
  await Dependencies.init();
  _log('✅ Dependencies initialized');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KISS Repository Example',
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange), useMaterial3: true),
      home: const UserManagementPage(),
    );
  }
}

class UserManagementPage extends StatefulWidget {
  const UserManagementPage({super.key});

  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> with TickerProviderStateMixin {
  Repository<User>? _userRepository;
  RepositoryType _selectedRepositoryType = RepositoryType.inMemory;
  bool _isRepositorySwitching = false;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeRepository(_selectedRepositoryType);
  }

  Future<void> _initializeRepository(RepositoryType type) async {
    setState(() {
      _isRepositorySwitching = true;
    });

    try {
      // Dispose previous repository if exists
      _userRepository?.dispose();

      final config = <String, dynamic>{};
      if (type == RepositoryType.pocketbase) {
        config['serverUrl'] = 'http://localhost:8090';
      }

      final repository = await RepositoryFactory.create(type, config: config);

      setState(() {
        _userRepository = repository;
        _selectedRepositoryType = type;
      });

      _showSnackBar('Switched to ${type.displayName} repository');
    } catch (e) {
      _showSnackBar('Failed to initialize ${type.displayName}: $e');
      _log('Repository initialization error: $e');
    } finally {
      setState(() {
        _isRepositorySwitching = false;
      });
    }
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _userRepository?.dispose();
    RepositoryFactory.disposeAll();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('KISS Repository Example'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: RepositorySelector(
              selectedType: _selectedRepositoryType,
              isLoading: _isRepositorySwitching,
              onChanged: _initializeRepository,
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.list), text: 'All Users'),
            Tab(icon: Icon(Icons.search), text: 'Search'),
            Tab(icon: Icon(Icons.schedule), text: 'Recent'),
          ],
        ),
      ),
      body: _userRepository == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Add User Form
                AddUserForm(userRepository: _userRepository!),

                // Tabbed Content
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      UserListWidget(userRepository: _userRepository!),
                      SearchTab(userRepository: _userRepository!),
                      RecentUsersTab(userRepository: _userRepository!),
                    ],
                  ),
                ),

                // Repository Info
                const RepositoryInfoWidget(),
              ],
            ),
    );
  }
}

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
import 'package:kiss_dependencies/kiss_dependencies.dart';
import 'package:kiss_repository/kiss_repository.dart';

import 'dependencies.dart';
import 'models/product_model.dart';
import 'repositories/repository_provider.dart';
import 'repositories/repository_type.dart';
import 'widgets/all_products_tab.dart';
import 'widgets/search_tab.dart';
import 'widgets/repository_selector.dart';
import 'widgets/repository_info_widget.dart';
import 'utils/logger.dart' as logger;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Dependencies.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KISS Repository Example',
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange), useMaterial3: true),
      home: const ProductManagementPage(),
    );
  }
}

class ProductManagementPage extends StatefulWidget {
  const ProductManagementPage({super.key});

  @override
  State<ProductManagementPage> createState() => _ProductManagementPageState();
}

class _ProductManagementPageState extends State<ProductManagementPage> with TickerProviderStateMixin {
  Repository<ProductModel>? _productRepository;
  RepositoryType _selectedRepositoryType = RepositoryType.inMemory;
  bool _isRepositorySwitching = false;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializeRepository(_selectedRepositoryType);
  }

  Future<void> _initializeRepository(RepositoryType type) async {
    setState(() {
      _isRepositorySwitching = true;
    });

    try {
      final providerId = _getProviderId(type);
      final provider = resolve<RepositoryProvider<ProductModel>>(identifier: providerId);

      await provider.initialize();
      // ignore: use_build_context_synchronously
      await provider.authenticate(context);

      setState(() {
        _productRepository = provider.repository;
        _selectedRepositoryType = type;
      });

      _showSnackBar('Switched to ${type.displayName} repository');
    } catch (e) {
      _showSnackBar('Failed to initialize ${type.displayName}: $e');
      logger.log('Repository initialization error: $e');
    } finally {
      setState(() {
        _isRepositorySwitching = false;
      });
    }
  }

  String _getProviderId(RepositoryType type) {
    switch (type) {
      case RepositoryType.firebase:
        return 'firebase_product_provider';
      case RepositoryType.pocketbase:
        return 'pocketbase_product_provider';
      case RepositoryType.inMemory:
        return 'inmemory_product_provider';
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
            Tab(icon: Icon(Icons.list), text: 'All Products'),
            Tab(icon: Icon(Icons.search), text: 'Search'),
          ],
        ),
      ),
      body: _productRepository == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      AllProductsTab(productRepository: _productRepository!),
                      SearchTab(productRepository: _productRepository!),
                    ],
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => RepositoryInfoWidget.show(context),
        tooltip: 'Repository Features',
        child: const Icon(Icons.info),
      ),
    );
  }
}

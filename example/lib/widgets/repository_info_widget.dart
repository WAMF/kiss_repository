import 'package:flutter/material.dart';

class RepositoryInfoWidget extends StatelessWidget {
  const RepositoryInfoWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('• Auto-generated repository IDs'),
        const Text('• Real-time streaming updates'),
        const Text('• CRUD operations (Create, Read, Update, Delete)'),
        const Text('• Custom Query system with QueryBuilder'),
        const Text('• Search queries (QueryByName, QueryByPriceGreaterThan/LessThan)'),
        const Text('• Date-based queries (QueryByCreatedAfter/Before)'),
        const Text('• Error handling'),
        const Text('• Multiple backend support (Firebase, PocketBase, InMemory)'),
        const SizedBox(height: 16),
        Text(
          'Collection: products | Query System: ProductModelQueryBuilder',
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  static void show(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Repository Features Demonstrated'),
          content: const SingleChildScrollView(
            child: RepositoryInfoWidget(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}

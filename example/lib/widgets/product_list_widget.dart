import 'package:example/models/product_model.dart';
import 'package:flutter/material.dart';
import 'package:kiss_repository/kiss_repository.dart';

class ProductListWidget extends StatelessWidget {
  const ProductListWidget({
    required this.productRepository,
    super.key,
    this.query = const AllQuery(),
  });
  final Repository<ProductModel> productRepository;
  final Query query;

  Future<void> _deleteProduct(BuildContext context, String productId) async {
    try {
      await productRepository.delete(productId);
      if (context.mounted) {
        _showSnackBar(context, 'Product deleted successfully!');
      }
    } catch (e) {
      if (context.mounted) {
        _showSnackBar(context, 'Error deleting product: $e');
      }
    }
  }

  Future<void> _updateProduct(
    BuildContext context,
    ProductModel product,
  ) async {
    final nameController = TextEditingController(text: product.name);
    final priceController =
        TextEditingController(text: product.price.toString());
    final descriptionController =
        TextEditingController(text: product.description);

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Product'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Product Name'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: priceController,
              decoration:
                  const InputDecoration(labelText: 'Price', prefixText: r'$'),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, {
              'name': nameController.text.trim(),
              'price': priceController.text.trim(),
              'description': descriptionController.text.trim(),
            }),
            child: const Text('Update'),
          ),
        ],
      ),
    );

    if (result != null) {
      final newName = result['name']!;
      final priceText = result['price']!;
      final newDescription = result['description']!;

      if (newName.isEmpty || priceText.isEmpty) {
        // ignore: use_build_context_synchronously
        _showSnackBar(context, 'Name and price are required');
        return;
      }

      final newPrice = double.tryParse(priceText);
      if (newPrice == null || newPrice < 0) {
        // ignore: use_build_context_synchronously
        _showSnackBar(context, 'Please enter a valid price');
        return;
      }

      if (newName != product.name ||
          newPrice != product.price ||
          newDescription != product.description) {
        try {
          await productRepository.update(
            product.id,
            (current) => current.copyWith(
              name: newName,
              price: newPrice,
              description: newDescription,
            ),
          );
          if (context.mounted) {
            _showSnackBar(context, 'Product updated successfully!');
          }
        } catch (e) {
          if (context.mounted) {
            _showSnackBar(context, 'Error updating product: $e');
          }
        }
      }
    }
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  String _formatCreatedDate(DateTime created) {
    final now = DateTime.now();
    final localCreated = created.toLocal();
    final difference = now.difference(localCreated);

    // If it's within the last minute
    if (difference.inMinutes < 1) {
      return 'Just now';
    }
    // If it's within the last hour
    else if (difference.inHours < 1) {
      final minutes = difference.inMinutes;
      return '$minutes minute${minutes == 1 ? '' : 's'} ago';
    }
    // If it's within the last 24 hours
    else if (difference.inDays < 1) {
      final hours = difference.inHours;
      return '$hours hour${hours == 1 ? '' : 's'} ago';
    }
    // If it's within the last week
    else if (difference.inDays < 7) {
      final days = difference.inDays;
      return '$days day${days == 1 ? '' : 's'} ago';
    }
    // For older dates, show the full date
    else {
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      final month = months[localCreated.month - 1];
      final day = localCreated.day;
      final year = localCreated.year;
      final hour = localCreated.hour;
      final minute = localCreated.minute.toString().padLeft(2, '0');
      final amPm = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);

      return '$month $day, $year at $displayHour:$minute $amPm';
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ProductModel>>(
      stream: productRepository.streamQuery(query: query),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                Text('Error: ${snapshot.error}'),
                const SizedBox(height: 8),
                const Text(
                  'Make sure your repository backend is running',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        final products = snapshot.data ?? [];

        if (products.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inventory_outlined, size: 48, color: Colors.grey),
                SizedBox(height: 16),
                Text('No products found'),
                Text(
                  'Try adjusting your search or add some products',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index];
            final createString = _formatCreatedDate(product.created);
            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context).primaryColor,
                  child: Text(
                    product.name.isNotEmpty
                        ? product.name[0].toUpperCase()
                        : '?',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                title: Text(product.name),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '\$${product.price.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    if (product.description.isNotEmpty)
                      Text(product.description),
                    Text(
                      'Created: $createString',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _updateProduct(context, product),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteProduct(context, product.id),
                    ),
                  ],
                ),
                isThreeLine: true,
              ),
            );
          },
        );
      },
    );
  }
}

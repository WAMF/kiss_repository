import 'package:example/models/product_model.dart';
import 'package:example/queries/product_queries.dart';
import 'package:example/widgets/product_list_widget.dart';
import 'package:flutter/material.dart';
import 'package:kiss_repository/kiss_repository.dart';

class SearchTab extends StatefulWidget {
  const SearchTab({required this.productRepository, super.key});
  final Repository<ProductModel> productRepository;

  @override
  State<SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends State<SearchTab> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _minPriceController = TextEditingController();
  final TextEditingController _maxPriceController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  Query _buildQuery() {
    final searchTerm = _searchController.text.trim();
    final minPriceText = _minPriceController.text.trim();
    final maxPriceText = _maxPriceController.text.trim();

    // For now, we'll use the first available filter
    // In a real app, you might want to combine multiple filters
    if (searchTerm.isNotEmpty) {
      return QueryByName(searchTerm);
    }

    if (minPriceText.isNotEmpty) {
      final minPrice = double.tryParse(minPriceText);
      if (minPrice != null) {
        return QueryByPriceGreaterThan(minPrice);
      }
    }

    if (maxPriceText.isNotEmpty) {
      final maxPrice = double.tryParse(maxPriceText);
      if (maxPrice != null) {
        return QueryByPriceLessThan(maxPrice);
      }
    }

    return const AllQuery();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search Controls
        Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Search Products',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),),
              const SizedBox(height: 16),
              TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  labelText: 'Search by name',
                  hintText: 'Enter product name to search...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => setState(() {}),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _minPriceController,
                      decoration: const InputDecoration(
                        labelText: 'Min Price',
                        hintText: '0.00',
                        prefixText: r'$',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (value) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _maxPriceController,
                      decoration: const InputDecoration(
                        labelText: 'Max Price',
                        hintText: '999.99',
                        prefixText: r'$',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (value) => setState(() {}),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => setState(() {}),
                      icon: const Icon(Icons.search),
                      label: const Text('Search'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        _searchController.clear();
                        _minPriceController.clear();
                        _maxPriceController.clear();
                        setState(() {});
                      },
                      icon: const Icon(Icons.clear),
                      label: const Text('Clear'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Search Results
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  _buildSearchResultsTitle(),
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold,),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ProductListWidget(
                    productRepository: widget.productRepository,
                    query: _buildQuery(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _buildSearchResultsTitle() {
    final searchTerm = _searchController.text.trim();
    final minPrice = _minPriceController.text.trim();
    final maxPrice = _maxPriceController.text.trim();

    if (searchTerm.isNotEmpty) {
      return 'Search Results for "$searchTerm"';
    }

    if (minPrice.isNotEmpty) {
      return 'Products over \$$minPrice';
    }

    if (maxPrice.isNotEmpty) {
      return 'Products under \$$maxPrice';
    }

    return 'All Products';
  }
}

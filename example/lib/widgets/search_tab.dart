import 'package:flutter/material.dart';
import 'package:kiss_repository/kiss_repository.dart';
import '../models/product_model.dart';
import '../queries/product_queries.dart';
import 'product_list_widget.dart';

class SearchTab extends StatefulWidget {
  final Repository<ProductModel> productRepository;

  const SearchTab({super.key, required this.productRepository});

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

    // If search term is provided, use name search
    if (searchTerm.isNotEmpty) {
      return QueryByName(searchTerm);
    }

    // Handle price filtering
    final minPrice = minPriceText.isNotEmpty ? double.tryParse(minPriceText) : null;
    final maxPrice = maxPriceText.isNotEmpty ? double.tryParse(maxPriceText) : null;

    if (minPrice != null || maxPrice != null) {
      return QueryByPriceRange(minPrice: minPrice, maxPrice: maxPrice);
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
              const Text('Search Products', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                        prefixText: '\$',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
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
                        prefixText: '\$',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
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
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
    final minPriceText = _minPriceController.text.trim();
    final maxPriceText = _maxPriceController.text.trim();

    if (searchTerm.isNotEmpty) {
      return 'Search Results for "$searchTerm"';
    }

    final minPrice = minPriceText.isNotEmpty ? double.tryParse(minPriceText) : null;
    final maxPrice = maxPriceText.isNotEmpty ? double.tryParse(maxPriceText) : null;

    if (minPrice != null && maxPrice != null) {
      return 'Products between \$${minPrice.toStringAsFixed(2)} - \$${maxPrice.toStringAsFixed(2)}';
    } else if (minPrice != null) {
      return 'Products over \$${minPrice.toStringAsFixed(2)}';
    } else if (maxPrice != null) {
      return 'Products under \$${maxPrice.toStringAsFixed(2)}';
    }

    return 'All Products';
  }
}

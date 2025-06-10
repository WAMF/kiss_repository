import 'package:flutter/material.dart';
import 'package:kiss_repository/kiss_repository.dart';

import '../widgets/add_product_form.dart';
import '../widgets/product_list_widget.dart';
import '../models/product_model.dart';

class AllProductsTab extends StatelessWidget {
  final Repository<ProductModel> productRepository;
  const AllProductsTab({super.key, required this.productRepository});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AddProductForm(productRepository: productRepository),
        Expanded(child: ProductListWidget(productRepository: productRepository)),
      ],
    );
  }
}

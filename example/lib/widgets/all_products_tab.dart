import 'package:example/models/product_model.dart';
import 'package:example/widgets/add_product_form.dart';
import 'package:example/widgets/product_list_widget.dart';
import 'package:flutter/material.dart';
import 'package:kiss_repository/kiss_repository.dart';

class AllProductsTab extends StatelessWidget {
  const AllProductsTab({required this.productRepository, super.key});
  final Repository<ProductModel> productRepository;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AddProductForm(productRepository: productRepository),
        Expanded(
            child: ProductListWidget(productRepository: productRepository),),
      ],
    );
  }
}

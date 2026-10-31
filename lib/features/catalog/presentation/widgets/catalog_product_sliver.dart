import 'package:flutter/material.dart';

import '../../../../design_system/components/product_card.dart';
import 'catalog_rows_sliver.dart';
import '../../models/product.dart';

/// Lazy rows allow each card to grow with its content and the user's text size.
class CatalogProductSliver extends StatelessWidget {
  const CatalogProductSliver({
    super.key,
    required this.products,
    required this.variant,
    required this.availableWidth,
    required this.onProductSelected,
    this.selectedProductId,
  });

  final List<Product> products;
  final int? selectedProductId;
  final ProductCardVariant variant;
  final double availableWidth;
  final ValueChanged<Product> onProductSelected;

  Widget _card(Product product) => ProductCard(
    key: ValueKey(product.id),
    title: product.title,
    selected: product.id == selectedProductId,
    brand: product.brand,
    category: product.category,
    imageUrl: product.thumbnail,
    price: product.discountedPrice,
    originalPrice: product.price,
    rating: product.rating,
    reviewCount: product.reviewCount,
    variant: variant,
    onTap: () => onProductSelected(product),
  );

  @override
  Widget build(BuildContext context) {
    return CatalogRowsSliver(
      itemCount: products.length,
      itemBuilder: (context, index) => _card(products[index]),
      variant: variant,
      availableWidth: availableWidth,
    );
  }
}

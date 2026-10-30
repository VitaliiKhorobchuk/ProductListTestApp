import 'package:flutter/material.dart';

import '../../models/product.dart';

/// Basic sample presentation; the design-system ProductCard comes later.
class SampleProductTile extends StatelessWidget {
  const SampleProductTile({super.key, required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final amount = product.discountedPrice;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CircleAvatar(child: Icon(Icons.shopping_bag_outlined)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${product.brand} · ${product.category.replaceAll('-', ' ')}',
                  ),
                  const SizedBox(height: 8),
                  Text(
                    amount == null
                        ? 'Price unavailable'
                        : '\$${amount.toStringAsFixed(2)} USD',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

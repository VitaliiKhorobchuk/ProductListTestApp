import 'package:flutter/material.dart';

import '../../design_system/components/empty_state.dart';
import '../widgets/catalog_detail_app_bar.dart';

class CatalogSelectionPrompt extends StatelessWidget {
  const CatalogSelectionPrompt({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: const CatalogDetailAppBar(title: 'Product details'),
    body: const EmptyState(
      title: 'Select a product',
      message: 'Choose a product from the catalog to see its details.',
      icon: Icons.touch_app_outlined,
    ),
  );
}

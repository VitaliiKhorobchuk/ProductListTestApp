import 'package:equatable/equatable.dart';

import '../../../../core/catalog_failure.dart';
import '../../models/category.dart';

enum CategoriesStatus { initial, loading, loaded, empty, error }

/// Category metadata has its own lifetime and failure, separate from products.
class CategoriesState extends Equatable {
  CategoriesState({
    this.status = CategoriesStatus.initial,
    List<Category> categories = const [],
    this.failure,
  }) : categories = List.unmodifiable(categories);

  final CategoriesStatus status;
  final List<Category> categories;
  final CatalogFailure? failure;

  @override
  List<Object?> get props => [status, categories, failure];
}

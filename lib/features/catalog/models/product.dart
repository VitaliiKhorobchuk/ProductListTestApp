import 'package:equatable/equatable.dart';

import '../../../core/product_labels.dart';
import '../../../core/product_pricing.dart';

class Product extends Equatable {
  Product({
    required this.id,
    required this.title,
    required this.category,
    this.description = '',
    this.brand = ProductLabels.unknownBrand,
    this.price,
    this.discountPercentage = 0,
    this.rating,
    this.reviewCount,
    this.stock,
    this.thumbnail,
    List<String> images = const [],
  }) : images = List.unmodifiable({
         for (final image in images)
           if (image.trim().isNotEmpty) image.trim(),
       });

  final int id;
  final String title;
  final String category;
  final String description;
  final String brand;
  final double? price;
  final double discountPercentage;
  final double? rating;
  final int? reviewCount;
  final int? stock;
  final String? thumbnail;
  final List<String> images;

  double? get discountedPrice =>
      ProductPricing.discountedPrice(price, discountPercentage);
  @override
  List<Object?> get props => [
    id,
    title,
    category,
    description,
    brand,
    price,
    discountPercentage,
    rating,
    reviewCount,
    stock,
    thumbnail,
    images,
  ];
}

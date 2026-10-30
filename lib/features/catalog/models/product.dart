import 'package:equatable/equatable.dart';

class Product extends Equatable {
  Product({
    required this.id,
    required this.title,
    required this.category,
    this.description = '',
    this.brand = 'Unknown brand',
    this.price,
    this.discountPercentage = 0,
    this.rating,
    this.stock,
    this.thumbnail,
    List<String> images = const [],
  }) : images = List.unmodifiable(images);

  final int id;
  final String title;
  final String category;
  final String description;
  final String brand;
  final double? price;
  final double discountPercentage;
  final double? rating;
  final int? stock;
  final String? thumbnail;
  final List<String> images;

  double? get discountedPrice {
    final original = price;
    if (original == null || !original.isFinite || original < 0) return null;
    final discount =
        discountPercentage.isFinite &&
            discountPercentage >= 0 &&
            discountPercentage <= 100
        ? discountPercentage
        : 0;
    return original * (1 - discount / 100);
  }

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
    stock,
    thumbnail,
    images,
  ];
}

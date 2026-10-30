import 'package:equatable/equatable.dart';

class CatalogQuery extends Equatable {
  CatalogQuery({String text = '', String? categorySlug})
    : text = text.trim(),
      categorySlug = categorySlug == null || categorySlug.trim().isEmpty
          ? null
          : categorySlug.trim();

  final String text;
  final String? categorySlug;

  String get normalizedText => text.toLowerCase();

  @override
  List<Object?> get props => [normalizedText, categorySlug];
}

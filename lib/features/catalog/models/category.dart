import 'package:equatable/equatable.dart';

class Category extends Equatable {
  const Category({required this.slug, required this.name});

  final String slug;
  final String name;

  @override
  List<Object> get props => [slug, name];
}

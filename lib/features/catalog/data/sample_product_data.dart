import '../../../fixtures/sample_product_assets.dart';
import '../models/category.dart';
import '../models/product.dart';

/// Offline fixtures for the architecture example, not fetched API records.
final List<Product> sampleProducts = List.unmodifiable([
  Product(
    id: 1,
    title: 'Red Lipstick',
    reviewCount: 23,
    thumbnail: SampleProductAssets.redLipstick,
    category: 'beauty',
    brand: 'Example Beauty',
    description: 'A classic red lipstick with a smooth finish.',
    price: 12.99,
    discountPercentage: 10,
    rating: 4.4,
    stock: 30,
  ),
  Product(
    id: 2,
    title: 'Red Onions',
    reviewCount: 12,
    thumbnail: SampleProductAssets.redOnions,
    category: 'groceries',
    brand: 'Example Market',
    description: 'A bag of fresh onions for everyday cooking.',
    price: 1.99,
    rating: 4.2,
    stock: 50,
  ),
  Product(
    id: 3,
    title: 'Eggs',
    reviewCount: 8,
    thumbnail: SampleProductAssets.eggs,
    category: 'groceries',
    brand: 'Example Market',
    description: 'A versatile ingredient for breakfast and baking.',
    price: 2.99,
    rating: 2.8,
    stock: 24,
  ),
  Product(
    id: 4,
    title: 'Wireless Headphones',
    reviewCount: 47,
    thumbnail: SampleProductAssets.wirelessHeadphones,
    category: 'mobile-accessories',
    brand: 'Example Audio',
    description: 'Comfortable wireless headphones for daily listening.',
    price: 89.99,
    discountPercentage: 15,
    rating: 4.7,
    stock: 12,
  ),
  Product(
    id: 5,
    title: 'Desk Lamp',
    reviewCount: 6,
    thumbnail: SampleProductAssets.deskLamp,
    category: 'home-decoration',
    brand: 'Example Home',
    description: 'An adjustable lamp for your desk.',
    price: 34.99,
    rating: 3.5,
    stock: 18,
  ),
  Product(
    id: 6,
    title: 'Wooden Side Table',
    reviewCount: 0,
    // Deliberately omit the thumbnail to demonstrate the unavailable state.
    category: 'furniture',
    brand: 'Example Home',
    description: 'A compact table for a comfortable reading corner.',
    price: 49.99,
    // No rating yet: keep unknown distinct from a zero rating.
    stock: 7,
  ),
]);

const sampleCategories = [
  Category(slug: 'beauty', name: 'Beauty'),
  Category(slug: 'groceries', name: 'Groceries'),
  Category(slug: 'mobile-accessories', name: 'Mobile accessories'),
  Category(slug: 'home-decoration', name: 'Home decoration'),
  Category(slug: 'furniture', name: 'Furniture'),
];

class Category {
  final int id;
  final String name;
  final String description;

  Category({
    required this.id,
    required this.name,
    required this.description,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
    );
  }
}

class Product {
  final int id;
  final String name;
  final String image;
  final String description;
  final double price;
  final int categoryId;
  final bool isFeatured;
  final int userId;
  final int stock;
  final String location;
  final Category category;

  Product({
    required this.id,
    required this.name,
    required this.image,
    required this.description,
    required this.price,
    required this.categoryId,
    required this.isFeatured,
    required this.userId,
    required this.stock,
    required this.location,
    required this.category,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      image: json['image'] ?? '',
      description: json['description'] ?? '',
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
      categoryId: json['category_id'] ?? 0,
      isFeatured: json['is_featured'] == 1,
      userId: json['user_id'] ?? 0,
      stock: json['stock'] ?? 0,
      location: json['location'] ?? '',
      category: Category.fromJson(json['category'] ?? {}),
    );
  }
} 
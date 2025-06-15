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

class Seller {
  final int id;
  final String name;
  final String username;
  final String email;
  final String phoneNumber;
  final String location;
  final String imageUrl;
  final String role;

  Seller({
    required this.id,
    required this.name,
    required this.username,
    required this.email,
    required this.phoneNumber,
    required this.location,
    required this.imageUrl,
    required this.role,
  });

  factory Seller.fromJson(Map<String, dynamic> json) {
    return Seller(
      id: json['id'] ?? 0,
      name: json['name'] ?? 'Unknown Seller',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phone_number'] ?? '',
      location: json['location'] ?? 'Location not available',
      imageUrl: json['image_url'] ?? '',
      role: json['role'] ?? 'Seller',
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
  final Seller seller;

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
    required this.seller,
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
      seller: json['user'] != null ? Seller.fromJson(json['user']) : Seller(
        id: 0,
        name: 'Unknown Seller',
        username: '',
        email: '',
        phoneNumber: '',
        location: '',
        imageUrl: '',
        role: '',
      ),
    );
  }
} 
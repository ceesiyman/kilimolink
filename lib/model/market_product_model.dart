class MarketProduct {
  final String name;
  final int pricePerKg;
  final String imageUrl;
  final String category; // Fruits, Vegetables, Grain, Tubers
  final String? description; // Optional for API

  MarketProduct({
    required this.name,
    required this.pricePerKg,
    required this.imageUrl,
    required this.category,
    this.description,
  });

  factory MarketProduct.fromJson(Map<String, dynamic> json) {
    return MarketProduct(
      name: json['name'],
      pricePerKg: json['pricePerKg'],
      imageUrl: json['imageUrl'],
      category: json['category'],
      description: json['description'],
    );
  }
}
class CropPrice {
  final String name;
  final int pricePerKg;
  final String imageUrl;
  final String? description; // Optional fields for API data
  final String? growingSeason;
  final String? soilType;
  final String? waterNeeds;

  CropPrice({
    required this.name,
    required this.pricePerKg,
    required this.imageUrl,
    this.description,
    this.growingSeason,
    this.soilType,
    this.waterNeeds,
  });

  factory CropPrice.fromJson(Map<String, dynamic> json) {
    return CropPrice(
      name: json['name'],
      pricePerKg: json['pricePerKg'],
      imageUrl: json['imageUrl'],
      description: json['description'],
      growingSeason: json['growingSeason'],
      soilType: json['soilType'],
      waterNeeds: json['waterNeeds'],
    );
  }
}
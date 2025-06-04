class Weather {
  final String location;
  final double temperature;
  final String condition;

  Weather({
    required this.location,
    required this.temperature,
    required this.condition,
  });

  factory Weather.fromJson(Map<String, dynamic> json) {
    return Weather(
      location: json['location'],
      temperature: json['temperature'].toDouble(),
      condition: json['condition'],
    );
  }
}
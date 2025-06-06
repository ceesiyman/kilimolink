import 'package:flutter/material.dart';
import '../model/weather_model.dart';
import '../model/product_model.dart';
import '../service/api_service.dart';
import '../screens/market_screen.dart';
import '../screens/expert_screen.dart';
import '../screens/community_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/crop_detail_screen.dart';
import '../widgets/bottom_nav_bar.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService apiService = ApiService();
  late Future<Weather> weatherFuture;
  late Future<List<Product>> featuredProductsFuture;
  final bool useRealApi = true;

  @override
  void initState() {
    super.initState();
    weatherFuture = apiService.fetchRealWeather();
    featuredProductsFuture = apiService.fetchFeaturedProductsFromApi();
  }

  void _onNavTap(int index) {
    if (index == 0) {
      // Already on HomeScreen, no action needed
    } else if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => MarketScreen()),
      );
    } else if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ExpertScreen()),
      );
    } else if (index == 3) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => CommunityScreen()),
      );
    } else if (index == 4) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ProfileScreen()),
      );
    }
  }

  IconData _getWeatherIcon(String condition) {
    switch (condition.toLowerCase()) {
      case 'clear':
        return Icons.wb_sunny;
      case 'clouds':
        return Icons.cloud;
      case 'rain':
        return Icons.beach_access;
      case 'thunderstorm':
        return Icons.bolt;
      case 'snow':
        return Icons.ac_unit;
      default:
        return Icons.wb_sunny;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Weather Section
                FutureBuilder<Weather>(
                  future: weatherFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Column(
                        children: [
                          Text(
                            'Failed to load weather: ${snapshot.error}',
                            style: TextStyle(color: Colors.red),
                          ),
                          SizedBox(height: 10),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                weatherFuture = apiService.fetchRealWeather();
                              });
                            },
                            child: Text('Retry'),
                          ),
                        ],
                      );
                    } else if (snapshot.hasData) {
                      final weather = snapshot.data!;
                      return Container(
                        padding: EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: Colors.green[100],
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  weather.location,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '${weather.temperature}°C',
                                  style: TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                            Icon(
                              _getWeatherIcon(weather.condition),
                              color: Colors.orange,
                              size: 40,
                            ),
                          ],
                        ),
                      );
                    }
                    return SizedBox.shrink();
                  },
                ),
                SizedBox(height: 20),

                // Featured Products Section
                Text(
                  'Featured Products',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                FutureBuilder<List<Product>>(
                  future: featuredProductsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}');
                    } else if (snapshot.hasData) {
                      final products = snapshot.data!;
                      return Column(
                        children: [
                          // Product Grid
                          Wrap(
                            spacing: 20,
                            runSpacing: 10,
                            children: products.map((product) {
                              return GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => CropDetailScreen(product: product),
                                    ),
                                  );
                                },
                                child: Column(
                                  children: [
                                    Container(
                                      width: 60,
                                      height: 60,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        image: DecorationImage(
                                          image: NetworkImage(product.image),
                                          fit: BoxFit.cover,
                                          onError: (exception, stackTrace) {
                                            print('Error loading image: $exception');
                                          },
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: 5),
                                    Text(
                                      product.name,
                                      style: TextStyle(fontSize: 12),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                          SizedBox(height: 20),
                          
                          // Product List
                          ...products.map((product) {
                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CropDetailScreen(product: product),
                                  ),
                                );
                              },
                              child: Card(
                                elevation: 2,
                                margin: EdgeInsets.symmetric(vertical: 8.0),
                                child: ListTile(
                                  leading: Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8.0),
                                      image: DecorationImage(
                                        image: NetworkImage(product.image),
                                        fit: BoxFit.cover,
                                        onError: (exception, stackTrace) {
                                          print('Error loading image: $exception');
                                        },
                                      ),
                                    ),
                                  ),
                                  title: Text(product.name),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(product.category.name),
                                      Text('Stock: ${product.stock}'),
                                    ],
                                  ),
                                  trailing: Text(
                                    '${product.price.toStringAsFixed(2)} Tsh',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ],
                      );
                    }
                    return SizedBox.shrink();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 0,
        onTap: _onNavTap,
      ),
    );
  }
}
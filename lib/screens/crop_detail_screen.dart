import 'package:flutter/material.dart';
import '../model/crop_price_model.dart';
import '../screens/home_screen.dart';
import '../screens/market_screen.dart';
import '../screens/expert_screen.dart';
import '../screens/community_screen.dart'; // Import the CommunityScreen
import '../widgets/bottom_nav_bar.dart';

class CropDetailScreen extends StatelessWidget {
  final CropPrice crop;

  const CropDetailScreen({required this.crop});

  void _onNavTap(int index, BuildContext context) {
    if (index == 0) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen()),
        (route) => false,
      );
    } else if (index == 1) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => MarketScreen()),
        (route) => false,
      );
    } else if (index == 2) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => ExpertScreen()),
        (route) => false,
      );
    } else if (index == 3) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => CommunityScreen()), // Navigate to CommunityScreen
        (route) => false,
      );
    }
    // Add navigation for Profile tab (index 4) as needed
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(crop.name),
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Crop Image
              Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12.0),
                  image: DecorationImage(
                    image: NetworkImage(crop.imageUrl),
                    fit: BoxFit.cover,
                    onError: (exception, stackTrace) {
                      print('Error loading image: $exception');
                    },
                  ),
                ),
              ),
              SizedBox(height: 20),

              // Crop Name
              Text(
                crop.name,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),

              // Crop Price
              Text(
                '${crop.pricePerKg} Tsh per Kg',
                style: TextStyle(fontSize: 18, color: Colors.green),
              ),
              SizedBox(height: 20),

              // Description Section
              Text(
                'Description',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Card(
                elevation: 2,
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    crop.description ?? 'This is a placeholder description for ${crop.name}. '
                        'It can include details like growing conditions, harvest time, and market demand. '
                        'Replace this with real data from the API when available.',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
              SizedBox(height: 20),

              // Additional Details
              Text(
                'Additional Details',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Card(
                elevation: 2,
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Growing Season: ${crop.growingSeason ?? "To be fetched from API"}',
                        style: TextStyle(fontSize: 16),
                      ),
                      SizedBox(height: 5),
                      Text(
                        'Soil Type: ${crop.soilType ?? "To be fetched from API"}',
                        style: TextStyle(fontSize: 16),
                      ),
                      SizedBox(height: 5),
                      Text(
                        'Water Needs: ${crop.waterNeeds ?? "To be fetched from API"}',
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 0, // Highlight "Home" tab (can be adjusted based on app state)
        onTap: (index) => _onNavTap(index, context),
      ),
    );
  }
}
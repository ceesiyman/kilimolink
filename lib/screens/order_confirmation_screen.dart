import 'package:flutter/material.dart';
import '../model/market_product_model.dart';
import '../widgets/bottom_nav_bar.dart';
import 'home_screen.dart';
import 'market_screen.dart';
import 'expert_screen.dart';
import 'community_screen.dart';
import 'profile_screen.dart';

class OrderConfirmationScreen extends StatelessWidget {
  final List<MarketProduct> cartItems;

  const OrderConfirmationScreen({required this.cartItems});

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
        MaterialPageRoute(builder: (context) => CommunityScreen()),
        (route) => false,
      );
    } else if (index == 4) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => ProfileScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalPrice = cartItems.fold<int>(
      0,
      (sum, item) => sum + item.pricePerKg,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('Order Confirmation'),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order Summary',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: cartItems.length,
                itemBuilder: (context, index) {
                  final product = cartItems[index];
                  return Card(
                    elevation: 2,
                    margin: EdgeInsets.symmetric(vertical: 8.0),
                    child: ListTile(
                      leading: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8.0),
                          image: DecorationImage(
                            image: NetworkImage(product.imageUrl),
                            fit: BoxFit.cover,
                            onError: (exception, stackTrace) {
                              print('Error loading image: $exception');
                            },
                          ),
                        ),
                      ),
                      title: Text(product.name),
                      subtitle: Text('${product.pricePerKg} Tsh per Kg'),
                    ),
                  );
                },
              ),
            ),
            Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  '$totalPrice Tsh',
                  style: TextStyle(fontSize: 18, color: Colors.green),
                ),
              ],
            ),
            SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: EdgeInsets.symmetric(vertical: 16.0),
                minimumSize: Size(double.infinity, 50),
              ),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Order placed successfully!')),
                );
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => HomeScreen()),
                  (route) => false,
                );
              },
              child: Text(
                'Confirm Order',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 1, // Market tab (consider changing if not intended)
        onTap: (index) => _onNavTap(index, context),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import '../model/market_product_model.dart';
import '../widgets/bottom_nav_bar.dart';
import 'order_confirmation_screen.dart';
import 'home_screen.dart';
import 'market_screen.dart';
import 'expert_screen.dart';
import 'community_screen.dart';
import 'profile_screen.dart';

class CartScreen extends StatefulWidget {
  final List<MarketProduct> cartItems;

  const CartScreen({required this.cartItems});

  @override
  _CartScreenState createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  void _onNavTap(int index) {
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
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ExpertScreen()),
      );
    }else if (index == 3) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => CommunityScreen()),
      );
    }else if (index == 4) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ProfileScreen()),
      );
    }
  }

  void _removeFromCart(int index) {
    setState(() {
      widget.cartItems.removeAt(index);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Item removed from cart')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Cart'),
        backgroundColor: Colors.green,
      ),
      body: widget.cartItems.isEmpty
          ? Center(child: Text('Your cart is empty'))
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: EdgeInsets.all(16.0),
                    itemCount: widget.cartItems.length,
                    itemBuilder: (context, index) {
                      final product = widget.cartItems[index];
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
                          trailing: IconButton(
                            icon: Icon(Icons.remove_circle, color: Colors.red),
                            onPressed: () => _removeFromCart(index),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(16.0),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      minimumSize: Size(double.infinity, 50),
                    ),
                    onPressed: widget.cartItems.isEmpty
                        ? null
                        : () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => OrderConfirmationScreen(cartItems: widget.cartItems),
                              ),
                            );
                          },
                    child: Text(
                      'Proceed to Checkout',
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 1, // Market tab
        onTap: _onNavTap,
      ),
    );
  }
}
import 'package:flutter/material.dart';
import '../model/market_product_model.dart';
import '../service/api_service.dart';
import '../widgets/bottom_nav_bar.dart';
import 'cart_screen.dart';
import 'home_screen.dart';
import 'expert_screen.dart';
import 'community_screen.dart';
import 'profile_screen.dart';

class MarketScreen extends StatefulWidget {
  @override
  _MarketScreenState createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen> {
  final ApiService apiService = ApiService();
  late Future<List<MarketProduct>> marketProductsFuture;
  final bool useRealApi = false;
  String selectedCategory = 'Fruits'; // Default category
  List<MarketProduct> cartItems = []; // Store cart items
  String searchQuery = ''; // Store search query
  List<MarketProduct> allProducts = []; // Store all products for filtering

  @override
  void initState() {
    super.initState();
    marketProductsFuture = useRealApi ? apiService.fetchMarketProductsFromApi() : apiService.fetchMarketProducts();
    // Fetch all products initially to enable local filtering
    marketProductsFuture.then((products) {
      setState(() {
        allProducts = products;
      });
    });
  }

  void _onNavTap(int index) {
    if (index == 0) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen()),
        (route) => false,
      );
    } else if (index == 1) {
      // Already on MarketScreen, no action needed
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
    }else if (index == 4) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => ProfileScreen()),
        (route) => false,
      );
    }
  }

  void _addToCart(MarketProduct product) {
    setState(() {
      cartItems.add(product);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${product.name} added to cart')),
    );
  }

  void _updateSearchQuery(String query) async {
    setState(() {
      searchQuery = query;
    });
    // Fetch filtered products based on search query
    final filteredProducts = useRealApi
        ? await apiService.searchMarketProductsFromApi(query)
        : await apiService.searchMarketProducts(query);
    setState(() {
      allProducts = filteredProducts;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Agri Market'),
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            icon: Icon(Icons.shopping_cart),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CartScreen(cartItems: cartItems),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'search products...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              onChanged: _updateSearchQuery,
            ),
          ),

          // Category Tabs
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildCategoryTab('Fruits'),
                _buildCategoryTab('Vegetables'),
                _buildCategoryTab('Grain'),
                _buildCategoryTab('Tubers'),
              ],
            ),
          ),
          SizedBox(height: 10),

          // Products Grid
          Expanded(
            child: FutureBuilder<List<MarketProduct>>(
              future: marketProductsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else {
                  // Filter products by category
                  final products = allProducts
                      .where((product) => product.category == selectedCategory)
                      .toList();
                  if (products.isEmpty) {
                    return Center(child: Text('No products found'));
                  }
                  return GridView.builder(
                    padding: EdgeInsets.all(16.0),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 0.75,
                    ),
                      itemCount: products.length,
                    itemBuilder: (context, index) {
                      final product = products[index];
                      return Card(
                        elevation: 2,
                        child: Column(
                          children: [
                            Expanded(
                              child: Container(
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
                            ),
                            Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Column(
                                children: [
                                  Text(
                                    product.name,
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                  SizedBox(height: 5),
                                  Text(
                                    '${product.pricePerKg} Tsh',
                                    style: TextStyle(fontSize: 14, color: Colors.green),
                                  ),
                                  SizedBox(height: 5),
                                  IconButton(
                                    icon: Icon(Icons.add_shopping_cart, color: Colors.green),
                                    onPressed: () => _addToCart(product),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                }
              },
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

  Widget _buildCategoryTab(String category) {
    bool isSelected = selectedCategory == category;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedCategory = category;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green : Colors.grey[200],
          borderRadius: BorderRadius.circular(20.0),
        ),
        child: Text(
          category,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import '../model/product_model.dart';
import '../service/api_service.dart';
import '../widgets/bottom_nav_bar.dart';
import 'cart_screen.dart';
import 'home_screen.dart';
import 'expert_screen.dart';
import 'community_screen.dart';
import 'profile_screen.dart';
import 'crop_detail_screen.dart';

class MarketScreen extends StatefulWidget {
  @override
  _MarketScreenState createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen> {
  final ApiService apiService = ApiService();
  late Future<List<Category>> categoriesFuture;
  late Future<List<Product>> productsFuture;
  List<Map<String, dynamic>> cartItems = [];
  String searchQuery = '';
  Category? selectedCategory;
  final TextEditingController minPriceController = TextEditingController();
  final TextEditingController maxPriceController = TextEditingController();
  Map<int, int> productQuantities = {};

  @override
  void initState() {
    super.initState();
    categoriesFuture = apiService.fetchCategoriesFromApi();
    productsFuture = apiService.fetchProductsFromApi();
    cartItems = [];
  }

  @override
  void dispose() {
    minPriceController.dispose();
    maxPriceController.dispose();
    super.dispose();
  }

  void _fetchProducts() {
    setState(() {
      double? minPrice = minPriceController.text.isNotEmpty 
          ? double.tryParse(minPriceController.text) 
          : null;
      double? maxPrice = maxPriceController.text.isNotEmpty 
          ? double.tryParse(maxPriceController.text) 
          : null;

      productsFuture = apiService.fetchProductsFromApi(
        categoryId: selectedCategory?.id,
        minPrice: minPrice,
        maxPrice: maxPrice,
      );
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
    } else if (index == 4) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => ProfileScreen()),
        (route) => false,
      );
    }
  }

  void _navigateToCart() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CartScreen(cartItems: cartItems),
      ),
    );
  }

  void _addToCart(Product product) {
    setState(() {
      int existingIndex = cartItems.indexWhere((item) => (item['product'] as Product).id == product.id);
      
      if (existingIndex != -1) {
        cartItems[existingIndex]['quantity'] = (cartItems[existingIndex]['quantity'] as int) + 1;
      } else {
        cartItems.add({
          'product': product,
          'quantity': 1,
        });
      }
      
      productQuantities[product.id] = (productQuantities[product.id] ?? 0) + 1;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${product.name} added to cart')),
    );
  }

  void _updateQuantity(Product product, int newQuantity) {
    if (newQuantity < 0) return;
    
    setState(() {
      productQuantities[product.id] = newQuantity;
      
      int existingIndex = cartItems.indexWhere((item) => (item['product'] as Product).id == product.id);
      if (existingIndex != -1) {
        if (newQuantity == 0) {
          cartItems.removeAt(existingIndex);
        } else {
          cartItems[existingIndex]['quantity'] = newQuantity;
        }
      } else if (newQuantity > 0) {
        cartItems.add({
          'product': product,
          'quantity': newQuantity,
        });
      }
    });
  }

  void _updateSearchQuery(String query) {
    setState(() {
      searchQuery = query;
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
            onPressed: _navigateToCart,
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
                hintText: 'Search products...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              onChanged: _updateSearchQuery,
            ),
          ),

          // Price Filter
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: minPriceController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Min Price',
                      suffixText: 'Tsh',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    onChanged: (value) => _fetchProducts(),
                  ),
                ),
                SizedBox(width: 16.0),
                Expanded(
                  child: TextField(
                    controller: maxPriceController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Max Price',
                      suffixText: 'Tsh',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    onChanged: (value) => _fetchProducts(),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16.0),

          // Category Tabs
          FutureBuilder<List<Category>>(
            future: categoriesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              } else if (snapshot.hasData) {
                final categories = snapshot.data!;
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      _buildCategoryTab(null, 'All'),
                      ...categories.map((category) => _buildCategoryTab(category, category.name)),
                    ],
                  ),
                );
              }
              return SizedBox.shrink();
            },
          ),
          SizedBox(height: 10),

          // Products Grid
          Expanded(
            child: FutureBuilder<List<Product>>(
              future: productsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (snapshot.hasData) {
                  final products = snapshot.data!;
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
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CropDetailScreen(product: product),
                            ),
                          );
                        },
                        child: _buildProductCard(product),
                      );
                    },
                  );
                }
                return SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 1,
        onTap: _onNavTap,
      ),
    );
  }

  Widget _buildCategoryTab(Category? category, String name) {
    bool isSelected = selectedCategory?.id == category?.id;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedCategory = category;
          _fetchProducts();
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        margin: EdgeInsets.only(right: 8.0),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green : Colors.grey[200],
          borderRadius: BorderRadius.circular(20.0),
        ),
        child: Text(
          name,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildProductCard(Product product) {
    int quantity = productQuantities[product.id] ?? 0;
    
    return Card(
      elevation: 2,
      child: Column(
        children: [
          Expanded(
            child: Container(
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
                  '${product.price.toStringAsFixed(2)} Tsh',
                  style: TextStyle(fontSize: 14, color: Colors.green),
                ),
                SizedBox(height: 5),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: Icon(Icons.remove_circle_outline, color: Colors.green),
                      onPressed: quantity > 0 
                          ? () => _updateQuantity(product, quantity - 1)
                          : null,
                    ),
                    Text(
                      quantity.toString(),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.add_circle_outline, color: Colors.green),
                      onPressed: () => _updateQuantity(product, quantity + 1),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
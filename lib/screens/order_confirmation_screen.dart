import 'package:flutter/material.dart';
import '../model/product_model.dart';
import '../service/api_service.dart';
import 'orders_screen.dart';

class OrderConfirmationScreen extends StatefulWidget {
  final List<Map<String, dynamic>> cartItems;

  OrderConfirmationScreen({required this.cartItems});

  @override
  _OrderConfirmationScreenState createState() => _OrderConfirmationScreenState();
}

class _OrderConfirmationScreenState extends State<OrderConfirmationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _shippingAddressController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _notesController = TextEditingController();
  final ApiService _apiService = ApiService();
  bool _isLoading = false;

  @override
  void dispose() {
    _shippingAddressController.dispose();
    _phoneNumberController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submitOrder() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final order = await _apiService.createOrderFromApi(
        items: widget.cartItems,
        shippingAddress: _shippingAddressController.text,
        phoneNumber: _phoneNumberController.text,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
      );

      if (!mounted) return;

      // Show success message and navigate to orders screen
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Order placed successfully!')),
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => OrdersScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  double _calculateTotal() {
    return widget.cartItems.fold(0.0, (total, item) {
      final product = item['product'] as Product;
      final quantity = item['quantity'] as int;
      return total + (product.price * quantity);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Confirm Order'),
        backgroundColor: Colors.green,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Order Summary
                    Card(
                      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order Summary',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
            ),
                            SizedBox(height: 8),
                            ...widget.cartItems.map((item) {
                              final product = item['product'] as Product;
                              final quantity = item['quantity'] as int;
                              return Padding(
                                padding: EdgeInsets.symmetric(vertical: 4.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
            Expanded(
                                      child: Text(
                                        '${product.name} x$quantity',
                                        style: TextStyle(fontSize: 16),
                                      ),
                                    ),
                                    Text(
                                      '${(product.price * quantity).toStringAsFixed(2)} Tsh',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                    ),
                                    ),
                                  ],
              ),
                              );
                            }).toList(),
            Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total:',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                ),
                Text(
                                  '${_calculateTotal().toStringAsFixed(2)} Tsh',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                ),
              ],
            ),
                      ),
                    ),
                    SizedBox(height: 16),

                    // Shipping Information
                    Text(
                      'Shipping Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    TextFormField(
                      controller: _shippingAddressController,
                      decoration: InputDecoration(
                        labelText: 'Shipping Address',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your shipping address';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneNumberController,
                      decoration: InputDecoration(
                        labelText: 'Phone Number',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your phone number';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _notesController,
                      decoration: InputDecoration(
                        labelText: 'Order Notes (Optional)',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    SizedBox(height: 24),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submitOrder,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                          padding: EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                          'Place Order',
                          style: TextStyle(fontSize: 16),
                        ),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}
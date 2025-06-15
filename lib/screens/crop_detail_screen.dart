import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../model/product_model.dart';
import '../screens/home_screen.dart';
import '../screens/market_screen.dart';
import '../screens/expert_screen.dart';
import '../screens/community_screen.dart';
import '../widgets/bottom_nav_bar.dart';

class CropDetailScreen extends StatefulWidget {
  final Product product;

  const CropDetailScreen({required this.product});

  @override
  _CropDetailScreenState createState() => _CropDetailScreenState();
}

class _CropDetailScreenState extends State<CropDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  String _selectedMessage = '';
  late List<String> _predefinedMessages;

  @override
  void initState() {
    super.initState();
    _predefinedMessages = [
      'Hi, I\'m interested in your ${widget.product.name}. Is it still available?',
      'Hello! I\'d like to know more about your ${widget.product.name}. What\'s the best price?',
      'Hi there! I\'m looking to buy ${widget.product.name}. Can we discuss delivery options?',
      'Hello! I\'m interested in bulk purchase of ${widget.product.name}. Do you offer discounts?',
      'Hi! I\'d like to place an order for ${widget.product.name}. What\'s your payment method?',
    ];
    _selectedMessage = _predefinedMessages[0];
    _messageController.text = _selectedMessage;
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

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
    }
  }

  Future<void> _sendSMS() async {
    final phoneNumber = widget.product.seller.phoneNumber;
    final message = _messageController.text.trim();
    
    if (phoneNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Seller phone number not available')),
      );
      return;
    }

    if (message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a message')),
      );
      return;
    }

    // Try multiple SMS URL formats for better compatibility
    final smsUrls = [
      'sms:$phoneNumber?body=${Uri.encodeComponent(message)}',
      'sms:$phoneNumber&body=${Uri.encodeComponent(message)}',
      'sms:$phoneNumber',
    ];
    
    bool smsSent = false;
    
    for (String smsUrl in smsUrls) {
      try {
        final uri = Uri.parse(smsUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          smsSent = true;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Opening SMS app...'),
              backgroundColor: Colors.green,
            ),
          );
          break;
        }
      } catch (e) {
        print('Failed to launch SMS URL: $smsUrl - $e');
        continue;
      }
    }
    
    if (!smsSent) {
      // Fallback: Show dialog with phone number and message for manual copying
      _showManualSMSSDialog(phoneNumber, message);
    }
  }

  void _showManualSMSSDialog(String phoneNumber, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('SMS Not Available'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Unable to open SMS app automatically.'),
              SizedBox(height: 16),
              Text('Phone Number:', style: TextStyle(fontWeight: FontWeight.bold)),
              SelectableText(phoneNumber),
              SizedBox(height: 8),
              Text('Message:', style: TextStyle(fontWeight: FontWeight.bold)),
              SelectableText(message),
              SizedBox(height: 16),
              Text('Please copy the details above and send SMS manually.'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product.name),
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image
              Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12.0),
                  image: DecorationImage(
                    image: NetworkImage(widget.product.image),
                    fit: BoxFit.cover,
                    onError: (exception, stackTrace) {
                      print('Error loading image: $exception');
                    },
                  ),
                ),
              ),
              SizedBox(height: 20),

              // Product Name
              Text(
                widget.product.name,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),

              // Product Price
              Text(
                '${widget.product.price.toStringAsFixed(2)} Tsh',
                style: TextStyle(fontSize: 18, color: Colors.green, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),

              // Seller Information
              Text(
                'Seller Information',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Card(
                elevation: 2,
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 25,
                        backgroundImage: NetworkImage(widget.product.seller.imageUrl),
                        onBackgroundImageError: (_, __) {},
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.product.seller.name,
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 4),
                            Text(
                              widget.product.seller.role,
                              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                            ),
                            SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                                SizedBox(width: 4),
                                Text(
                                  widget.product.seller.location,
                                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
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
                    widget.product.description,
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
                        'Category: ${widget.product.category.name}',
                        style: TextStyle(fontSize: 16),
                      ),
                      SizedBox(height: 5),
                      Text(
                        'Stock Available: ${widget.product.stock}',
                        style: TextStyle(fontSize: 16),
                      ),
                      SizedBox(height: 5),
                      Text(
                        'Location: ${widget.product.location}',
                        style: TextStyle(fontSize: 16),
                      ),
                      SizedBox(height: 5),
                      Text(
                        'Category Description: ${widget.product.category.description}',
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),

              // Contact Seller Section
              Text(
                'Contact Seller',
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
                        'Quick Messages',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 10),
                      Container(
                        height: 120,
                        child: ListView.builder(
                          itemCount: _predefinedMessages.length,
                          itemBuilder: (context, index) {
                            return RadioListTile<String>(
                              title: Text(
                                _predefinedMessages[index],
                                style: TextStyle(fontSize: 14),
                              ),
                              value: _predefinedMessages[index],
                              groupValue: _selectedMessage,
                              onChanged: (value) {
                                setState(() {
                                  _selectedMessage = value!;
                                  _messageController.text = value;
                                });
                              },
                            );
                          },
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Custom Message',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 10),
                      TextField(
                        controller: _messageController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: 'Type your custom message...',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _selectedMessage = value;
                          });
                        },
                      ),
                      SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _sendSMS,
                          icon: Icon(Icons.message),
                          label: Text('Send SMS to Seller'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
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
        currentIndex: 0,
        onTap: (index) => _onNavTap(index, context),
      ),
    );
  }
}
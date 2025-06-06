import 'package:flutter/material.dart';
import '../service/api_service.dart';
import '../model/user_model.dart';
import '../widgets/bottom_nav_bar.dart';
import 'home_screen.dart';
import 'market_screen.dart';
import 'expert_screen.dart';
import 'community_screen.dart';
import 'edit_profile_screen.dart';
import 'my_favorites_screen.dart';
import 'location_screen.dart';
import 'saved_tips_screen.dart';
import 'my_role_screen.dart';
import 'login_screen.dart'; // Import LoginScreen
import 'orders_screen.dart'; // Add import for OrdersScreen
import 'my_consultations_screen.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ApiService apiService = ApiService();
  late Future<User> userFuture;
  final bool useRealApi = true;

  @override
  void initState() {
    super.initState();
    userFuture = useRealApi ? apiService.fetchUserFromApi() : apiService.fetchUser();
  }

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
      // Already on ProfileScreen, no action needed
    }
  }

  void _logout() async {
    final success = useRealApi ? await apiService.logoutFromApi() : await apiService.logout();
    if (success) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
        (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to logout')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Profile'),
        backgroundColor: Colors.green,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => HomeScreen()),
              (route) => false,
            );
          },
        ),
      ),
      body: FutureBuilder<User>(
        future: userFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.hasData) {
            final user = snapshot.data!;
            return Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.grey[300],
                          image: DecorationImage(
                            image: NetworkImage(user.imageUrl),
                            fit: BoxFit.cover,
                            onError: (exception, stackTrace) {
                              print('Error loading user image: $exception');
                            },
                          ),
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.name,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 5),
                            Text(
                              user.username,
                              style: TextStyle(fontSize: 16, color: Colors.grey),
                            ),
                            SizedBox(height: 5),
                            Text(
                              user.email,
                              style: TextStyle(fontSize: 16, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditProfileScreen(user: user),
                            ),
                          ).then((_) {
                            setState(() {
                              userFuture = useRealApi ? apiService.fetchUserFromApi() : apiService.fetchUser();
                            });
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                        ),
                        child: Text(
                          'Edit Profile',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  _buildProfileOption(
                    icon: Icons.favorite_border,
                    label: 'My Favourites',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MyFavoritesScreen(favorites: user.favorites),
                        ),
                      );
                    },
                  ),
                  _buildProfileOption(
                    icon: Icons.location_on,
                    label: 'Location',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => LocationScreen(location: user.location),
                        ),
                      );
                    },
                  ),
                  _buildProfileOption(
                    icon: Icons.bookmark_border,
                    label: 'Saved Tips',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SavedTipsScreen(savedTips: user.savedTips),
                        ),
                      );
                    },
                  ),
                  _buildProfileOption(
                    icon: Icons.person,
                    label: 'My Role',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MyRoleScreen(role: user.role),
                        ),
                      );
                    },
                  ),
                  _buildProfileOption(
                    icon: Icons.shopping_bag_outlined,
                    label: 'My Orders',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => OrdersScreen(),
                        ),
                      );
                    },
                  ),
                  _buildProfileOption(
                    icon: Icons.event_note,
                    label: 'My Consultations',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MyConsultationsScreen(),
                        ),
                      );
                    },
                  ),
                  _buildProfileOption(
                    icon: Icons.logout,
                    label: 'Log Out',
                    onTap: _logout,
                  ),
                ],
              ),
            );
          }
          return SizedBox.shrink();
        },
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 4,
        onTap: _onNavTap,
      ),
    );
  }

  Widget _buildProfileOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.black),
      title: Text(label),
      trailing: Icon(Icons.arrow_forward_ios),
      onTap: onTap,
    );
  }
}
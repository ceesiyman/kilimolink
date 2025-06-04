import 'package:flutter/material.dart';
import '../model/expert_model.dart';
import '../service/api_service.dart';
import '../widgets/bottom_nav_bar.dart';
import 'home_screen.dart';
import 'market_screen.dart';
import 'ask_question_screen.dart';
import 'book_consultation_screen.dart';
import 'view_tips_screen.dart';
import 'chat_screen.dart';
import 'community_screen.dart';
import 'profile_screen.dart';

class ExpertScreen extends StatefulWidget {
  @override
  _ExpertScreenState createState() => _ExpertScreenState();
}

class _ExpertScreenState extends State<ExpertScreen> {
  final ApiService apiService = ApiService();
  late Future<List<Expert>> expertsFuture;
  final bool useRealApi = false;

  @override
  void initState() {
    super.initState();
    expertsFuture = useRealApi ? apiService.fetchExpertsFromApi() : apiService.fetchExperts();
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
      // Already on ExpertScreen, no action needed
    } else if (index == 3) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => CommunityScreen()),
        (route) => false,
      );
    }
    else if (index == 4) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => ProfileScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Expert Service'),
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Action Buttons
              _buildActionButton(
                icon: Icons.question_answer,
                label: 'Ask a Question',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AskQuestionScreen()),
                  );
                },
              ),
              SizedBox(height: 10),
              _buildActionButton(
                icon: Icons.calendar_today,
                label: 'Book a Consultation',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => BookConsultationScreen()),
                  );
                },
              ),
              SizedBox(height: 10),
              _buildActionButton(
                icon: Icons.lightbulb_outline,
                label: 'View Tips & Advice',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ViewTipsScreen()),
                  );
                },
              ),
              SizedBox(height: 20),

              // Experts List
              FutureBuilder<List<Expert>>(
                future: expertsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else if (snapshot.hasData) {
                    final experts = snapshot.data!;
                    return Column(
                      children: experts.map((expert) {
                        return Card(
                          elevation: 2,
                          margin: EdgeInsets.symmetric(vertical: 8.0),
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    image: DecorationImage(
                                      image: NetworkImage(expert.imageUrl),
                                      fit: BoxFit.cover,
                                      onError: (exception, stackTrace) {
                                        print('Error loading image: $exception');
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
                                        expert.name,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(height: 5),
                                      Text(
                                        expert.specialty,
                                        style: TextStyle(fontSize: 14),
                                      ),
                                    ],
                                  ),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ChatScreen(expert: expert),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                  ),
                                  child: Text(
                                    'Chat now',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  }
                  return SizedBox.shrink();
                },
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 2, // Expert tab
        onTap: _onNavTap,
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.green),
            SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
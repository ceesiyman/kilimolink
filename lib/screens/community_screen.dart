import 'package:flutter/material.dart';
import '../model/success_story_model.dart';
import '../model/discussion_message_model.dart';
import '../model/tip_model.dart';
import '../service/api_service.dart';
import '../widgets/bottom_nav_bar.dart';
import 'home_screen.dart';
import 'market_screen.dart';
import 'expert_screen.dart';
import 'community_screen.dart';
import 'profile_screen.dart';

class CommunityScreen extends StatefulWidget {
  @override
  _CommunityScreenState createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> with SingleTickerProviderStateMixin {
  final ApiService apiService = ApiService();
  late TabController _tabController;
  late Future<List<SuccessStory>> successStoriesFuture;
  late Future<List<DiscussionMessage>> discussionMessagesFuture;
  late Future<List<Tip>> tipsFuture;
  final bool useRealApi = false;
  final TextEditingController _messageController = TextEditingController();
  List<DiscussionMessage> _discussionMessages = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    successStoriesFuture = useRealApi ? apiService.fetchSuccessStoriesFromApi() : apiService.fetchSuccessStories();
    discussionMessagesFuture = useRealApi ? apiService.fetchDiscussionMessagesFromApi() : apiService.fetchDiscussionMessages();
    tipsFuture = useRealApi ? apiService.fetchTipsFromApi() : apiService.fetchTips();
    discussionMessagesFuture.then((messages) {
      setState(() {
        _discussionMessages = messages;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _messageController.dispose();
    super.dispose();
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
      // Already on CommunityScreen, no action needed
    }
   else if (index == 4) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ProfileScreen()),
      );
    }
    // Add navigation for Profile tab as needed
  }

  void _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    final newMessage = DiscussionMessage(
      userName: 'Current User', // Replace with actual user name from auth
      content: message,
    );

    try {
      final success = useRealApi
          ? await apiService.sendDiscussionMessageFromApi(newMessage.userName, newMessage.content, false)
          : await apiService.sendDiscussionMessage(newMessage.userName, newMessage.content, false);
      if (success) {
        setState(() {
          _discussionMessages.add(newMessage);
        });
        _messageController.clear();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending message: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Community'),
        backgroundColor: Colors.green,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: [
            Tab(text: 'Success Stories'),
            Tab(text: 'Discussion'),
            Tab(text: 'Tips & Ideas'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Success Stories Tab
          FutureBuilder<List<SuccessStory>>(
            future: successStoriesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              } else if (snapshot.hasData) {
                final stories = snapshot.data!;
                return ListView.builder(
                  padding: EdgeInsets.all(16.0),
                  itemCount: stories.length,
                  itemBuilder: (context, index) {
                    final story = stories[index];
                    return Card(
                      elevation: 2,
                      margin: EdgeInsets.symmetric(vertical: 8.0),
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '"${story.content}"',
                              style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
                            ),
                            SizedBox(height: 5),
                            Text(
                              story.userName,
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 10),
                            SizedBox(
                              height: 150,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: story.imageUrls.length,
                                itemBuilder: (context, imgIndex) {
                                  return Padding(
                                    padding: EdgeInsets.only(right: 8.0),
                                    child: Container(
                                      width: 150,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8.0),
                                        image: DecorationImage(
                                          image: NetworkImage(story.imageUrls[imgIndex]),
                                          fit: BoxFit.cover,
                                          onError: (exception, stackTrace) {
                                            print('Error loading image: $exception');
                                          },
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              }
              return SizedBox.shrink();
            },
          ),

          // Discussion Tab
          Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.all(16.0),
                  itemCount: _discussionMessages.length,
                  itemBuilder: (context, index) {
                    final message = _discussionMessages[index];
                    final isCurrentUser = message.userName == 'Current User';
                    return Align(
                      alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: EdgeInsets.symmetric(vertical: 5.0),
                        padding: EdgeInsets.all(10.0),
                        decoration: BoxDecoration(
                          color: isCurrentUser ? Colors.green[100] : Colors.grey[200],
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: message.isVoiceMessage
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.play_arrow, color: Colors.green),
                                  SizedBox(width: 5),
                                  Container(
                                    width: 100,
                                    height: 5,
                                    color: Colors.green[300],
                                  ),
                                ],
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    message.userName,
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                  SizedBox(height: 5),
                                  Text(message.content),
                                ],
                              ),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: 'Type a message...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 10),
                    IconButton(
                      icon: Icon(Icons.send, color: Colors.green),
                      onPressed: _sendMessage,
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Tips & Ideas Tab
          FutureBuilder<List<Tip>>(
            future: tipsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              } else if (snapshot.hasData) {
                final tips = snapshot.data!;
                return ListView.builder(
                  padding: EdgeInsets.all(16.0),
                  itemCount: tips.length,
                  itemBuilder: (context, index) {
                    final tip = tips[index];
                    return Card(
                      elevation: 2,
                      margin: EdgeInsets.symmetric(vertical: 8.0),
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tip.content,
                              style: TextStyle(fontSize: 16),
                            ),
                            SizedBox(height: 5),
                            Text(
                              tip.userName,
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              }
              return SizedBox.shrink();
            },
          ),
        ],
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 3, // Community tab
        onTap: _onNavTap,
      ),
    );
  }
}
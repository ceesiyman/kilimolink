import 'package:flutter/material.dart';
import '../model/success_story_model.dart';
import '../model/discussion_message_model.dart';
import '../model/tip_model.dart';
import '../model/tip_category_model.dart';
import '../service/api_service.dart';
import '../service/auth_storage_service.dart';
import '../widgets/bottom_nav_bar.dart';
import 'home_screen.dart';
import 'market_screen.dart';
import 'expert_screen.dart';
import 'community_screen.dart';
import 'profile_screen.dart';
import 'create_success_story_screen.dart';
import 'success_story_detail_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class CommunityScreen extends StatefulWidget {
  @override
  _CommunityScreenState createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> with SingleTickerProviderStateMixin {
  final ApiService apiService = ApiService();
  final AuthStorageService authStorage = AuthStorageService();
  late TabController _tabController;
  late Future<Map<String, dynamic>> successStoriesFuture;
  late Future<List<DiscussionMessage>> discussionMessagesFuture;
  late Future<Map<String, dynamic>> categoriesFuture;
  late Future<Map<String, dynamic>> tipsFuture;
  final bool useRealApi = true;
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _storySearchController = TextEditingController();
  List<DiscussionMessage> _discussionMessages = [];
  TipCategory? selectedCategory;
  String? searchQuery;
  String? storySearchQuery;
  String sortBy = 'latest';
  String storySortBy = 'latest';
  bool showFeatured = false;
  bool showFeaturedStories = false;
  String? selectedCropType;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      // Force rebuild when tab changes to update floating action button
      setState(() {});
    });
    _loadSuccessStories();
    discussionMessagesFuture = apiService.fetchDiscussionMessagesFromApi();
    categoriesFuture = apiService.fetchTipCategoriesFromApi();
    tipsFuture = apiService.fetchTipsFromApi(
      categoryId: selectedCategory?.id,
      search: searchQuery,
      featured: showFeatured ? true : null,
      sort: sortBy,
    );
    discussionMessagesFuture.then((messages) {
      setState(() {
        _discussionMessages = messages;
      });
    });
  }

  void _loadSuccessStories() {
    setState(() {
      successStoriesFuture = apiService.fetchSuccessStoriesFromApi(
        search: storySearchQuery,
        cropType: selectedCropType,
        featured: showFeaturedStories ? true : null,
        sort: storySortBy,
      ).catchError((error) {
        print('Error loading success stories: $error');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading success stories: $error')),
        );
        return {
          'stories': <SuccessStory>[],
          'pagination': {},
        };
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _messageController.dispose();
    _searchController.dispose();
    _storySearchController.dispose();
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

  void _loadTips() {
    setState(() {
      tipsFuture = apiService.fetchTipsFromApi(
        categoryId: selectedCategory?.id,
        search: searchQuery,
        featured: showFeatured ? true : null,
        sort: sortBy,
      );
    });
  }

  void _loadData() {
    setState(() {
      categoriesFuture = apiService.fetchTipCategoriesFromApi();
      tipsFuture = apiService.fetchTipsFromApi(
        categoryId: selectedCategory?.id,
        search: searchQuery,
        featured: showFeatured ? true : null,
        sort: sortBy,
      );
    });
  }

  Future<void> _toggleStoryLike(SuccessStory story) async {
    try {
      final response = await apiService.toggleSuccessStoryLikeFromApi(story.id);
      _loadSuccessStories();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response['message'])),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error toggling like: $e')),
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
          Column(
            children: [
              // Search and Filter Bar
              Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    TextField(
                      controller: _storySearchController,
                      decoration: InputDecoration(
                        hintText: 'Search success stories...',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(Icons.clear),
                          onPressed: () {
                            _storySearchController.clear();
                            storySearchQuery = null;
                            _loadSuccessStories();
                          },
                        ),
                      ),
                      onSubmitted: (value) {
                        storySearchQuery = value.isEmpty ? null : value;
                        _loadSuccessStories();
                      },
                    ),
                    SizedBox(height: 10),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          FilterChip(
                            label: Text('Featured'),
                            selected: showFeaturedStories,
                            onSelected: (value) {
                              setState(() {
                                showFeaturedStories = value;
                                _loadSuccessStories();
                              });
                            },
                          ),
                          SizedBox(width: 8),
                          FilterChip(
                            label: Text('Latest'),
                            selected: storySortBy == 'latest',
                            onSelected: (value) {
                              if (value) {
                                setState(() {
                                  storySortBy = 'latest';
                                  _loadSuccessStories();
                                });
                              }
                            },
                          ),
                          SizedBox(width: 8),
                          FilterChip(
                            label: Text('Popular'),
                            selected: storySortBy == 'popular',
                            onSelected: (value) {
                              if (value) {
                                setState(() {
                                  storySortBy = 'popular';
                                  _loadSuccessStories();
                                });
                              }
                            },
                          ),
                          SizedBox(width: 8),
                          FilterChip(
                            label: Text('Most Viewed'),
                            selected: storySortBy == 'views',
                            onSelected: (value) {
                              if (value) {
                                setState(() {
                                  storySortBy = 'views';
                                  _loadSuccessStories();
                                });
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Success Stories List
              Expanded(
                child: FutureBuilder<Map<String, dynamic>>(
            future: successStoriesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Error loading success stories: ${snapshot.error}'),
                            SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadSuccessStories,
                              child: Text('Retry'),
                            ),
                          ],
                        ),
                      );
              } else if (snapshot.hasData) {
                      final stories = snapshot.data!['stories'] as List<SuccessStory>;
                      if (stories.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('No success stories found'),
                              if (storySearchQuery != null || showFeaturedStories || selectedCropType != null)
                                TextButton(
                                  onPressed: () {
                                    setState(() {
                                      storySearchQuery = null;
                                      showFeaturedStories = false;
                                      selectedCropType = null;
                                      _storySearchController.clear();
                                      _loadSuccessStories();
                                    });
                                  },
                                  child: Text('Clear filters'),
                                ),
                            ],
                          ),
                        );
                      }
                      return RefreshIndicator(
                        onRefresh: () {
                          _loadSuccessStories();
                          return Future.value();
                        },
                        child: ListView.builder(
                  padding: EdgeInsets.all(16.0),
                  itemCount: stories.length,
                  itemBuilder: (context, index) {
                    final story = stories[index];
                    return Card(
                      elevation: 2,
                      margin: EdgeInsets.symmetric(vertical: 8.0),
                              child: InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => SuccessStoryDetailScreen(story: story),
                                    ),
                                  ).then((_) {
                                    // Refresh the stories when returning from detail screen
                                    setState(() {
                                      _loadSuccessStories();
                                    });
                                  });
                                },
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          CircleAvatar(
                                            backgroundImage: story.user.imageUrl.isNotEmpty
                                                ? NetworkImage(story.user.imageUrl)
                                                : null,
                                            onBackgroundImageError: (_, __) {
                                              print('Error loading user image: ${story.user.imageUrl}');
                                            },
                                            child: story.user.imageUrl.isEmpty
                                                ? Icon(Icons.person, color: Colors.grey)
                                                : null,
                                          ),
                                          SizedBox(width: 10),
                                          Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                                story.user.name,
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              if (story.location != null)
                            Text(
                                                  story.location!,
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                            ],
                                          ),
                                          Spacer(),
                                          if (story.isFeatured)
                                            Chip(
                                              label: Text('Featured'),
                                              backgroundColor: Colors.amber[100],
                                            ),
                                        ],
                            ),
                            SizedBox(height: 10),
                                      Text(
                                        story.title,
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(height: 5),
                                      Text(story.content),
                                      if (story.cropType != null || story.yieldImprovement != null)
                                        Padding(
                                          padding: EdgeInsets.only(top: 10),
                                          child: Row(
                                            children: [
                                              if (story.cropType != null)
                                                Chip(
                                                  label: Text(story.cropType!),
                                                  backgroundColor: Colors.green[50],
                                                ),
                                              if (story.yieldImprovement != null) ...[
                                                SizedBox(width: 8),
                                                Chip(
                                                  label: Text('${story.yieldImprovement} ${story.yieldUnit ?? 'units'}'),
                                                  backgroundColor: Colors.blue[50],
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                      if (story.images.isNotEmpty)
                                        Padding(
                                          padding: EdgeInsets.only(top: 10),
                                          child: SizedBox(
                              height: 150,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                              itemCount: story.images.length,
                                itemBuilder: (context, imgIndex) {
                                                final image = story.images[imgIndex];
                                  return Padding(
                                    padding: EdgeInsets.only(right: 8.0),
                                    child: Container(
                                      width: 150,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8.0),
                                                      color: Colors.grey[200],
                                                    ),
                                                    child: ClipRRect(
                                                      borderRadius: BorderRadius.circular(8.0),
                                                      child: image.imagePath.isNotEmpty
                                                          ? Image.network(
                                                              image.imagePath,
                                          fit: BoxFit.cover,
                                                              width: 150,
                                                              height: 150,
                                                              errorBuilder: (context, error, stackTrace) {
                                                                print('Error loading story image: ${image.imagePath}');
                                                                return Container(
                                                                  width: 150,
                                                                  height: 150,
                                                                  color: Colors.grey[300],
                                                                  child: Icon(
                                                                    Icons.broken_image,
                                                                    size: 50,
                                                                    color: Colors.grey[600],
                                                                  ),
                                                                );
                                                              },
                                                              loadingBuilder: (context, child, loadingProgress) {
                                                                if (loadingProgress == null) return child;
                                                                return Container(
                                                                  width: 150,
                                                                  height: 150,
                                                                  color: Colors.grey[200],
                                                                  child: Center(
                                                                    child: CircularProgressIndicator(
                                                                      value: loadingProgress.expectedTotalBytes != null
                                                                          ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                                                          : null,
                                                                    ),
                                                                  ),
                                                                );
                                                              },
                                                            )
                                                          : Container(
                                                              width: 150,
                                                              height: 150,
                                                              color: Colors.grey[300],
                                                              child: Icon(
                                                                Icons.image_not_supported,
                                                                size: 50,
                                                                color: Colors.grey[600],
                                                              ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                                          ),
                                        ),
                                      SizedBox(height: 10),
                                      Row(
                                        children: [
                                          IconButton(
                                            icon: Icon(
                                              (story.isLiked ?? false) ? Icons.thumb_up : Icons.thumb_up_outlined,
                                              color: (story.isLiked ?? false) ? Colors.green : null,
                                            ),
                                            onPressed: () => _toggleStoryLike(story),
                                          ),
                                          Text('${story.likesCount}'),
                                          SizedBox(width: 16),
                                          IconButton(
                                            icon: Icon(Icons.comment_outlined),
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) => SuccessStoryDetailScreen(story: story),
                                                ),
                                              ).then((_) {
                                                setState(() {
                                                  _loadSuccessStories();
                                                });
                                              });
                                            },
                                          ),
                                          Text('${story.commentsCount}'),
                                          SizedBox(width: 16),
                                          IconButton(
                                            icon: Icon(Icons.visibility_outlined),
                                            onPressed: null,
                                          ),
                                          Text('${story.viewsCount}'),
                                          Spacer(),
                                          Text(
                                            '${story.createdAt.day}/${story.createdAt.month}/${story.createdAt.year}',
                                            style: TextStyle(color: Colors.grey[600]),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                        ),
                      ),
                    );
                  },
                        ),
                );
              }
              return SizedBox.shrink();
            },
                ),
              ),
            ],
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
          Column(
            children: [
              // Search and Filter Bar
              Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search tips...',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            searchQuery = null;
                            _loadTips();
                          },
                        ),
                      ),
                      onSubmitted: (value) {
                        searchQuery = value.isEmpty ? null : value;
                        _loadTips();
                      },
                    ),
                    SizedBox(height: 10),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          FilterChip(
                            label: Text('Featured'),
                            selected: showFeatured,
                            onSelected: (value) {
                              setState(() {
                                showFeatured = value;
                                _loadTips();
                              });
                            },
                          ),
                          SizedBox(width: 8),
                          FilterChip(
                            label: Text('Latest'),
                            selected: sortBy == 'latest',
                            onSelected: (value) {
                              if (value) {
                                setState(() {
                                  sortBy = 'latest';
                                  _loadTips();
                                });
                              }
                            },
                          ),
                          SizedBox(width: 8),
                          FilterChip(
                            label: Text('Popular'),
                            selected: sortBy == 'popular',
                            onSelected: (value) {
                              if (value) {
                                setState(() {
                                  sortBy = 'popular';
                                  _loadTips();
                                });
                              }
                            },
                          ),
                          SizedBox(width: 8),
                          FilterChip(
                            label: Text('Most Viewed'),
                            selected: sortBy == 'views',
                            onSelected: (value) {
                              if (value) {
                                setState(() {
                                  sortBy = 'views';
                                  _loadTips();
                                });
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Categories
              FutureBuilder<Map<String, dynamic>>(
                future: categoriesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Container(
                      height: 50,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  } else if (snapshot.hasError) {
                    return Container(
                      height: 50,
                      child: Center(child: Text('Error loading categories: ${snapshot.error}')),
                    );
                  } else if (snapshot.hasData) {
                    final categories = snapshot.data!['categories'] as List<TipCategory>;
                    if (categories.isEmpty) {
                      return Container(
                        height: 50,
                        child: Center(child: Text('No categories available')),
                      );
                    }
                    return Container(
                      height: 50,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: EdgeInsets.symmetric(horizontal: 16.0),
                        itemCount: categories.length,
                        itemBuilder: (context, index) {
                          final category = categories[index];
                          return Padding(
                            padding: EdgeInsets.only(right: 8.0),
                            child: FilterChip(
                              label: Text('${category.name} (${category.tipsCount})'),
                              selected: selectedCategory?.id == category.id,
                              onSelected: (value) {
                                setState(() {
                                  selectedCategory = value ? category : null;
                                  _loadTips();
                                });
                              },
                            ),
                          );
                        },
                      ),
                    );
                  }
                  return SizedBox.shrink();
                },
              ),

              // Tips List
              Expanded(
                child: FutureBuilder<Map<String, dynamic>>(
            future: tipsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Error loading tips: ${snapshot.error}'),
                            SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadTips,
                              child: Text('Retry'),
                            ),
                          ],
                        ),
                      );
              } else if (snapshot.hasData) {
                      final tips = snapshot.data!['tips'] as List<Tip>;
                      if (tips.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('No tips found'),
                              if (selectedCategory != null || searchQuery != null || showFeatured)
                                TextButton(
                                  onPressed: () {
                                    setState(() {
                                      selectedCategory = null;
                                      searchQuery = null;
                                      showFeatured = false;
                                      _searchController.clear();
                                      _loadTips();
                                    });
                                  },
                                  child: Text('Clear filters'),
                                ),
                            ],
                          ),
                        );
                      }
                      return RefreshIndicator(
                        onRefresh: () {
                          setState(() {
                            _loadTips();
                          });
                          return Future.value();
                        },
                        child: ListView.builder(
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
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          backgroundImage: tip.user.imageUrl.isNotEmpty
                                              ? NetworkImage(tip.user.imageUrl)
                                              : null,
                                          onBackgroundImageError: (_, __) {
                                            print('Error loading tip user image: ${tip.user.imageUrl}');
                                          },
                                          child: tip.user.imageUrl.isEmpty
                                              ? Icon(Icons.person, color: Colors.grey)
                                              : null,
                                        ),
                                        SizedBox(width: 10),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              tip.user.name,
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              tip.category.name,
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          ],
                                        ),
                                        Spacer(),
                                        if (tip.isFeatured)
                                          Chip(
                                            label: Text('Featured'),
                                            backgroundColor: Colors.amber[100],
                                          ),
                                      ],
                                    ),
                                    SizedBox(height: 10),
                            Text(
                                      tip.title,
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                            ),
                            SizedBox(height: 5),
                                    Text(tip.content),
                                    SizedBox(height: 10),
                                    Wrap(
                                      spacing: 8.0,
                                      children: tip.tags.map((tag) {
                                        return Chip(
                                          label: Text(tag),
                                          backgroundColor: Colors.green[50],
                                        );
                                      }).toList(),
                                    ),
                                    SizedBox(height: 10),
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: Icon(
                                            (tip.isLiked ?? false) ? Icons.thumb_up : Icons.thumb_up_outlined,
                                            color: (tip.isLiked ?? false) ? Colors.green : null,
                                          ),
                                          onPressed: () async {
                                            try {
                                              final response = await apiService.toggleTipLike(tip.id);
                                              setState(() {
                                                // Update the tip in the list
                                                final updatedTip = Tip(
                                                  id: tip.id,
                                                  userId: tip.userId,
                                                  categoryId: tip.categoryId,
                                                  title: tip.title,
                                                  slug: tip.slug,
                                                  content: tip.content,
                                                  isFeatured: tip.isFeatured,
                                                  viewsCount: tip.viewsCount,
                                                  likesCount: response['likesCount'],
                                                  tags: tip.tags,
                                                  createdAt: tip.createdAt,
                                                  updatedAt: tip.updatedAt,
                                                  likedByCount: response['isLiked'] ? (tip.likedByCount ?? 0) + 1 : (tip.likedByCount ?? 1) - 1,
                                                  savedByCount: tip.savedByCount,
                                                  category: tip.category,
                                                  user: tip.user,
                                                  isLiked: response['isLiked'],
                                                  isSaved: tip.isSaved,
                                                );
                                                final tips = (tipsFuture as Future<Map<String, dynamic>>).then((data) {
                                                  final updatedTips = List<Tip>.from(data['tips'] as List<Tip>);
                                                  final index = updatedTips.indexWhere((t) => t.id == tip.id);
                                                  if (index != -1) {
                                                    updatedTips[index] = updatedTip;
                                                  }
                                                  return {
                                                    'tips': updatedTips,
                                                    'pagination': data['pagination'],
                                                  };
                                                });
                                                tipsFuture = tips;
                                              });
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(content: Text(response['message'])),
                                              );
                                            } catch (e) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(content: Text('Failed to update like: $e')),
                                              );
                                            }
                                          },
                                        ),
                                        Text('${tip.likesCount}'),
                                        SizedBox(width: 16),
                                        IconButton(
                                          icon: Icon(
                                            (tip.isSaved ?? false) ? Icons.bookmark : Icons.bookmark_border,
                                            color: (tip.isSaved ?? false) ? Colors.green : null,
                                          ),
                                          onPressed: () async {
                                            try {
                                              final response = await apiService.toggleTipSave(tip.id);
                                              setState(() {
                                                // Update the tip in the list
                                                final updatedTip = Tip(
                                                  id: tip.id,
                                                  userId: tip.userId,
                                                  categoryId: tip.categoryId,
                                                  title: tip.title,
                                                  slug: tip.slug,
                                                  content: tip.content,
                                                  isFeatured: tip.isFeatured,
                                                  viewsCount: tip.viewsCount,
                                                  likesCount: tip.likesCount,
                                                  tags: tip.tags,
                                                  createdAt: tip.createdAt,
                                                  updatedAt: tip.updatedAt,
                                                  likedByCount: tip.likedByCount,
                                                  savedByCount: response['isSaved'] ? (tip.savedByCount ?? 0) + 1 : (tip.savedByCount ?? 1) - 1,
                                                  category: tip.category,
                                                  user: tip.user,
                                                  isLiked: tip.isLiked,
                                                  isSaved: response['isSaved'],
                                                );
                                                final tips = (tipsFuture as Future<Map<String, dynamic>>).then((data) {
                                                  final updatedTips = List<Tip>.from(data['tips'] as List<Tip>);
                                                  final index = updatedTips.indexWhere((t) => t.id == tip.id);
                                                  if (index != -1) {
                                                    updatedTips[index] = updatedTip;
                                                  }
                                                  return {
                                                    'tips': updatedTips,
                                                    'pagination': data['pagination'],
                                                  };
                                                });
                                                tipsFuture = tips;
                                              });
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(content: Text(response['message'])),
                                              );
                                            } catch (e) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(content: Text('Failed to update save: $e')),
                                              );
                                            }
                                          },
                                        ),
                                        Spacer(),
                            Text(
                                          '${tip.createdAt.day}/${tip.createdAt.month}/${tip.createdAt.year}',
                                          style: TextStyle(color: Colors.grey[600]),
                                        ),
                                      ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                        ),
                );
              }
              return SizedBox.shrink();
            },
                ),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: AnimatedSwitcher(
        duration: Duration(milliseconds: 200),
        child: _tabController.index == 0
            ? FloatingActionButton(
                key: ValueKey('success_stories_fab'),
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CreateSuccessStoryScreen(),
                    ),
                  );
                  if (result == true) {
                    // Refresh the success stories list
                    setState(() {
                      _loadSuccessStories();
                    });
                  }
                },
                child: Icon(Icons.add),
                backgroundColor: Colors.green,
              )
            : SizedBox.shrink(),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 3, // Community tab
        onTap: _onNavTap,
      ),
    );
  }
}
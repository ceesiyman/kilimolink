import 'package:flutter/material.dart';
import '../model/success_story_model.dart';
import '../model/discussion_message_model.dart';
import '../model/community_message_model.dart' as community;
import '../model/tip_model.dart';
import '../model/tip_category_model.dart';
import '../service/api_service.dart';
import '../service/community_api_service.dart';
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
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:io';
import 'dart:async';

class CommunityScreen extends StatefulWidget {
  @override
  _CommunityScreenState createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> with SingleTickerProviderStateMixin {
  final ApiService apiService = ApiService();
  final CommunityApiService communityApiService = CommunityApiService();
  final AuthStorageService authStorage = AuthStorageService();
  late TabController _tabController;
  late Future<Map<String, dynamic>> successStoriesFuture;
  late Future<Map<String, dynamic>> communityMessagesFuture;
  late Future<Map<String, dynamic>> categoriesFuture;
  late Future<Map<String, dynamic>> tipsFuture;
  final bool useRealApi = true;
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _storySearchController = TextEditingController();
  final TextEditingController _communitySearchController = TextEditingController();
  List<community.CommunityMessage> _communityMessages = [];
  TipCategory? selectedCategory;
  String? searchQuery;
  String? storySearchQuery;
  String? communitySearchQuery;
  String sortBy = 'latest';
  String storySortBy = 'latest';
  bool showFeatured = false;
  bool showFeaturedStories = false;
  String? selectedCropType;
  final ImagePicker _imagePicker = ImagePicker();
  
  // Reply functionality
  community.CommunityMessage? _replyingTo;
  List<File> _attachments = [];
  
  // Replies functionality
  Set<int> _expandedReplies = {}; // Track which messages have replies expanded
  Map<int, List<community.MessageReply>> _messageReplies = {}; // Cache replies for each message
  Map<int, bool> _loadingReplies = {}; // Track loading state for replies
  
  // Scroll controller for auto-scrolling to bottom
  final ScrollController _scrollController = ScrollController();
  
  // Polling variables
  Timer? _pollingTimer;
  int? _lastMessageId;
  String? _lastUpdated;
  bool _isPolling = false;
  int? _currentUserId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      // Force rebuild when tab changes to update floating action button
      setState(() {});
    });
    _loadCurrentUserId();
    _loadSuccessStories();
    _loadCommunityMessages();
    categoriesFuture = apiService.fetchTipCategoriesFromApi();
    tipsFuture = apiService.fetchTipsFromApi(
      categoryId: selectedCategory?.id,
      search: searchQuery,
      featured: showFeatured ? true : null,
      sort: sortBy,
    );
    
    // Start polling for real-time updates
    _startPolling();
  }

  Future<void> _loadCurrentUserId() async {
    try {
      final authData = await authStorage.getAuthData();
      final userId = authData['userId'];
      setState(() {
        _currentUserId = userId != null ? int.tryParse(userId) : null;
      });
    } catch (e) {
      print('Error loading current user ID: $e');
    }
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

  void _loadCommunityMessages() {
    setState(() {
      communityMessagesFuture = communityApiService.fetchCommunityMessagesFromApi(
        search: communitySearchQuery,
        lastUpdated: _lastUpdated,
      ).catchError((error) {
        print('Error loading community messages: $error');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading community messages: $error')),
        );
        return {
          'messages': <community.CommunityMessage>[],
          'pagination': {},
          'server_time': null,
          'polling_interval': 3000,
        };
      });
    });

    communityMessagesFuture.then((data) {
      setState(() {
        // Reverse the messages to show newest at bottom
        _communityMessages = (data['messages'] as List<community.CommunityMessage>).reversed.toList();
        _lastUpdated = data['server_time'];
        if (_communityMessages.isNotEmpty) {
          _lastMessageId = _communityMessages.last.id; // Use last instead of first
        }
      });
    });
  }

  void _startPolling() {
    _isPolling = true;
    _pollingTimer = Timer.periodic(Duration(seconds: 3), (timer) {
      if (_isPolling && mounted) {
        _pollForNewMessages();
      }
    });
  }

  void _stopPolling() {
    _isPolling = false;
    _pollingTimer?.cancel();
  }

  Future<void> _pollForNewMessages() async {
    try {
      final data = await communityApiService.pollCommunityMessagesFromApi(
        lastId: _lastMessageId,
        lastUpdated: _lastUpdated,
      );

      if (data['has_new_messages'] && mounted) {
        final newMessages = data['messages'] as List<community.CommunityMessage>;
        setState(() {
          // Add new messages to the end of the list (newest at bottom)
          _communityMessages.addAll(newMessages);
          _lastUpdated = data['server_time'];
          if (newMessages.isNotEmpty) {
            _lastMessageId = newMessages.last.id; // Use last instead of first
          }
        });
        
        // Auto-scroll to bottom when new messages arrive
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom();
        });
      }
    } catch (e) {
      print('Error polling for new messages: $e');
    }
  }

  @override
  void dispose() {
    _stopPolling();
    _tabController.dispose();
    _scrollController.dispose();
    _messageController.dispose();
    _searchController.dispose();
    _storySearchController.dispose();
    _communitySearchController.dispose();
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

  void _sendCommunityMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty && _attachments.isEmpty) return;

    try {
      Map<String, dynamic> result;
      
      if (_replyingTo != null) {
        // Use reply API when replying to a message
        result = await communityApiService.createMessageReplyFromApi(
          messageId: _replyingTo!.id,
      content: message,
    );
      } else {
        // Use regular message creation API
        result = await communityApiService.createCommunityMessageFromApi(
          content: message,
          attachments: _attachments.isNotEmpty ? _attachments : null,
        );
      }
      
      if (mounted) {
        setState(() {
          if (_replyingTo != null) {
            // For replies, we need to update the replies count of the original message
            final index = _communityMessages.indexWhere((m) => m.id == _replyingTo!.id);
            if (index != -1) {
              final originalMessage = _communityMessages[index];
              final updatedMessage = community.CommunityMessage(
                id: originalMessage.id,
                userId: originalMessage.userId,
                title: originalMessage.title,
                content: originalMessage.content,
                category: originalMessage.category,
                tags: originalMessage.tags,
                isPinned: originalMessage.isPinned,
                isAnnouncement: originalMessage.isAnnouncement,
                viewsCount: originalMessage.viewsCount,
                likesCount: originalMessage.likesCount,
                repliesCount: originalMessage.repliesCount + 1,
                createdAt: originalMessage.createdAt,
                updatedAt: originalMessage.updatedAt,
                user: originalMessage.user,
                attachments: originalMessage.attachments,
                replies: originalMessage.replies,
                isLiked: originalMessage.isLiked,
              );
              _communityMessages[index] = updatedMessage;
            }
          } else {
            // Add new message to the end of the list (newest at bottom)
            _communityMessages.add(result['data'] as community.CommunityMessage);
            _lastMessageId = result['data'].id;
          }
        _messageController.clear();
          _attachments.clear();
          _replyingTo = null;
        });
        
        // Auto-scroll to bottom after sending message
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom();
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'])),
        );
      }
    } catch (e) {
      if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending message: $e')),
        );
      }
    }
  }

  void _cancelReply() {
    setState(() {
      _replyingTo = null;
    });
  }

  Future<void> _pickAttachments() async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage();
      if (images.isNotEmpty) {
        setState(() {
          _attachments.addAll(images.map((image) => File(image.path)));
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking images: $e')),
      );
    }
  }

  void _removeAttachment(int index) {
    setState(() {
      _attachments.removeAt(index);
    });
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _fetchMessageReplies(int messageId) async {
    if (_loadingReplies[messageId] == true) return;
    
    setState(() {
      _loadingReplies[messageId] = true;
    });
    
    try {
      final result = await communityApiService.fetchMessageRepliesFromApi(messageId);
      
      if (mounted) {
        setState(() {
          _messageReplies[messageId] = result['replies'] as List<community.MessageReply>;
          _loadingReplies[messageId] = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingReplies[messageId] = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading replies: $e')),
        );
      }
    }
  }

  void _toggleReplies(int messageId) {
    setState(() {
      if (_expandedReplies.contains(messageId)) {
        _expandedReplies.remove(messageId);
      } else {
        _expandedReplies.add(messageId);
        // Fetch replies if not already cached
        if (!_messageReplies.containsKey(messageId)) {
          _fetchMessageReplies(messageId);
        }
      }
    });
  }

  Widget _buildReplyWidget(community.MessageReply reply, int messageId) {
    final isCurrentUser = reply.userId == _currentUserId;
    
    return Padding(
      padding: EdgeInsets.only(left: 20, top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Reply line
          Container(
            width: 2,
            height: 40,
            color: Colors.grey[300],
          ),
          SizedBox(width: 8),
          
          // Reply content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User info
                Row(
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundImage: (reply.user.imageUrl != null && reply.user.imageUrl!.isNotEmpty)
                          ? NetworkImage(reply.user.imageUrl!) as ImageProvider
                          : null,
                      child: (reply.user.imageUrl == null || reply.user.imageUrl!.isEmpty)
                          ? Icon(Icons.person, size: 12, color: Colors.grey)
                          : null,
                    ),
                    SizedBox(width: 6),
                    Text(
                      reply.user.name,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                    SizedBox(width: 6),
                    Text(
                      '${reply.createdAt.hour.toString().padLeft(2, '0')}:${reply.createdAt.minute.toString().padLeft(2, '0')}',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4),
                
                // Reply content
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    reply.content,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.black87,
                    ),
                  ),
                ),
                
                // Reply actions
                Padding(
                  padding: EdgeInsets.only(top: 4, left: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: () async {
                          try {
                            final result = await communityApiService.toggleMessageReplyLikeFromApi(
                              messageId,
                              reply.id,
                            );
                            
                            if (mounted) {
                              setState(() {
                                final replies = _messageReplies[messageId];
                                if (replies != null) {
                                  final index = replies.indexWhere((r) => r.id == reply.id);
                                  if (index != -1) {
                                    final updatedReply = community.MessageReply(
                                      id: reply.id,
                                      communityMessageId: reply.communityMessageId,
                                      userId: reply.userId,
                                      content: reply.content,
                                      parentReplyId: reply.parentReplyId,
                                      likesCount: result['likes_count'],
                                      createdAt: reply.createdAt,
                                      updatedAt: reply.updatedAt,
                                      user: reply.user,
                                      replies: reply.replies,
                                      isLiked: result['is_liked'],
                                    );
                                    replies[index] = updatedReply;
                                  }
                                }
                              });
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error toggling like: $e')),
                              );
                            }
                          }
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              reply.isLiked == true ? Icons.thumb_up : Icons.thumb_up_outlined,
                              size: 12,
                              color: reply.isLiked == true ? Colors.green : Colors.grey[500],
                            ),
                            SizedBox(width: 2),
                            Text(
                              '${reply.likesCount}',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 12),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _replyingTo = _communityMessages.firstWhere((m) => m.id == messageId);
                          });
                        },
                        child: Text(
                          'Reply',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleMessageLike(community.CommunityMessage message) async {
    try {
      final result = await communityApiService.toggleCommunityMessageLikeFromApi(message.id);
      
      if (mounted) {
        setState(() {
          final index = _communityMessages.indexWhere((m) => m.id == message.id);
          if (index != -1) {
            final updatedMessage = community.CommunityMessage(
              id: message.id,
              userId: message.userId,
              title: message.title,
              content: message.content,
              category: message.category,
              tags: message.tags,
              isPinned: message.isPinned,
              isAnnouncement: message.isAnnouncement,
              viewsCount: message.viewsCount,
              likesCount: result['likes_count'],
              repliesCount: message.repliesCount,
              createdAt: message.createdAt,
              updatedAt: message.updatedAt,
              user: message.user,
              attachments: message.attachments,
              replies: message.replies,
              isLiked: result['is_liked'],
            );
            _communityMessages[index] = updatedMessage;
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'])),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error toggling like: $e')),
        );
      }
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
              // Search and Filter Bar for Community Messages
              Padding(
                  padding: EdgeInsets.all(16.0),
                child: TextField(
                  controller: _communitySearchController,
                  decoration: InputDecoration(
                    hintText: 'Search community messages...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(Icons.clear),
                      onPressed: () {
                        _communitySearchController.clear();
                        communitySearchQuery = null;
                        _loadCommunityMessages();
                      },
                    ),
                  ),
                  onSubmitted: (value) {
                    communitySearchQuery = value.isEmpty ? null : value;
                    _loadCommunityMessages();
                  },
                ),
              ),

              // Community Messages List
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () {
                    _loadCommunityMessages();
                    return Future.value();
                  },
                  child: _communityMessages.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('No community messages found'),
                              if (communitySearchQuery != null)
                                TextButton(
                                  onPressed: () {
                                    setState(() {
                                      communitySearchQuery = null;
                                      _communitySearchController.clear();
                                      _loadCommunityMessages();
                                    });
                                  },
                                  child: Text('Clear search'),
                                ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: EdgeInsets.all(8.0),
                          itemCount: _communityMessages.length,
                          reverse: false,
                  itemBuilder: (context, index) {
                            final message = _communityMessages[index];
                            final isCurrentUser = message.userId == _currentUserId;
                            
                            return Padding(
                              padding: EdgeInsets.symmetric(vertical: 4.0),
                              child: Row(
                                mainAxisAlignment: isCurrentUser 
                                    ? MainAxisAlignment.end 
                                    : MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (!isCurrentUser) ...[
                                    // Other user's avatar
                                    CircleAvatar(
                                      radius: 16,
                                      backgroundImage: (message.user.imageUrl != null && message.user.imageUrl!.isNotEmpty)
                                          ? NetworkImage(message.user.imageUrl!) as ImageProvider
                                          : null,
                                      child: (message.user.imageUrl == null || message.user.imageUrl!.isEmpty)
                                          ? Icon(Icons.person, size: 16, color: Colors.grey)
                                          : null,
                                    ),
                                    SizedBox(width: 8),
                                  ],
                                  
                                  // Message bubble
                                  Flexible(
                      child: Container(
                                      constraints: BoxConstraints(
                                        maxWidth: MediaQuery.of(context).size.width * 0.75,
                                      ),
                                      child: Column(
                                        crossAxisAlignment: isCurrentUser 
                                            ? CrossAxisAlignment.end 
                                            : CrossAxisAlignment.start,
                                        children: [
                                          // User name (only for other users)
                                          if (!isCurrentUser) ...[
                                            Padding(
                                              padding: EdgeInsets.only(left: 8, bottom: 2),
                                              child: Text(
                                                message.user.name,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                            ),
                                          ],
                                          
                                          // Message bubble
                                          GestureDetector(
                                            onDoubleTap: () => _toggleMessageLike(message),
                                            child: Container(
                                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                                                color: isCurrentUser 
                                                    ? Colors.green[400] 
                                                    : Colors.grey[200],
                                                borderRadius: BorderRadius.circular(18),
                                              ),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  // Title if present
                                                  if (message.title != null) ...[
                                                    Text(
                                                      message.title!,
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        fontWeight: FontWeight.bold,
                                                        color: isCurrentUser ? Colors.white : Colors.black87,
                                                      ),
                                                    ),
                                                    SizedBox(height: 4),
                                                  ],
                                                  
                                                  // Content
                                                  Text(
                                                    message.content,
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      color: isCurrentUser ? Colors.white : Colors.black87,
                                                    ),
                                                  ),
                                                  
                                                  // Tags if present
                                                  if (message.tags != null && message.tags!.isNotEmpty) ...[
                                                    SizedBox(height: 6),
                                                    Wrap(
                                                      spacing: 4.0,
                                                      runSpacing: 2.0,
                                                      children: message.tags!.map((tag) {
                                                        return Container(
                                                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                          decoration: BoxDecoration(
                                                            color: isCurrentUser 
                                                                ? Colors.white.withOpacity(0.3) 
                                                                : Colors.green[100],
                                                            borderRadius: BorderRadius.circular(8),
                                                          ),
                                                          child: Text(
                                                            tag,
                                                            style: TextStyle(
                                                              fontSize: 10,
                                                              color: isCurrentUser ? Colors.white : Colors.green[800],
                                                            ),
                                                          ),
                                                        );
                                                      }).toList(),
                                                    ),
                                                  ],
                                                  
                                                  // Attachments if present
                                                  if (message.attachments != null && message.attachments!.isNotEmpty) ...[
                                                    SizedBox(height: 6),
                                                    SizedBox(
                                                      height: 60,
                                                      child: ListView.builder(
                                                        scrollDirection: Axis.horizontal,
                                                        itemCount: message.attachments!.length,
                                                        itemBuilder: (context, imgIndex) {
                                                          final attachment = message.attachments![imgIndex];
                                                          return Padding(
                                                            padding: EdgeInsets.only(right: 4.0),
                                                            child: Container(
                                                              width: 60,
                                                              decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8.0),
                                                                color: Colors.grey[300],
                                                              ),
                                                              child: ClipRRect(
                                                                borderRadius: BorderRadius.circular(8.0),
                                                                child: attachment.fileType == 'image'
                                                                    ? Image.network(
                                                                        '${dotenv.env['IMAGE_BASE_URL'] ?? ''}${attachment.filePath}',
                                                                        fit: BoxFit.cover,
                                                                        width: 60,
                                                                        height: 60,
                                                                        errorBuilder: (context, error, stackTrace) {
                                                                          return Container(
                                                                            width: 60,
                                                                            height: 60,
                                                                            color: Colors.grey[300],
                                                                            child: Icon(
                                                                              Icons.broken_image,
                                                                              size: 20,
                                                                              color: Colors.grey[600],
                                                                            ),
                                                                          );
                                                                        },
                                                                      )
                                                                    : Container(
                                                                        width: 60,
                                                                        height: 60,
                                                                        color: Colors.grey[300],
                                                                        child: Icon(
                                                                          Icons.attach_file,
                                                                          size: 20,
                                                                          color: Colors.grey[600],
                                                                        ),
                                                                      ),
                                                              ),
                                                            ),
                                                          );
                                                        },
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ),
                                          ),
                                          
                                          // Message info (time, likes, etc.)
                                          Padding(
                                            padding: EdgeInsets.only(
                                              left: isCurrentUser ? 0 : 8,
                                              right: isCurrentUser ? 8 : 0,
                                              top: 4,
                                            ),
                                            child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                                Text(
                                                  '${message.createdAt.hour.toString().padLeft(2, '0')}:${message.createdAt.minute.toString().padLeft(2, '0')}',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: Colors.grey[500],
                                                  ),
                                                ),
                                                SizedBox(width: 8),
                                                if (message.likesCount > 0) ...[
                                                  Icon(
                                                    Icons.thumb_up,
                                                    size: 12,
                                                    color: Colors.grey[500],
                                                  ),
                                                  SizedBox(width: 2),
                                                  Text(
                                                    '${message.likesCount}',
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      color: Colors.grey[500],
                                                    ),
                                                  ),
                                                  SizedBox(width: 8),
                                                ],
                                                if (message.repliesCount > 0) ...[
                                                  Icon(
                                                    Icons.reply,
                                                    size: 12,
                                                    color: Colors.grey[500],
                                                  ),
                                                  SizedBox(width: 2),
                                                  Text(
                                                    '${message.repliesCount}',
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      color: Colors.grey[500],
                                                    ),
                                                  ),
                                                  SizedBox(width: 8),
                                                ],
                                                // Reply button
                                                GestureDetector(
                                                  onTap: () {
                                                    setState(() {
                                                      _replyingTo = message;
                                                    });
                                                  },
                                                  child: Icon(
                                                    Icons.reply,
                                                    size: 14,
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          
                                          // Show replies button
                                          if (message.repliesCount > 0) ...[
                                            Padding(
                                              padding: EdgeInsets.only(
                                                left: isCurrentUser ? 0 : 8,
                                                right: isCurrentUser ? 8 : 0,
                                                top: 4,
                                              ),
                                              child: GestureDetector(
                                                onTap: () => _toggleReplies(message.id),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                  Container(
                                                      width: 20,
                                                      height: 1,
                                                      color: Colors.grey[300],
                                                    ),
                                                    SizedBox(width: 8),
                                                    Text(
                                                      _expandedReplies.contains(message.id) 
                                                          ? 'Hide replies' 
                                                          : 'Show ${message.repliesCount} replies',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.grey[600],
                                                        fontWeight: FontWeight.w500,
                                                      ),
                                                    ),
                                                    SizedBox(width: 4),
                                                    Icon(
                                                      _expandedReplies.contains(message.id)
                                                          ? Icons.keyboard_arrow_up
                                                          : Icons.keyboard_arrow_down,
                                                      size: 16,
                                                      color: Colors.grey[600],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            
                                            // Replies list
                                            if (_expandedReplies.contains(message.id)) ...[
                                              SizedBox(height: 8),
                                              if (_loadingReplies[message.id] == true)
                                                Padding(
                                                  padding: EdgeInsets.symmetric(vertical: 8),
                                                  child: Center(
                                                    child: SizedBox(
                                                      width: 20,
                                                      height: 20,
                                                      child: CircularProgressIndicator(strokeWidth: 2),
                                                    ),
                                                  ),
                                                )
                                              else if (_messageReplies.containsKey(message.id))
                                                ...(_messageReplies[message.id]!.map((reply) => _buildReplyWidget(reply, message.id))),
                                            ],
                                          ],
                                        ],
                                      ),
                                    ),
                                  ),
                                  
                                  if (isCurrentUser) ...[
                                    SizedBox(width: 8),
                                    // Current user's avatar
                                    CircleAvatar(
                                      radius: 16,
                                      backgroundImage: (message.user.imageUrl != null && message.user.imageUrl!.isNotEmpty)
                                          ? NetworkImage(message.user.imageUrl!) as ImageProvider
                                          : null,
                                      child: (message.user.imageUrl == null || message.user.imageUrl!.isEmpty)
                                          ? Icon(Icons.person, size: 16, color: Colors.grey)
                                          : null,
                                    ),
                                  ],
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ),
              
              // Message Input
                                  Container(
                padding: EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      spreadRadius: 1,
                      blurRadius: 3,
                      offset: Offset(0, -1),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Reply indicator
                    if (_replyingTo != null) ...[
                      Container(
                        padding: EdgeInsets.all(8),
                        margin: EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.reply, size: 16, color: Colors.grey[600]),
                            SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Replying to ${_replyingTo!.user.name}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                  Text(
                                    _replyingTo!.content.length > 50 
                                        ? '${_replyingTo!.content.substring(0, 50)}...'
                                        : _replyingTo!.content,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.close, size: 16),
                              onPressed: _cancelReply,
                              padding: EdgeInsets.zero,
                              constraints: BoxConstraints(
                                minWidth: 24,
                                minHeight: 24,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    
                    // Attachment preview
                    if (_attachments.isNotEmpty) ...[
                      Container(
                        height: 80,
                        margin: EdgeInsets.only(bottom: 8),
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _attachments.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: EdgeInsets.only(right: 8),
                              child: Stack(
                                children: [
                                  Container(
                                    width: 80,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      color: Colors.grey[200],
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.file(
                                        _attachments[index],
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Container(
                                            width: 80,
                                            height: 80,
                                            color: Colors.grey[300],
                                            child: Icon(
                                              Icons.broken_image,
                                              size: 30,
                                              color: Colors.grey[600],
                      ),
                    );
                  },
                ),
              ),
                                  ),
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: GestureDetector(
                                      onTap: () => _removeAttachment(index),
                                      child: Container(
                                        padding: EdgeInsets.all(2),
                                        decoration: BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.close,
                                          size: 12,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                    
                    // Input row
                    Row(
                  children: [
                        // Attachment button
                        IconButton(
                          icon: Icon(Icons.attach_file, color: Colors.grey[600]),
                          onPressed: _pickAttachments,
                          constraints: BoxConstraints(
                            minWidth: 40,
                            minHeight: 40,
                          ),
                        ),
                        SizedBox(width: 4),
                        
                        // Text input
                    Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(24),
                            ),
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                                hintText: _replyingTo != null 
                                    ? 'Reply to ${_replyingTo!.user.name}...'
                                    : 'Type a message...',
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              ),
                              maxLines: null,
                              textInputAction: TextInputAction.send,
                              onSubmitted: (_) => _sendCommunityMessage(),
                        ),
                      ),
                    ),
                        SizedBox(width: 8),
                        
                        // Send button
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: Icon(Icons.send, color: Colors.white, size: 20),
                            onPressed: _sendCommunityMessage,
                            constraints: BoxConstraints(
                              minWidth: 40,
                              minHeight: 40,
                            ),
                          ),
                        ),
                      ],
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
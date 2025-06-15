import 'package:flutter/material.dart';
import '../model/tip_model.dart';
import '../model/tip_category_model.dart';
import '../service/api_service.dart';
import '../service/auth_storage_service.dart';
import 'create_tip_screen.dart';
import 'login_screen.dart';

class ViewTipsScreen extends StatefulWidget {
  @override
  _ViewTipsScreenState createState() => _ViewTipsScreenState();
}

class _ViewTipsScreenState extends State<ViewTipsScreen> {
  final ApiService apiService = ApiService();
  final AuthStorageService authStorage = AuthStorageService();
  late Future<Map<String, dynamic>> categoriesFuture;
  late Future<Map<String, dynamic>> tipsFuture;
  TipCategory? selectedCategory;
  String? searchQuery;
  String sortBy = 'latest'; // 'latest', 'popular', 'views'
  bool showFeatured = false;
  final TextEditingController _searchController = TextEditingController();
  String? _userRole;

  @override
  void initState() {
    super.initState();
    _loadData();
    _checkUserRole();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh user role when dependencies change
    _checkUserRole();
  }

  void _loadData() {
    setState(() {
      // Load categories and tips from real API
      categoriesFuture = apiService.fetchTipCategoriesFromApi();
      tipsFuture = apiService.fetchTipsFromApi(
        categoryId: selectedCategory?.id,
        search: searchQuery,
        featured: showFeatured ? true : null,
        sort: sortBy,
      );
    });
  }

  Future<void> _checkUserRole() async {
    try {
      final isLoggedIn = await authStorage.isLoggedIn();
      print('Is logged in: $isLoggedIn');
      if (isLoggedIn) {
        final role = await authStorage.getUserRole();
        print('User role: $role');
        setState(() {
          _userRole = role;
        });
        print('Set user role in state: $_userRole');
      }
    } catch (e) {
      print('Error checking user role: $e');
    }
  }

  Future<void> _checkAuthAndNavigate() async {
    final isLoggedIn = await authStorage.isLoggedIn();
    
    if (isLoggedIn) {
      // Check if user is an expert
      if (_userRole == 'expert') {
        // User is logged in and is an expert, navigate to create tip screen
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CreateTipScreen(),
          ),
        );
        
        // If tip was created successfully, refresh the tips list
        if (result == true) {
          setState(() {
            _loadData();
          });
        }
      } else {
        // User is logged in but not an expert
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Only experts can create tips'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } else {
      // User is not logged in, navigate to login screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => LoginScreen(),
        ),
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('View Tips & Advice'),
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: Column(
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
                                      backgroundImage: NetworkImage(tip.user.imageUrl),
                                      onBackgroundImageError: (_, __) {},
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
      floatingActionButton: () {
        print('Building FAB - User role: $_userRole');
        final shouldShowFab = _userRole?.toLowerCase() == 'expert';
        print('Should show FAB: $shouldShowFab');
        return shouldShowFab
            ? FloatingActionButton(
                onPressed: _checkAuthAndNavigate,
                backgroundColor: Colors.green,
                child: Icon(Icons.add, color: Colors.white),
                tooltip: 'Create Tip',
              )
            : null;
      }(),
    );
  }
}
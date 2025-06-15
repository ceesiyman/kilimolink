import 'package:flutter/material.dart';
import '../model/tip_model.dart';
import '../service/api_service.dart';

class SavedTipsScreen extends StatefulWidget {
  @override
  _SavedTipsScreenState createState() => _SavedTipsScreenState();
}

class _SavedTipsScreenState extends State<SavedTipsScreen> {
  final ApiService apiService = ApiService();
  late Future<Map<String, dynamic>> savedTipsFuture;

  @override
  void initState() {
    super.initState();
    _loadSavedTips();
  }

  void _loadSavedTips() {
    setState(() {
      savedTipsFuture = apiService.fetchSavedTipsFromApi();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Saved Tips'),
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadSavedTips,
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: savedTipsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error loading saved tips: ${snapshot.error}'),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadSavedTips,
                    child: Text('Retry'),
                  ),
                ],
              ),
            );
          } else if (snapshot.hasData) {
            final data = snapshot.data!['tips'];
            if (data == null || data['data'] == null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.bookmark_border, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'No saved tips yet',
                      style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Save tips to read them later',
                      style: TextStyle(color: Colors.grey[500]),
                    ),
                  ],
                ),
              );
            }
            
            final tipsData = data['data'] as List<dynamic>;
            final tips = tipsData.map((tipJson) {
              try {
                return Tip.fromJson(tipJson);
              } catch (e) {
                print('Error parsing tip: $e');
                return null;
              }
            }).where((tip) => tip != null).cast<Tip>().toList();
            
            if (tips.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.bookmark_border, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'No saved tips yet',
                      style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Save tips to read them later',
                      style: TextStyle(color: Colors.grey[500]),
                    ),
                  ],
                ),
              );
            }
            return RefreshIndicator(
              onRefresh: () async {
                _loadSavedTips();
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
                              IconButton(
                                icon: Icon(
                                  Icons.bookmark,
                                  color: Colors.green,
                                ),
                                onPressed: () async {
                                  try {
                                    final response = await apiService.toggleTipSave(tip.id);
                                    if (!response['isSaved']) {
                                      // Remove the tip from the list if it's unsaved
                                      setState(() {
                                        savedTipsFuture = savedTipsFuture.then((data) {
                                          final updatedData = Map<String, dynamic>.from(data);
                                          final updatedTips = Map<String, dynamic>.from(updatedData['tips']);
                                          final updatedTipsList = List<dynamic>.from(updatedTips['data'] ?? []);
                                          updatedTipsList.removeWhere((t) => t['id'] == tip.id);
                                          updatedTips['data'] = updatedTipsList;
                                          updatedTips['total'] = (updatedTips['total'] as int?) ?? 0;
                                          updatedTips['total'] = (updatedTips['total'] as int) - 1;
                                          updatedData['tips'] = updatedTips;
                                          return updatedData;
                                        });
                                      });
                                    }
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(response['message'])),
                                    );
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Failed to unsave tip: $e')),
                                    );
                                  }
                                },
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
                              Icon(Icons.visibility, size: 16),
                              SizedBox(width: 4),
                              Text('${tip.viewsCount}'),
                              SizedBox(width: 16),
                              Icon(Icons.thumb_up, size: 16),
                              SizedBox(width: 4),
                              Text('${tip.likesCount}'),
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
    );
  }
}
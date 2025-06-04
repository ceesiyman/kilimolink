import 'package:flutter/material.dart';
import '../model/expert_model.dart';
import '../service/api_service.dart';

class ViewTipsScreen extends StatefulWidget {
  @override
  _ViewTipsScreenState createState() => _ViewTipsScreenState();
}

class _ViewTipsScreenState extends State<ViewTipsScreen> {
  final ApiService apiService = ApiService();
  late Future<List<Expert>> expertsFuture;
  final bool useRealApi = false;

  @override
  void initState() {
    super.initState();
    expertsFuture = useRealApi ? apiService.fetchExpertsFromApi() : apiService.fetchExperts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('View Tips & Advice'),
        backgroundColor: Colors.green,
      ),
      body: FutureBuilder<List<Expert>>(
        future: expertsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.hasData) {
            final experts = snapshot.data!;
            return ListView.builder(
              padding: EdgeInsets.all(16.0),
              itemCount: experts.length,
              itemBuilder: (context, index) {
                final expert = experts[index];
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
                            Container(
                              width: 40,
                              height: 40,
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
                            SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  expert.name,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  expert.specialty,
                                  style: TextStyle(fontSize: 14),
                                ),
                              ],
                            ),
                          ],
                        ),
                        SizedBox(height: 10),
                        if (expert.tips != null && expert.tips!.isNotEmpty)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: expert.tips!.map((tip) {
                              return Padding(
                                padding: EdgeInsets.symmetric(vertical: 4.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(Icons.check, color: Colors.green, size: 20),
                                    SizedBox(width: 8),
                                    Expanded(child: Text(tip)),
                                  ],
                                ),
                              );
                            }).toList(),
                          )
                        else
                          Text('No tips available from this expert.'),
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
    );
  }
}
import 'package:flutter/material.dart';
import '../service/api_service.dart';

class MyFavoritesScreen extends StatefulWidget {
  final List<String>? favorites;

  const MyFavoritesScreen({this.favorites});

  @override
  _MyFavoritesScreenState createState() => _MyFavoritesScreenState();
}

class _MyFavoritesScreenState extends State<MyFavoritesScreen> {
  final ApiService apiService = ApiService();
  late Future<List<String>> favoritesFuture;
  final bool useRealApi = false;

  @override
  void initState() {
    super.initState();
    if (widget.favorites == null) {
      favoritesFuture = useRealApi ? apiService.fetchFavoritesFromApi() : apiService.fetchFavorites();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Favourites'),
        backgroundColor: Colors.green,
      ),
      body: widget.favorites != null
          ? _buildFavoritesList(widget.favorites!)
          : FutureBuilder<List<String>>(
              future: favoritesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (snapshot.hasData) {
                  return _buildFavoritesList(snapshot.data!);
                }
                return Center(child: Text('No favorites found'));
              },
            ),
    );
  }

  Widget _buildFavoritesList(List<String> favorites) {
    return favorites.isEmpty
        ? Center(child: Text('No favorites found'))
        : ListView.builder(
            padding: EdgeInsets.all(16.0),
            itemCount: favorites.length,
            itemBuilder: (context, index) {
              return Card(
                elevation: 2,
                margin: EdgeInsets.symmetric(vertical: 8.0),
                child: ListTile(
                  title: Text(favorites[index]),
                ),
              );
            },
          );
  }
}
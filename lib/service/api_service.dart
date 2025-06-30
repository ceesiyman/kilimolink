import 'dart:io';
import 'package:flutter/foundation.dart' hide Category;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../model/weather_model.dart';
import '../model/crop_price_model.dart';
import '../model/market_product_model.dart';
import '../model/expert_model.dart';
import '../model/success_story_model.dart';
import '../model/discussion_message_model.dart';
import '../model/community_message_model.dart' as community;
import '../model/tip_model.dart';
import '../model/user_model.dart';
import '../model/auth_model.dart';
import '../model/product_model.dart' as product_model;
import 'package:geolocator/geolocator.dart';
import 'auth_storage_service.dart';
import '../model/order_model.dart';
import '../model/consultation_model.dart';
import '../model/tip_category_model.dart';
import 'package:dio/dio.dart';

class ApiService {
  final String baseUrl = dotenv.env['BASE_URL'] ?? 'https://api.farmapp.com';
  final String weatherApiKey = dotenv.env['OPENWEATHERMAP_API_KEY'] ?? '';
  final AuthStorageService _authStorage = AuthStorageService();
  final Dio _dio = Dio(BaseOptions(baseUrl: dotenv.env['BASE_URL'] ?? 'https://api.farmapp.com'));

  // Check and request location permissions
  Future<bool> _checkAndRequestLocationPermissions() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled.');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied.');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied.');
      }

      return true;
    } catch (e) {
      print('Error checking/requesting location permissions: $e');
      rethrow;
    }
  }

  // Get the user's current location
  Future<Position> _getCurrentLocation() async {
    try {
      await _checkAndRequestLocationPermissions();
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      print('Error getting current location: $e');
      rethrow;
    }
  }

  // Fetch real weather data using OpenWeatherMap API
  Future<Weather> fetchRealWeather() async {
    try {
      // Get the user's location
      final position = await _getCurrentLocation();
      final lat = position.latitude;
      final lon = position.longitude;

      // Fetch weather data from OpenWeatherMap
      final response = await http.get(
        Uri.parse(
            'https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&appid=$weatherApiKey&units=metric'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Weather(
          location: data['name'], // City name from OpenWeatherMap
          temperature: data['main']['temp'].toDouble(),
          condition: data['weather'][0]['main'], // e.g., "Sunny", "Clouds", "Rain"
        );
      } else {
        throw Exception('Failed to load real weather: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching real weather: $e');
      // Fallback to mock data if real weather fetch fails
      return fetchWeather();
    }
  }

  Future<Weather> fetchWeather() async {
    await Future.delayed(Duration(seconds: 1));
    return Weather(
      location: 'Kilimanjaro, Tanzania',
      temperature: 30.0,
      condition: 'Sunny',
    );
  }

  Future<List<CropPrice>> fetchCropPrices() async {
    await Future.delayed(Duration(seconds: 1));
    return [
      CropPrice(
        name: 'Maize',
        pricePerKg: 1500,
        imageUrl: 'https://media.istockphoto.com/id/841408966/photo/corn-on-the-cob-kernels-peeled-isolated-on-white-background.jpg?s=612x612&w=0&k=20&c=v76mGkmlRYhLo98AMVQbpCpYwDc-1OGv7pI96aHc8zA=',
      ),
      CropPrice(
        name: 'Rice',
        pricePerKg: 2600,
        imageUrl: 'https://cdn.britannica.com/17/176517-050-6F2B774A/Pile-uncooked-rice-grains-Oryza-sativa.jpg',
      ),
      CropPrice(
        name: 'Cassava',
        pricePerKg: 5600,
        imageUrl: 'https://cdn.britannica.com/68/140368-050-C1B8D613/tubers.jpg',
      ),
      CropPrice(
        name: 'Tomatoes',
        pricePerKg: 1700,
        imageUrl: 'https://encrypted-tbn0.gstatic.com/images?q=tbngi9GcTN9-OuOtsl4iecwrOQ4c00iOqngoUdBz1dzQ&s',
      ),
      CropPrice(
        name: 'Beans',
        pricePerKg: 3200,
        imageUrl: 'https://www.heynutritionlady.com/wp-content/uploads/2023/05/How_to_Cook_Kidney_Beans-SQ.jpg',
      ),
      CropPrice(
        name: 'Potatoes',
        pricePerKg: 2100,
        imageUrl: 'https://www.lovefoodhatewaste.com/sites/default/files/styles/twitter_card_image/public/2022-08/Potatoes-shutterstock-1721688538.jpg.webp?itok=4hLqSjDi',
      ),
      CropPrice(
        name: 'Bananas',
        pricePerKg: 1800,
        imageUrl: 'https://thumbs.dreamstime.com/b/bunch-bananas-6175887.jpg',
      ),
    ];
  }

  Future<List<MarketProduct>> fetchMarketProducts() async {
    await Future.delayed(Duration(seconds: 1));
    return [
      MarketProduct(
        name: 'Banana',
        pricePerKg: 2950,
        imageUrl: 'https://thumbs.dreamstime.com/b/bunch-bananas-6175887.jpg',
        category: 'Fruits',
      ),
      MarketProduct(
        name: 'Tomato',
        pricePerKg: 1700,
        imageUrl: 'https://encrypted-tbn0.gstatic.com/images?q=tbngi9GcTN9-OuOtsl4iecwrOQ4c00iOqngoUdBz1dzQ&s',
        category: 'Vegetables',
      ),
      MarketProduct(
        name: 'Rice',
        pricePerKg: 2600,
        imageUrl: 'https://cdn.britannica.com/17/176517-050-6F2B774A/Pile-uncooked-rice-grains-Oryza-sativa.jpg',
        category: 'Grain',
      ),
      MarketProduct(
        name: 'Potato',
        pricePerKg: 2100,
        imageUrl: 'https://www.lovefoodhatewaste.com/sites/default/files/styles/twitter_card_image/public/2022-08/Potatoes-shutterstock-1721688538.jpg.webp?itok=4hLqSjDi',
        category: 'Tubers',
      ),
      MarketProduct(
        name: 'Mango',
        pricePerKg: 3500,
        imageUrl: 'https://encrypted-tbn0.gstatic.com/images?q=tbngi9GcQYv6hIwvS4A6vaKCvXU4pEH5km4_Myqh3soQ&s',
        category: 'Fruits',
      ),
      MarketProduct(
        name: 'Onion',
        pricePerKg: 1800,
        imageUrl: 'https://media.istockphoto.com/id/499146870/photo/red-onions.jpg?s=612x612&w=0&k=20&c=OaZUynAtxIJyPaSgAsAGWwAbpTs_EfKF5zT_UvBDpbY=',
        category: 'Vegetables',
      ),
    ];
  }

  Future<List<MarketProduct>> searchMarketProducts(String query) async {
    final allProducts = await fetchMarketProducts();
    if (query.isEmpty) {
      return allProducts;
    }
    return allProducts
        .where((product) =>
            product.name.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  Future<List<DiscussionMessage>> fetchDiscussionMessages() async {
    await Future.delayed(Duration(seconds: 1));
    return [
      DiscussionMessage(
        userName: 'Amina',
        content: 'Has anyone tried organic pest control methods? I need advice!',
      ),
      DiscussionMessage(
        userName: 'Joel',
        content: 'Yes Ive used neem oil with great success. What pests are you dealing with?',
      ),
      DiscussionMessage(
        userName: 'Amina',
        content: 'Voice message',
        isVoiceMessage: true,
      ),
      DiscussionMessage(
        userName: 'Joel',
        content: 'That sounds like aphids. Try a garlic spray as well.',
      ),
    ];
  }

  Future<List<Tip>> fetchTips() async {
    await Future.delayed(Duration(seconds: 1));
    return [
      Tip(
        id: 1,
        userId: 1,
        categoryId: 1,
        title: 'Use mulch to retain soil moisture',
        slug: 'use-mulch-to-retain-soil-moisture',
        content: 'Use mulch to retain soil moisture during dry seasons.',
        isFeatured: true,
        viewsCount: 100,
        likesCount: 50,
        tags: ['soil', 'moisture', 'mulch'],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        likedByCount: 50,
        savedByCount: 30,
        category: TipCategory(
          id: 1,
          name: 'Soil Management',
          slug: 'soil-management',
          description: 'Tips for managing soil health',
          icon: 'soil',
          tipsCount: 10,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        user: User(
          name: 'Joel',
          username: '@joel',
          email: 'joel@example.com',
          imageUrl: 'https://example.com/joel.jpg',
          favorites: [],
          location: 'Kilimanjaro',
          savedTips: [],
          role: 'expert',
        ),
      ),
      Tip(
        id: 2,
        userId: 2,
        categoryId: 2,
        title: 'Plant marigolds for pest control',
        slug: 'plant-marigolds-for-pest-control',
        content: 'Plant marigolds near your crops to deter pests naturally.',
        isFeatured: false,
        viewsCount: 80,
        likesCount: 40,
        tags: ['pests', 'flowers', 'natural'],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        likedByCount: 40,
        savedByCount: 20,
        category: TipCategory(
          id: 2,
          name: 'Pest Control',
          slug: 'pest-control',
          description: 'Natural pest control methods',
          icon: 'pest',
          tipsCount: 8,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        user: User(
          name: 'Amina',
          username: '@amina',
          email: 'amina@example.com',
          imageUrl: 'https://example.com/amina.jpg',
          favorites: [],
          location: 'Arusha',
          savedTips: [],
          role: 'expert',
        ),
      ),
    ];
  }

  Future<bool> sendDiscussionMessage(String userName, String content, bool isVoiceMessage) async {
    await Future.delayed(Duration(seconds: 1));
    print('Mock API: Discussion message sent by $userName - $content (Voice: $isVoiceMessage)');
    return true;
  }

  Future<String> uploadUserImage(File image) async {
    await Future.delayed(Duration(seconds: 1));
    print('Mock API: Image uploaded - ${image.path}');
    return 'https://t3.ftcdn.net/jpg/04/32/15/18/360_F_432151892_oQ3YQDo2LYZPILlEMnlo55PjjgiUwnQb.jpg';
  }

  Future<String> uploadUserImageFromApi(File image) async {
    try {
      final headers = await _getAuthHeaders();
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/user/image'));
      
      // Add auth header to multipart request
      request.headers.addAll({
        'Authorization': headers['Authorization'] ?? '',
      });
      
      request.files.add(await http.MultipartFile.fromPath('image', image.path));
      
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['image_url'] ?? '';
      } else if (response.statusCode == 422) {
        final data = jsonDecode(response.body);
        throw Exception(data['errors']?.values?.first?.first ?? 'Validation failed');
      } else {
        throw Exception('Failed to upload image: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error uploading image: $e');
    }
  }

  Future<User> fetchUser() async {
    await Future.delayed(Duration(seconds: 1));
    return User(
      name: 'Yusuph Paul',
      username: '@yusuphpaul',
      email: 'yusuph.paul@example.com',
      imageUrl: 'https://t3.ftcdn.net/jpg/04/32/15/18/360_F_432151892_oQ3YQDo2LYZPILlEMnlo55PjjgiUwnQb.jpg',
      favorites: ['Maize', 'Tomatoes', 'Bananas'],
      location: 'Kilimanjaro, Tanzania',
      savedTips: [
        'Use mulch to retain soil moisture during dry seasons.',
        'Plant marigolds near your crops to deter pests naturally.',
      ],
      role: 'Farmer',
    );
  }

  Future<Auth> login(String username, String password) async {
    await Future.delayed(Duration(seconds: 1));
    if (username.isNotEmpty && password.isNotEmpty) {
      return Auth(
        token: 'mock_token_${username}',
        userId: 'mock_user_id_${username}',
      );
      } else {
      throw Exception('Invalid username or password');
    }
  }

  Future<Auth> loginFromApi(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['token'];
        final userId = data['user']['id'].toString();
        final role = data['user']['role'] ?? 'farmer';

        // Store auth data
        await _authStorage.saveAuthData(
          token: token,
          userId: userId,
          role: role,
        );

        return Auth(
          token: token,
          userId: userId,
        );
      } else if (response.statusCode == 401) {
        throw Exception('Invalid credentials');
      } else if (response.statusCode == 422) {
        final data = jsonDecode(response.body);
        throw Exception(data['errors']?.values?.first?.first ?? 'Validation failed');
      } else {
        throw Exception('Failed to login: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error logging in: $e');
    }
  }

  Future<bool> logout() async {
    await Future.delayed(Duration(seconds: 1));
    print('Mock API: User logged out');
    return true;
  }

  Future<bool> logoutFromApi() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/logout'),
        headers: headers,
      );
      
      // Clear local auth data regardless of API response
      await _authStorage.clearAuthData();
      
      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception('Failed to logout: ${response.statusCode}');
      }
    } catch (e) {
      // Still clear local auth data even if API call fails
      await _authStorage.clearAuthData();
      throw Exception('Error logging out: $e');
    }
  }

  Future<bool> signup(String fullName, String phoneNumber, String email, String password) async {
    await Future.delayed(Duration(seconds: 1));
    if (fullName.isNotEmpty && phoneNumber.isNotEmpty && email.isNotEmpty && password.isNotEmpty) {
      print('Mock API: User signed up - Name: $fullName, Phone: $phoneNumber, Email: $email');
      return true;
    } else {
      throw Exception('All fields are required');
    }
  }

  Future<bool> signupFromApi(String name, String phoneNumber, String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'phone_number': phoneNumber,
          'email': email,
          'password': password,
          'role': 'farmer', // Default role for new users
        }),
      );

      if (response.statusCode == 201) {
        return true;
      } else if (response.statusCode == 422) {
        final data = jsonDecode(response.body);
        throw Exception(data['errors']?.values?.first?.first ?? 'Validation failed');
      } else {
        throw Exception('Failed to signup: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error signing up: $e');
    }
  }

  Future<bool> resetPassword(String email) async {
    await Future.delayed(Duration(seconds: 1));
    print('Mock API: Password reset requested for $email');
    return true;
  }

  Future<bool> resetPasswordFromApi(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );
      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception('Failed to request password reset: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error requesting password reset: $e');
    }
  }

  // New methods for related screens
  Future<List<String>> fetchFavorites() async {
    await Future.delayed(Duration(seconds: 1));
    return ['Maize', 'Tomatoes', 'Bananas', 'Rice'];
  }

  Future<List<String>> fetchFavoritesFromApi() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/user/favorites'));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<String>();
      } else {
        throw Exception('Failed to load favorites: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching favorites: $e');
    }
  }

  Future<String> fetchLocation() async {
    await Future.delayed(Duration(seconds: 1));
    return 'Kilimanjaro, Tanzania';
  }

  Future<String> fetchLocationFromApi() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/user/location'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['location'] as String;
      } else {
        throw Exception('Failed to load location: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching location: $e');
    }
  }

  Future<List<String>> fetchSavedTips() async {
    await Future.delayed(Duration(seconds: 1));
    return [
      'Use mulch to retain soil moisture during dry seasons.',
      'Plant marigolds near your crops to deter pests naturally.',
      'Compost kitchen scraps to create nutrient-rich fertilizer.',
      'Test soil pH regularly to ensure optimal nutrient availability.',
    ];
  }

  Future<Map<String, dynamic>> fetchSavedTipsFromApi() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/tips/saved'),
        headers: await _getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final tipsData = data['tips'];
        
        if (tipsData == null) {
          return {
            'tips': {
              'data': [],
              'current_page': 1,
              'last_page': 1,
              'per_page': 10,
              'total': 0,
            }
          };
        }
        
        return {
          'tips': tipsData,
        };
      } else {
        throw Exception('Failed to load saved tips: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to load saved tips: $e');
    }
  }

  Future<String> fetchRole() async {
    await Future.delayed(Duration(seconds: 1));
    return 'Farmer';
  }

  Future<String> fetchRoleFromApi() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/user/role'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['role'] as String;
      } else {
        throw Exception('Failed to load role: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching role: $e');
    }
  }

  Future<Weather> fetchWeatherFromApi() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/weather/kilimanjaro'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Weather.fromJson(data);
      } else {
        throw Exception('Failed to load weather: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching weather: $e');
    }
  }

  Future<List<CropPrice>> fetchCropPricesFromApi() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/crop-prices'));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => CropPrice.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load crop prices: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching crop prices: $e');
    }
  }

  Future<List<MarketProduct>> fetchMarketProductsFromApi() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/market-products'));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => MarketProduct.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load market products: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching market products: $e');
    }
  }

  Future<List<MarketProduct>> searchMarketProductsFromApi(String query) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/market-products/search?query=$query'),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => MarketProduct.fromJson(json)).toList();
      } else {
        throw Exception('Failed to search market products: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error searching market products: $e');
    }
  }

  Future<List<Expert>> fetchExpertsFromApi() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/experts'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> expertsJson = data['experts'];
        return expertsJson.map((json) => Expert.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load experts: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching experts: $e');
    }
  }

  Future<bool> submitQuestion(String question) async {
    await Future.delayed(Duration(seconds: 1));
    print('Mock API: Question submitted - $question');
    return true;
  }

  Future<bool> submitQuestionFromApi(String question) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/experts/questions'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'question': question}),
      );
      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception('Failed to submit question: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error submitting question: $e');
    }
  }

  Future<bool> bookConsultation(String expertName, String date, String time) async {
    await Future.delayed(Duration(seconds: 1));
    print('Mock API: Consultation booked with $expertName on $date at $time');
    return true;
  }

 

  Future<List<DiscussionMessage>> fetchDiscussionMessagesFromApi() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/community/discussion-messages'));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => DiscussionMessage.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load discussion messages: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching discussion messages: $e');
    }
  }

  Future<List<Tip>> fetchTipsListFromApi() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/community/tips'));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Tip.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load tips: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching tips: $e');
    }
  }

  Future<bool> sendDiscussionMessageFromApi(String userName, String content, bool isVoiceMessage) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/community/discussion-messages'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userName': userName,
          'content': content,
          'isVoiceMessage': isVoiceMessage,
        }),
      );
      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception('Failed to send discussion message: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error sending discussion message: $e');
    }
  }

  // Community Messages API Methods
  Future<Map<String, dynamic>> fetchCommunityMessagesFromApi({
    int? page,
    String? search,
    String? category,
    bool? pinned,
    bool? announcement,
    String? lastUpdated,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (page != null) queryParams['page'] = page.toString();
      if (search != null) queryParams['search'] = search;
      if (category != null) queryParams['category'] = category;
      if (pinned != null) queryParams['pinned'] = pinned.toString();
      if (announcement != null) queryParams['announcement'] = announcement.toString();
      if (lastUpdated != null) queryParams['last_updated'] = lastUpdated;

      final uri = Uri.parse('$baseUrl/community/messages').replace(queryParameters: queryParams);
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final imageBaseUrl = dotenv.env['IMAGE_BASE_URL'] ?? '';
        
        // Process messages to add image base URL
        final messages = (data['data']['data'] as List).map((json) {
          if (json['user']['image_url'] != null && json['user']['image_url'].toString().isNotEmpty) {
            json['user']['image_url'] = imageBaseUrl + json['user']['image_url'];
          }
          return community.CommunityMessage.fromJson(json);
        }).toList();

        return {
          'messages': messages,
          'pagination': data['data']['pagination'],
          'server_time': data['server_time'],
          'polling_interval': data['polling_interval'],
        };
      } else {
        throw Exception('Failed to load community messages: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching community messages: $e');
    }
  }

  Future<Map<String, dynamic>> pollCommunityMessagesFromApi({
    int? lastId,
    String? lastUpdated,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (lastId != null) queryParams['last_id'] = lastId.toString();
      if (lastUpdated != null) queryParams['last_updated'] = lastUpdated;

      final uri = Uri.parse('$baseUrl/community/messages/poll').replace(queryParameters: queryParams);
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final imageBaseUrl = dotenv.env['IMAGE_BASE_URL'] ?? '';
        
        // Process messages to add image base URL
        final messages = (data['data'] as List).map((json) {
          if (json['user']['image_url'] != null && json['user']['image_url'].toString().isNotEmpty) {
            json['user']['image_url'] = imageBaseUrl + json['user']['image_url'];
          }
          return community.CommunityMessage.fromJson(json);
        }).toList();

        return {
          'messages': messages,
          'last_id': data['last_id'],
          'server_time': data['server_time'],
          'has_new_messages': data['has_new_messages'],
          'polling_interval': data['polling_interval'],
        };
      } else {
        throw Exception('Failed to poll community messages: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error polling community messages: $e');
    }
  }

  Future<community.CommunityMessage> fetchCommunityMessageFromApi(int messageId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/community/messages/$messageId'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final imageBaseUrl = dotenv.env['IMAGE_BASE_URL'] ?? '';
        
        // Process message to add image base URL
        final messageJson = data['data'];
        if (messageJson['user']['image_url'] != null && messageJson['user']['image_url'].toString().isNotEmpty) {
          messageJson['user']['image_url'] = imageBaseUrl + messageJson['user']['image_url'];
        }
        
        // Process replies and nested replies
        if (messageJson['replies'] != null) {
          for (var reply in messageJson['replies']) {
            if (reply['user']['image_url'] != null && reply['user']['image_url'].toString().isNotEmpty) {
              reply['user']['image_url'] = imageBaseUrl + reply['user']['image_url'];
            }
            if (reply['replies'] != null) {
              for (var nestedReply in reply['replies']) {
                if (nestedReply['user']['image_url'] != null && nestedReply['user']['image_url'].toString().isNotEmpty) {
                  nestedReply['user']['image_url'] = imageBaseUrl + nestedReply['user']['image_url'];
                }
              }
            }
          }
        }

        return community.CommunityMessage.fromJson(messageJson);
      } else {
        throw Exception('Failed to load community message: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching community message: $e');
    }
  }

  Future<Map<String, dynamic>> createCommunityMessageFromApi({
    String? title,
    required String content,
    String? category,
    List<String>? tags,
    bool isPinned = false,
    bool isAnnouncement = false,
    List<File>? attachments,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      headers.remove('Content-Type'); // Remove for multipart request

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/community/messages'),
      );

      // Add headers
      request.headers.addAll(headers);

      // Add text fields
      request.fields['content'] = content;
      if (title != null) request.fields['title'] = title;
      if (category != null) request.fields['category'] = category;
      if (tags != null) request.fields['tags'] = tags.join(',');
      request.fields['is_pinned'] = isPinned.toString();
      request.fields['is_announcement'] = isAnnouncement.toString();

      // Add attachments
      if (attachments != null) {
        for (int i = 0; i < attachments.length; i++) {
          final file = attachments[i];
          final stream = http.ByteStream(file.openRead());
          final length = await file.length();
          final multipartFile = http.MultipartFile(
            'attachments[]',
            stream,
            length,
            filename: file.path.split('/').last,
          );
          request.files.add(multipartFile);
        }
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final imageBaseUrl = dotenv.env['IMAGE_BASE_URL'] ?? '';
        
        // Process message to add image base URL
        final messageJson = data['data'];
        if (messageJson['user']['image_url'] != null && messageJson['user']['image_url'].toString().isNotEmpty) {
          messageJson['user']['image_url'] = imageBaseUrl + messageJson['user']['image_url'];
        }

        return {
          'message': data['message'],
          'data': community.CommunityMessage.fromJson(messageJson),
        };
      } else if (response.statusCode == 422) {
        final data = jsonDecode(response.body);
        throw Exception(data['errors']?.values?.first?.first ?? 'Validation failed');
      } else {
        throw Exception('Failed to create community message: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error creating community message: $e');
    }
  }

  Future<Map<String, dynamic>> updateCommunityMessageFromApi({
    required int messageId,
    String? title,
    required String content,
    String? category,
    List<String>? tags,
    bool? isPinned,
    bool? isAnnouncement,
    List<File>? attachments,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      headers.remove('Content-Type'); // Remove for multipart request

      final request = http.MultipartRequest(
        'PUT',
        Uri.parse('$baseUrl/community/messages/$messageId'),
      );

      // Add headers
      request.headers.addAll(headers);

      // Add text fields
      request.fields['content'] = content;
      if (title != null) request.fields['title'] = title;
      if (category != null) request.fields['category'] = category;
      if (tags != null) request.fields['tags'] = tags.join(',');
      if (isPinned != null) request.fields['is_pinned'] = isPinned.toString();
      if (isAnnouncement != null) request.fields['is_announcement'] = isAnnouncement.toString();

      // Add attachments
      if (attachments != null) {
        for (int i = 0; i < attachments.length; i++) {
          final file = attachments[i];
          final stream = http.ByteStream(file.openRead());
          final length = await file.length();
          final multipartFile = http.MultipartFile(
            'attachments[]',
            stream,
            length,
            filename: file.path.split('/').last,
          );
          request.files.add(multipartFile);
        }
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final imageBaseUrl = dotenv.env['IMAGE_BASE_URL'] ?? '';
        
        // Process message to add image base URL
        final messageJson = data['data'];
        if (messageJson['user']['image_url'] != null && messageJson['user']['image_url'].toString().isNotEmpty) {
          messageJson['user']['image_url'] = imageBaseUrl + messageJson['user']['image_url'];
        }

        return {
          'message': data['message'],
          'data': community.CommunityMessage.fromJson(messageJson),
        };
      } else if (response.statusCode == 403) {
        throw Exception('You are not authorized to edit this message');
      } else if (response.statusCode == 422) {
        final data = jsonDecode(response.body);
        throw Exception(data['errors']?.values?.first?.first ?? 'Validation failed');
      } else {
        throw Exception('Failed to update community message: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating community message: $e');
    }
  }

  Future<Map<String, dynamic>> deleteCommunityMessageFromApi(int messageId) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/community/messages/$messageId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'message': data['message'],
        };
      } else if (response.statusCode == 403) {
        throw Exception('You are not authorized to delete this message');
      } else {
        throw Exception('Failed to delete community message: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error deleting community message: $e');
    }
  }

  Future<Map<String, dynamic>> toggleCommunityMessageLikeFromApi(int messageId) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/community/messages/$messageId/like'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'message': data['message'],
          'is_liked': data['data']['is_liked'],
          'likes_count': data['data']['likes_count'],
        };
      } else {
        throw Exception('Failed to toggle like: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error toggling like: $e');
    }
  }

  Future<Map<String, dynamic>> fetchMessageRepliesFromApi(int messageId, {int? page}) async {
    try {
      final queryParams = <String, String>{};
      if (page != null) queryParams['page'] = page.toString();

      final uri = Uri.parse('$baseUrl/community/messages/$messageId/replies').replace(queryParameters: queryParams);
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final imageBaseUrl = dotenv.env['IMAGE_BASE_URL'] ?? '';
        
        // Process replies to add image base URL
        final replies = (data['data']['data'] as List).map((json) {
          if (json['user']['image_url'] != null && json['user']['image_url'].toString().isNotEmpty) {
            json['user']['image_url'] = imageBaseUrl + json['user']['image_url'];
          }
          if (json['replies'] != null) {
            for (var reply in json['replies']) {
              if (reply['user']['image_url'] != null && reply['user']['image_url'].toString().isNotEmpty) {
                reply['user']['image_url'] = imageBaseUrl + reply['user']['image_url'];
              }
            }
          }
          return community.MessageReply.fromJson(json);
        }).toList();

        return {
          'replies': replies,
          'pagination': data['data']['pagination'],
        };
      } else {
        throw Exception('Failed to load replies: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching replies: $e');
    }
  }

  Future<Map<String, dynamic>> createMessageReplyFromApi({
    required int messageId,
    required String content,
    int? parentReplyId,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/community/messages/$messageId/replies'),
        headers: headers,
        body: jsonEncode({
          'content': content,
          if (parentReplyId != null) 'parent_reply_id': parentReplyId,
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final imageBaseUrl = dotenv.env['IMAGE_BASE_URL'] ?? '';
        
        // Process reply to add image base URL
        final replyJson = data['data'];
        if (replyJson['user']['image_url'] != null && replyJson['user']['image_url'].toString().isNotEmpty) {
          replyJson['user']['image_url'] = imageBaseUrl + replyJson['user']['image_url'];
        }

        return {
          'message': data['message'],
          'data': community.MessageReply.fromJson(replyJson),
        };
      } else if (response.statusCode == 422) {
        final data = jsonDecode(response.body);
        throw Exception(data['errors']?.values?.first?.first ?? 'Validation failed');
      } else {
        throw Exception('Failed to create reply: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error creating reply: $e');
    }
  }

  Future<Map<String, dynamic>> updateMessageReplyFromApi({
    required int messageId,
    required int replyId,
    required String content,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl/community/messages/$messageId/replies/$replyId'),
        headers: headers,
        body: jsonEncode({
          'content': content,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final imageBaseUrl = dotenv.env['IMAGE_BASE_URL'] ?? '';
        
        // Process reply to add image base URL
        final replyJson = data['data'];
        if (replyJson['user']['image_url'] != null && replyJson['user']['image_url'].toString().isNotEmpty) {
          replyJson['user']['image_url'] = imageBaseUrl + replyJson['user']['image_url'];
        }

        return {
          'message': data['message'],
          'data': community.MessageReply.fromJson(replyJson),
        };
      } else if (response.statusCode == 403) {
        throw Exception('You are not authorized to edit this reply');
      } else if (response.statusCode == 422) {
        final data = jsonDecode(response.body);
        throw Exception(data['errors']?.values?.first?.first ?? 'Validation failed');
      } else {
        throw Exception('Failed to update reply: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating reply: $e');
    }
  }

  Future<Map<String, dynamic>> deleteMessageReplyFromApi(int messageId, int replyId) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/community/messages/$messageId/replies/$replyId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'message': data['message'],
        };
      } else if (response.statusCode == 403) {
        throw Exception('You are not authorized to delete this reply');
      } else {
        throw Exception('Failed to delete reply: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error deleting reply: $e');
    }
  }

  Future<Map<String, dynamic>> toggleMessageReplyLikeFromApi(int messageId, int replyId) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/community/messages/$messageId/replies/$replyId/like'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'message': data['message'],
          'is_liked': data['data']['is_liked'],
          'likes_count': data['data']['likes_count'],
        };
      } else {
        throw Exception('Failed to toggle reply like: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error toggling reply like: $e');
    }
  }

  // Helper method to get auth headers
  Future<Map<String, String>> _getAuthHeaders() async {
    final token = await _authStorage.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<User> fetchUserFromApi() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/user/profile'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final userJson = data['user'];
        // Get image base URL from .env
        final imageBaseUrl = dotenv.env['IMAGE_BASE_URL'] ?? '';
        // Prepend base URL to image_url if present and not already a full URL
        if (userJson['image_url'] != null && userJson['image_url'] != '') {
          userJson['imageUrl'] = imageBaseUrl + userJson['image_url'];
        } else {
          userJson['imageUrl'] = '';
        }
        return User.fromJson(userJson);
      } else {
        throw Exception('Failed to load user profile: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching user profile: $e');
    }
  }

  Future<bool> updateUserProfileFromApi(String name, String username, String imageUrl, String location, String role) async {
    try {
      final headers = await _getAuthHeaders();
      final Map<String, dynamic> body = {};

      if (name.isNotEmpty) body['name'] = name;
      if (username.isNotEmpty) body['username'] = username;
      if (imageUrl.isNotEmpty) body['image_url'] = imageUrl;
      if (location.isNotEmpty) body['location'] = location;
      // Do NOT send 'role'

      final response = await http.patch(
        Uri.parse('$baseUrl/user'),
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        return true;
      } else if (response.statusCode == 422) {
        final data = jsonDecode(response.body);
        throw Exception(data['errors']?.values?.first?.first ?? 'Validation failed');
      } else {
        throw Exception('Failed to update profile: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating profile: $e');
    }
  }

  Future<List<product_model.Product>> fetchFeaturedProductsFromApi() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/products/featured'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> productsJson = data['products'];
        final imageBaseUrl = dotenv.env['IMAGE_BASE_URL'] ?? '';
        
        return productsJson.map((json) {
          // Prepend base URL to image path
          if (json['image'] != null && json['image'].toString().isNotEmpty) {
            json['image'] = imageBaseUrl + json['image'];
          }
          return product_model.Product.fromJson(json);
        }).toList();
      } else {
        throw Exception('Failed to load featured products: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching featured products: $e');
    }
  }

  Future<List<product_model.Category>> fetchCategoriesFromApi() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/categories'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> categoriesJson = data['categories'];
        return categoriesJson.map((json) => product_model.Category.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load categories: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching categories: $e');
    }
  }

  Future<List<product_model.Product>> fetchProductsFromApi({
    int? categoryId,
    double? minPrice,
    double? maxPrice,
    String? createdAfter,
    String? createdBefore,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (categoryId != null) queryParams['category_id'] = categoryId.toString();
      if (minPrice != null) queryParams['min_price'] = minPrice.toString();
      if (maxPrice != null) queryParams['max_price'] = maxPrice.toString();
      if (createdAfter != null) queryParams['created_after'] = createdAfter;
      if (createdBefore != null) queryParams['created_before'] = createdBefore;

      final uri = Uri.parse('$baseUrl/products').replace(queryParameters: queryParams);
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> productsJson = data['products'];
        final imageBaseUrl = dotenv.env['IMAGE_BASE_URL'] ?? '';
        
        return productsJson.map((json) {
          // Prepend base URL to image path
          if (json['image'] != null && json['image'].toString().isNotEmpty) {
            json['image'] = imageBaseUrl + json['image'];
          }
          return product_model.Product.fromJson(json);
        }).toList();
      } else {
        throw Exception('Failed to load products: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching products: $e');
    }
  }

  Future<Order> createOrderFromApi({
    required List<Map<String, dynamic>> items,
    required String shippingAddress,
    required String phoneNumber,
    String? notes,
  }) async {
    try {
      final token = await _authStorage.getToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/orders'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'items': items.map((item) => {
            'product_id': (item['product'] as product_model.Product).id,
            'quantity': item['quantity'],
          }).toList(),
          'shipping_address': shippingAddress,
          'phone_number': phoneNumber,
          if (notes != null) 'notes': notes,
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return Order.fromJson(data['order']);
      } else if (response.statusCode == 422) {
        final data = jsonDecode(response.body);
        throw Exception(data['message'] ?? 'Validation failed');
      } else {
        throw Exception('Failed to create order');
      }
    } catch (e) {
      throw Exception('Error creating order: $e');
    }
  }

  Future<List<Order>> fetchMyOrdersFromApi() async {
    try {
      final token = await _authStorage.getToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/orders/my-orders'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['orders'] as List)
            .map((order) => Order.fromJson(order))
            .toList();
      } else {
        throw Exception('Failed to fetch orders');
      }
    } catch (e) {
      throw Exception('Error fetching orders: $e');
    }
  }

  Future<Order> fetchOrderDetailsFromApi(int orderId) async {
    try {
      final token = await _authStorage.getToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/orders/$orderId'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Order.fromJson(data['order']);
      } else if (response.statusCode == 404) {
        throw Exception('Order not found');
      } else if (response.statusCode == 403) {
        throw Exception('Unauthorized to view this order');
      } else {
        throw Exception('Failed to fetch order details');
      }
    } catch (e) {
      throw Exception('Error fetching order details: $e');
    }
  }

  Future<Consultation> bookConsultationFromApi({
    required int expertId,
    required DateTime consultationDate,
    required String description,
  }) async {
    try {
      final token = await _authStorage.getToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/consultations'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'expert_id': expertId,
          'consultation_date': consultationDate.toIso8601String(),
          'description': description,
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return Consultation.fromJson(data['consultation']);
      } else if (response.statusCode == 422) {
        final data = jsonDecode(response.body);
        throw Exception(data['errors']?.values?.first?.first ?? 'Validation failed');
      } else {
        throw Exception('Failed to book consultation: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error booking consultation: $e');
    }
  }

  Future<List<Consultation>> fetchMyConsultationsFromApi() async {
    try {
      final token = await _authStorage.getToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/consultations/my-bookings'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Farmer consultations response status: ${response.statusCode}');
      print('Farmer consultations response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Farmer consultations data structure: $data');
        print('Consultations list type: ${data['consultations'].runtimeType}');
        print('Consultations list length: ${(data['consultations'] as List).length}');
        
        if ((data['consultations'] as List).isNotEmpty) {
          print('First consultation: ${(data['consultations'] as List).first}');
        }
        
        return (data['consultations'] as List)
            .map((consultation) => Consultation.fromJson(consultation))
            .toList();
      } else {
        throw Exception('Failed to fetch consultations: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in fetchMyConsultationsFromApi: $e');
      throw Exception('Error fetching consultations: $e');
    }
  }

  Future<List<Consultation>> fetchMyExpertConsultationsFromApi() async {
    try {
      final token = await _authStorage.getToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/consultations/my-expert-bookings'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Expert consultations response status: ${response.statusCode}');
      print('Expert consultations response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Expert consultations data structure: $data');
        print('Consultations list type: ${data['consultations'].runtimeType}');
        print('Consultations list length: ${(data['consultations'] as List).length}');
        
        if ((data['consultations'] as List).isNotEmpty) {
          print('First consultation: ${(data['consultations'] as List).first}');
        }
        
        return (data['consultations'] as List)
            .map((consultation) => Consultation.fromJson(consultation))
            .toList();
      } else {
        throw Exception('Failed to fetch expert consultations: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in fetchMyExpertConsultationsFromApi: $e');
      throw Exception('Error fetching expert consultations: $e');
    }
  }

  Future<Map<String, dynamic>> acceptConsultationFromApi(int consultationId, {String? expertNotes}) async {
    try {
      final token = await _authStorage.getToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.patch(
        Uri.parse('$baseUrl/consultations/$consultationId/accept'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          if (expertNotes != null && expertNotes.isNotEmpty) 'expert_notes': expertNotes,
        }),
      );

      print('Accept consultation response status: ${response.statusCode}');
      print('Accept consultation response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'message': data['message'] ?? 'Consultation accepted successfully',
          'consultation': data['consultation'],
        };
      } else if (response.statusCode == 403) {
        throw Exception('Unauthorized to accept this consultation');
      } else if (response.statusCode == 404) {
        throw Exception('Consultation not found');
      } else if (response.statusCode == 422) {
        final data = jsonDecode(response.body);
        throw Exception(data['message'] ?? 'Consultation is not in pending status');
      } else {
        throw Exception('Failed to accept consultation: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in acceptConsultationFromApi: $e');
      throw Exception('Error accepting consultation: $e');
    }
  }

  Future<Map<String, dynamic>> declineConsultationFromApi(int consultationId, String declineReason) async {
    try {
      final token = await _authStorage.getToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.patch(
        Uri.parse('$baseUrl/consultations/$consultationId/decline'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'decline_reason': declineReason,
        }),
      );

      print('Decline consultation response status: ${response.statusCode}');
      print('Decline consultation response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'message': data['message'] ?? 'Consultation declined successfully',
          'consultation': data['consultation'],
        };
      } else if (response.statusCode == 403) {
        throw Exception('Unauthorized to decline this consultation');
      } else if (response.statusCode == 404) {
        throw Exception('Consultation not found');
      } else if (response.statusCode == 422) {
        final data = jsonDecode(response.body);
        if (data['errors'] != null) {
          final errors = data['errors'] as Map<String, dynamic>;
          final errorMessage = errors.values.first?.first ?? 'Validation failed';
          throw Exception(errorMessage);
        } else {
          throw Exception(data['message'] ?? 'Consultation is not in pending status');
        }
      } else {
        throw Exception('Failed to decline consultation: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in declineConsultationFromApi: $e');
      throw Exception('Error declining consultation: $e');
    }
  }

  Future<Map<String, dynamic>> completeConsultationFromApi(int consultationId) async {
    try {
      final token = await _authStorage.getToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.patch(
        Uri.parse('$baseUrl/consultations/$consultationId/complete'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Complete consultation response status: ${response.statusCode}');
      print('Complete consultation response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'message': data['message'] ?? 'Consultation marked as completed',
          'consultation': data['consultation'],
        };
      } else if (response.statusCode == 403) {
        throw Exception('Unauthorized to complete this consultation');
      } else if (response.statusCode == 404) {
        throw Exception('Consultation not found');
      } else if (response.statusCode == 422) {
        final data = jsonDecode(response.body);
        throw Exception(data['message'] ?? 'Consultation must be accepted before completing');
      } else {
        throw Exception('Failed to complete consultation: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in completeConsultationFromApi: $e');
      throw Exception('Error completing consultation: $e');
    }
  }

  Future<Map<String, dynamic>> fetchTipCategoriesFromApi() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/tip-categories'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> categoriesJson = data['categories'];
        return {
          'categories': categoriesJson.map((json) => TipCategory.fromJson(json)).toList(),
          'totalCategories': data['total_categories'] ?? 0,
          'totalTips': data['total_tips'] ?? 0,
        };
      } else {
        throw Exception('Failed to load tip categories: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching tip categories: $e');
    }
  }

  Future<Map<String, dynamic>> fetchTipsFromApi({
    int? categoryId,
    String? search,
    bool? featured,
    String? sort,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (categoryId != null) queryParams['category'] = categoryId.toString();
      if (search != null) queryParams['search'] = search;
      if (featured != null) queryParams['featured'] = featured.toString();
      if (sort != null) queryParams['sort'] = sort;

      final uri = Uri.parse('$baseUrl/tips').replace(queryParameters: queryParams);
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final tipsData = data['tips'];
        return {
          'tips': (tipsData['data'] as List).map((json) => Tip.fromJson(json)).toList(),
          'currentPage': tipsData['current_page'] ?? 1,
          'lastPage': tipsData['last_page'] ?? 1,
          'perPage': tipsData['per_page'] ?? 10,
          'total': tipsData['total'] ?? 0,
        };
      } else {
        throw Exception('Failed to load tips: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching tips: $e');
    }
  }

  Future<Map<String, dynamic>> toggleTipLike(int tipId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/tips/$tipId/like'),
        headers: await _getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final message = data['message'] as String;
        return {
          'message': message,
          'likesCount': data['likes_count'] as int,
          'isLiked': message.contains('liked') && !message.contains('unliked'),
        };
      } else {
        throw Exception('Failed to toggle like: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to toggle like: $e');
    }
  }

  Future<Map<String, dynamic>> toggleTipSave(int tipId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/tips/$tipId/save'),
        headers: await _getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final message = data['message'] as String;
        return {
          'message': message,
          'isSaved': message.contains('saved') && !message.contains('unsaved'),
        };
      } else {
        throw Exception('Failed to toggle save: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to toggle save: $e');
    }
  }

  Future<Map<String, dynamic>> createProductFromApi({
    required String name,
    required String description,
    required double price,
    required int categoryId,
    required File image,
    int? stock,
    String? location,
    bool? isFeatured,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      // Remove Content-Type for multipart request
      headers.remove('Content-Type');
      
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/products'));
      
      // Add auth header
      request.headers.addAll({
        'Authorization': headers['Authorization'] ?? '',
      });
      
      // Add text fields
      request.fields['name'] = name;
      request.fields['description'] = description;
      request.fields['price'] = price.toString();
      request.fields['category_id'] = categoryId.toString();
      
      if (stock != null) {
        request.fields['stock'] = stock.toString();
      }
      if (location != null && location.isNotEmpty) {
        request.fields['location'] = location;
      }
      if (isFeatured != null) {
        request.fields['is_featured'] = isFeatured.toString();
      }
      
      // Add image file
      request.files.add(await http.MultipartFile.fromPath('image', image.path));
      
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {
          'message': data['message'] ?? 'Product created successfully',
          'product': data['product'],
        };
      } else if (response.statusCode == 422) {
        final data = jsonDecode(response.body);
        throw Exception(data['errors']?.values?.first?.first ?? 'Validation failed');
      } else {
        throw Exception('Failed to create product: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error creating product: $e');
    }
  }

  Future<Map<String, dynamic>> createTipFromApi({
    required String title,
    required String content,
    required int categoryId,
    List<String>? tags,
    bool? isFeatured,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/tips'),
        headers: headers,
        body: jsonEncode({
          'title': title,
          'content': content,
          'category_id': categoryId,
          if (tags != null && tags.isNotEmpty) 'tags': tags,
          if (isFeatured != null) 'is_featured': isFeatured,
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {
          'message': data['message'] ?? 'Tip created successfully',
          'tip': data['tip'],
        };
      } else if (response.statusCode == 403) {
        throw Exception('Only experts can create tips');
      } else if (response.statusCode == 422) {
        final data = jsonDecode(response.body);
        throw Exception(data['errors']?.values?.first?.first ?? 'Validation failed');
      } else {
        throw Exception('Failed to create tip: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error creating tip: $e');
    }
  }

  // ==================== SUCCESS STORIES API METHODS ====================

  /// Fetch success stories with filters
  Future<Map<String, dynamic>> fetchSuccessStoriesFromApi({
    String? search,
    String? cropType,
    bool? featured,
    String? sort,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (search != null) queryParams['search'] = search;
      if (cropType != null) queryParams['crop_type'] = cropType;
      if (featured != null) queryParams['featured'] = featured.toString();
      if (sort != null) queryParams['sort'] = sort;

      final uri = Uri.parse('$baseUrl/success-stories').replace(queryParameters: queryParams);
      print('Fetching success stories from: $uri');
      
      final response = await http.get(uri);
      print('Success stories response status: ${response.statusCode}');
      print('Success stories response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Success stories data structure: $data');
        
        final List<dynamic> storiesJson = data['stories']['data'];
        final imageBaseUrl = dotenv.env['IMAGE_BASE_URL'] ?? '';
        
        print('Found ${storiesJson.length} success stories');
        
        final stories = storiesJson.map((json) {
          try {
            // Prepend base URL to image paths
            if (json['images'] != null) {
              for (var image in json['images']) {
                if (image['image_path'] != null && image['image_path'].toString().isNotEmpty) {
                  image['image_path'] = imageBaseUrl + image['image_path'];
                }
              }
            }
            return SuccessStory.fromJson(json);
          } catch (e) {
            print('Error parsing success story JSON: $e');
            print('Problematic JSON: $json');
            rethrow;
          }
        }).toList();

        return {
          'stories': stories,
          'pagination': data['stories'],
        };
      } else {
        print('Failed to load success stories: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to load success stories: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching success stories: $e');
      throw Exception('Error fetching success stories: $e');
    }
  }

  /// Fetch a specific success story
  Future<SuccessStory> fetchSuccessStoryFromApi(int id) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/success-stories/$id'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final storyJson = data['story'];
        final imageBaseUrl = dotenv.env['IMAGE_BASE_URL'] ?? '';
        
        // Prepend base URL to image paths
        if (storyJson['images'] != null) {
          for (var image in storyJson['images']) {
            if (image['image_path'] != null && image['image_path'].toString().isNotEmpty) {
              image['image_path'] = imageBaseUrl + image['image_path'];
            }
          }
        }
        
        // Prepend base URL to user image paths
        if (storyJson['user']['image_url'] != null && storyJson['user']['image_url'].toString().isNotEmpty) {
          storyJson['user']['imageUrl'] = imageBaseUrl + storyJson['user']['image_url'];
        }
        
        // Prepend base URL to comment user image paths
        if (storyJson['comments'] != null) {
          for (var comment in storyJson['comments']) {
            if (comment['user']['image_url'] != null && comment['user']['image_url'].toString().isNotEmpty) {
              comment['user']['imageUrl'] = imageBaseUrl + comment['user']['image_url'];
            }
            // Handle replies
            if (comment['replies'] != null) {
              for (var reply in comment['replies']) {
                if (reply['user']['image_url'] != null && reply['user']['image_url'].toString().isNotEmpty) {
                  reply['user']['imageUrl'] = imageBaseUrl + reply['user']['image_url'];
                }
              }
            }
          }
        }
        
        return SuccessStory.fromJson(storyJson);
      } else if (response.statusCode == 404) {
        throw Exception('Success story not found');
      } else {
        throw Exception('Failed to load success story: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching success story: $e');
    }
  }

  /// Create a new success story
  Future<SuccessStory> createSuccessStoryFromApi({
    required String title,
    required String content,
    String? location,
    String? cropType,
    double? yieldImprovement,
    String? yieldUnit,
    List<Map<String, dynamic>>? images,
  }) async {
    try {
      print('Creating success story with title: $title');
      final headers = await _getAuthHeaders();
      
      // Remove Content-Type for multipart request
      headers.remove('Content-Type');
      
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/success-stories'),
      );
      
      // Add headers
      request.headers.addAll(headers);
      
      // Add text fields
      request.fields['title'] = title;
      request.fields['content'] = content;
      if (location != null) request.fields['location'] = location;
      if (cropType != null) request.fields['crop_type'] = cropType;
      if (yieldImprovement != null) request.fields['yield_improvement'] = yieldImprovement.toString();
      if (yieldUnit != null) request.fields['yield_unit'] = yieldUnit;
      
      print('Request fields: ${request.fields}');
      
      // Add images
      if (images != null) {
        print('Adding ${images.length} images to request');
        for (int i = 0; i < images.length; i++) {
          final imageData = images[i];
          if (imageData['file'] != null) {
            request.files.add(await http.MultipartFile.fromBytes(
              'images[]',
              imageData['file'],
              filename: imageData['filename'] ?? 'image_$i.jpg',
            ));
          }
          if (imageData['caption'] != null) {
            request.fields['captions[]'] = imageData['caption'];
          }
        }
      }
      
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('Create success story response status: ${response.statusCode}');
      print('Create success story response body: ${response.body}');

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final storyJson = data['story'];
        final imageBaseUrl = dotenv.env['IMAGE_BASE_URL'] ?? '';
        
        // Prepend base URL to image paths
        if (storyJson['images'] != null) {
          for (var image in storyJson['images']) {
            if (image['image_path'] != null && image['image_path'].toString().isNotEmpty) {
              image['image_path'] = imageBaseUrl + image['image_path'];
            }
          }
        }
        
        print('Success story created successfully');
        return SuccessStory.fromJson(storyJson);
      } else if (response.statusCode == 422) {
        final data = jsonDecode(response.body);
        print('Validation error: $data');
        throw Exception(data['errors']?.values?.first?.first ?? 'Validation failed');
      } else {
        print('Failed to create success story: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to create success story: ${response.statusCode}');
      }
    } catch (e) {
      print('Error creating success story: $e');
      throw Exception('Error creating success story: $e');
    }
  }

  /// Update a success story
  Future<SuccessStory> updateSuccessStoryFromApi({
    required int id,
    String? title,
    String? content,
    String? location,
    String? cropType,
    double? yieldImprovement,
    String? yieldUnit,
    List<Map<String, dynamic>>? images,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      
      // Remove Content-Type for multipart request
      headers.remove('Content-Type');
      
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/success-stories/$id'),
      );
      
      // Add headers
      request.headers.addAll(headers);
      
      // Add _method field for PUT request
      request.fields['_method'] = 'PUT';
      
      // Add text fields
      if (title != null) request.fields['title'] = title;
      if (content != null) request.fields['content'] = content;
      if (location != null) request.fields['location'] = location;
      if (cropType != null) request.fields['crop_type'] = cropType;
      if (yieldImprovement != null) request.fields['yield_improvement'] = yieldImprovement.toString();
      if (yieldUnit != null) request.fields['yield_unit'] = yieldUnit;
      
      // Add images
      if (images != null) {
        for (int i = 0; i < images.length; i++) {
          final imageData = images[i];
          if (imageData['file'] != null) {
            request.files.add(await http.MultipartFile.fromBytes(
              'images[]',
              imageData['file'],
              filename: imageData['filename'] ?? 'image_$i.jpg',
            ));
          }
          if (imageData['caption'] != null) {
            request.fields['captions[]'] = imageData['caption'];
          }
        }
      }
      
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final storyJson = data['story'];
        final imageBaseUrl = dotenv.env['IMAGE_BASE_URL'] ?? '';
        
        // Prepend base URL to image paths
        if (storyJson['images'] != null) {
          for (var image in storyJson['images']) {
            if (image['image_path'] != null && image['image_path'].toString().isNotEmpty) {
              image['image_path'] = imageBaseUrl + image['image_path'];
            }
          }
        }
        
        return SuccessStory.fromJson(storyJson);
      } else if (response.statusCode == 403) {
        throw Exception('Unauthorized to update this success story');
      } else if (response.statusCode == 404) {
        throw Exception('Success story not found');
      } else if (response.statusCode == 422) {
        final data = jsonDecode(response.body);
        throw Exception(data['errors']?.values?.first?.first ?? 'Validation failed');
      } else {
        throw Exception('Failed to update success story: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating success story: $e');
    }
  }

  /// Delete a success story
  Future<bool> deleteSuccessStoryFromApi(int id) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/success-stories/$id'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return true;
      } else if (response.statusCode == 403) {
        throw Exception('Unauthorized to delete this success story');
      } else if (response.statusCode == 404) {
        throw Exception('Success story not found');
      } else {
        throw Exception('Failed to delete success story: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error deleting success story: $e');
    }
  }

  /// Get user's success stories
  Future<Map<String, dynamic>> fetchMySuccessStoriesFromApi() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/success-stories/my-stories'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> storiesJson = data['stories']['data'];
        final imageBaseUrl = dotenv.env['IMAGE_BASE_URL'] ?? '';
        
        final stories = storiesJson.map((json) {
          // Prepend base URL to image paths
          if (json['images'] != null) {
            for (var image in json['images']) {
              if (image['image_path'] != null && image['image_path'].toString().isNotEmpty) {
                image['image_path'] = imageBaseUrl + image['image_path'];
              }
            }
          }
          return SuccessStory.fromJson(json);
        }).toList();

        return {
          'stories': stories,
          'pagination': data['stories'],
        };
      } else {
        throw Exception('Failed to load my success stories: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching my success stories: $e');
    }
  }

  /// Like or unlike a success story
  Future<Map<String, dynamic>> toggleSuccessStoryLikeFromApi(int id) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/success-stories/$id/like'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'message': data['message'],
          'likesCount': data['likes_count'],
        };
      } else if (response.statusCode == 404) {
        throw Exception('Success story not found');
      } else {
        throw Exception('Failed to toggle like: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error toggling like: $e');
    }
  }

  /// Get comments for a success story
  Future<Map<String, dynamic>> fetchSuccessStoryCommentsFromApi(int id) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/success-stories/$id/comments'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> commentsJson = data['comments']['data'];
        
        final comments = commentsJson.map((json) {
          return StoryComment.fromJson(json);
        }).toList();

        return {
          'comments': comments,
          'pagination': data['comments'],
        };
      } else if (response.statusCode == 404) {
        throw Exception('Success story not found');
      } else {
        throw Exception('Failed to load comments: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching comments: $e');
    }
  }

  /// Add a comment to a success story
  Future<StoryComment> addSuccessStoryCommentFromApi({
    required int storyId,
    required String comment,
    int? parentId,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/success-stories/$storyId/comments'),
        headers: headers,
        body: jsonEncode({
          'comment': comment,
          if (parentId != null) 'parent_id': parentId,
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return StoryComment.fromJson(data['comment']);
      } else if (response.statusCode == 404) {
        throw Exception('Success story not found');
      } else if (response.statusCode == 422) {
        final data = jsonDecode(response.body);
        throw Exception(data['errors']?.values?.first?.first ?? 'Validation failed');
      } else {
        throw Exception('Failed to add comment: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error adding comment: $e');
    }
  }

  /// Test image upload for success stories
  Future<Map<String, dynamic>> testSuccessStoryImageUploadFromApi(List<Map<String, dynamic>> images) async {
    try {
      final headers = await _getAuthHeaders();
      
      // Remove Content-Type for multipart request
      headers.remove('Content-Type');
      
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/success-stories/test-upload'),
      );
      
      // Add headers
      request.headers.addAll(headers);
      
      // Add images
      for (int i = 0; i < images.length; i++) {
        final imageData = images[i];
        if (imageData['file'] != null) {
          request.files.add(await http.MultipartFile.fromBytes(
            'images[]',
            imageData['file'],
            filename: imageData['filename'] ?? 'image_$i.jpg',
          ));
        }
      }
      
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to test upload: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error testing upload: $e');
    }
  }

  Future<Map<String, dynamic>> requestPasswordResetOTP(String email) async {
    try {
      final response = await _dio.post(
        '/password/request-reset',
        data: {
          'email': email,
        },
      );
      return response.data;
    } catch (e) {
      if (e is DioException) {
        if (e.response?.statusCode == 404) {
          throw 'User not found';
        } else if (e.response?.statusCode == 422) {
          final errors = e.response?.data['errors'];
          if (errors != null && errors['email'] != null) {
            throw errors['email'][0];
          }
        }
        throw 'Failed to send OTP: ${e.message ?? "Unknown error"}';
      }
      throw 'An error occurred while sending OTP';
    }
  }

  Future<Map<String, dynamic>> verifyAndResetPassword(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post(
        '/password/reset',
        data: data,
      );
      return response.data;
    } catch (e) {
      if (e is DioException) {
        if (e.response?.statusCode == 404) {
          throw 'User not found';
        } else if (e.response?.statusCode == 400) {
          throw 'Invalid or expired OTP';
        } else if (e.response?.statusCode == 422) {
          final errors = e.response?.data['errors'];
          if (errors != null) {
            if (errors['otp'] != null) {
              throw errors['otp'][0];
            } else if (errors['new_password'] != null) {
              throw errors['new_password'][0];
            }
          }
        }
        throw 'Failed to reset password: ${e.message ?? "Unknown error"}';
      }
      throw 'An error occurred while resetting password';
    }
  }
}
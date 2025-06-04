import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../model/weather_model.dart';
import '../model/crop_price_model.dart';
import '../model/market_product_model.dart';
import '../model/expert_model.dart';
import '../model/success_story_model.dart';
import '../model/discussion_message_model.dart';
import '../model/tip_model.dart';
import '../model/user_model.dart';
import '../model/auth_model.dart';
import 'package:geolocator/geolocator.dart';

class ApiService {
  final String baseUrl = dotenv.env['BASE_URL'] ?? 'https://api.farmapp.com';
  final String weatherApiKey = dotenv.env['OPENWEATHERMAP_API_KEY'] ?? '';

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

  Future<List<Expert>> fetchExperts() async {
    await Future.delayed(Duration(seconds: 1));
    return [
      Expert(
        name: 'Dr. Hassan',
        specialty: 'Soil & irrigation',
        imageUrl: 'https://encrypted-tbn0.gstatic.com/images?q=tbngi9GcQfu9dg1a4_gBzTvbgr9PpXcfOg21fza4eQ9Q&s',
        tips: [
          'Test soil pH regularly to ensure optimal nutrient availability.',
          'Use drip irrigation to conserve water and reduce runoff.',
          'Rotate crops to prevent soil depletion.',
        ],
      ),
      Expert(
        name: 'Dr. Kimario',
        specialty: 'Plant pathologist',
        imageUrl: 'https://encrypted-tbn0.gstatic.com/images?q=tbngi9GcQYUfzzk_t4C8F-NoPQJVW8aaQs3Y6m_5VP1g&s',
        tips: [
          'Inspect plants regularly for early signs of disease.',
          'Use resistant crop varieties to minimize disease risk.',
          'Ensure proper spacing between plants for air circulation.',
        ],
      ),
      Expert(
        name: 'Dr. Amina',
        specialty: 'Crop nutrition',
        imageUrl: 'https://thumbs.dreamstime.com/b/science-portrait-woman-plants-microscope-laboratory-research-agriculture-sustainability-leaves-test-scientist-african-287575186.jpg',
        tips: [
          'Apply organic compost to improve soil fertility.',
          'Monitor nitrogen levels to prevent over-fertilization.',
          'Use foliar feeding for quick nutrient uptake.',
        ],
      ),
    ];
  }

  Future<List<SuccessStory>> fetchSuccessStories() async {
    await Future.delayed(Duration(seconds: 1));
    return [
      SuccessStory(
        userName: 'Joel',
        content: 'After experimenting with organic fertilizers, my yields have tripled',
        imageUrls: [
          'https://media.istockphoto.com/id/684977254/photo/farmer-hand-giving-plant-organic-humus-fertilizer-to-plant.jpg?s=612x612&w=0&k=20&c=SjD1diUDXEBmXRF1My6lDdwV9BGpPTD1yWUCwz8235U=',
          'https://encrypted-tbn0.gstatic.com/images?q=tbngi9GcQPmqcMjTQDeNX-8lGQlWTbFJpDYg0g5U3tRA&s',
          'https://encrypted-tbn0.gstatic.com/images?q=tbngi9GcS7qKsEk_L1hwa6GjXVjrZiwMSzdA4_orqd4A&s',
        ],
      ),
      SuccessStory(
        userName: 'Amina',
        content: 'Switching to drip irrigation saved me 30% on water usage',
        imageUrls: [
          'https://encrypted-tbn0.gstatic.com/images?q=tbngi9GcSJzQEudhZw0uw-SwsXaTpVme8D1nubRBbi7g&s',
          'https://qph.cf2.quoracdn.net/main-qimg-f69435572d9f81f037473a860e4e5a2d-lq',
        ],
      ),
    ];
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
        content: 'Yes, I’ve used neem oil with great success. What pests are you dealing with?',
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
        userName: 'Joel',
        content: 'Use mulch to retain soil moisture during dry seasons.',
      ),
      Tip(
        userName: 'Amina',
        content: 'Plant marigolds near your crops to deter pests naturally.',
      ),
      Tip(
        userName: 'Hassan',
        content: 'Compost kitchen scraps to create nutrient-rich fertilizer.',
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
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/user/upload-image'));
      request.files.add(await http.MultipartFile.fromPath('image', image.path));
      final response = await request.send();
      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        final data = jsonDecode(responseData);
        return data['imageUrl'];
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

  Future<User> fetchUserFromApi() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/user/profile'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return User.fromJson(data);
      } else {
        throw Exception('Failed to load user profile: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching user profile: $e');
    }
  }

  Future<bool> updateUserProfile(String name, String username, String imageUrl, String location, String role) async {
    await Future.delayed(Duration(seconds: 1));
    print('Mock API: User profile updated - Name: $name, Username: $username, Image: $imageUrl, Location: $location, Role: $role');
    return true;
  }

  Future<bool> updateUserProfileFromApi(String name, String username, String imageUrl, String location, String role) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/user/profile'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'username': username,
          'imageUrl': imageUrl,
          'location': location,
          'role': role,
        }),
      );
      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception('Failed to update user profile: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating user profile: $e');
    }
  }

  Future<bool> logout() async {
    await Future.delayed(Duration(seconds: 1));
    print('Mock API: User logged out');
    return true;
  }

  Future<bool> logoutFromApi() async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/logout'),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception('Failed to logout: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error logging out: $e');
    }
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

  Future<Auth> loginFromApi(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Auth.fromJson(data);
      } else {
        throw Exception('Failed to login: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error logging in: $e');
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

  Future<bool> signupFromApi(String fullName, String phoneNumber, String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/signup'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'fullName': fullName,
          'phoneNumber': phoneNumber,
          'email': email,
          'password': password,
        }),
      );
      if (response.statusCode == 201) {
        return true;
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

  Future<List<String>> fetchSavedTipsFromApi() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/user/saved-tips'));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<String>();
      } else {
        throw Exception('Failed to load saved tips: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching saved tips: $e');
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
      final response = await http.get(Uri.parse('$baseUrl/experts'));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Expert.fromJson(json)).toList();
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

  Future<bool> bookConsultationFromApi(String expertName, String date, String time) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/experts/consultations'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'expertName': expertName,
          'date': date,
          'time': time,
        }),
      );
      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception('Failed to book consultation: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error booking consultation: $e');
    }
  }

  Future<List<SuccessStory>> fetchSuccessStoriesFromApi() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/community/success-stories'));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => SuccessStory.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load success stories: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching success stories: $e');
    }
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

  Future<List<Tip>> fetchTipsFromApi() async {
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
}
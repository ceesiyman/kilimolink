import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../model/community_message_model.dart' as community;
import 'auth_storage_service.dart';

class CommunityApiService {
  final String baseUrl = dotenv.env['BASE_URL'] ?? 'https://api.farmapp.com';
  final AuthStorageService _authStorage = AuthStorageService();

  // Helper method to get auth headers
  Future<Map<String, String>> _getAuthHeaders() async {
    final token = await _authStorage.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
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
} 
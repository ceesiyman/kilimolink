import 'package:flutter/material.dart';
import 'user_model.dart';

class Consultation {
  final int id;
  final int farmerId;
  final int expertId;
  final DateTime consultationDate;
  final String description;
  final String status;
  final String? expertNotes;
  final String? declineReason;
  final DateTime createdAt;
  final DateTime updatedAt;
  final User expert;
  final User? farmer;

  Consultation({
    required this.id,
    required this.farmerId,
    required this.expertId,
    required this.consultationDate,
    required this.description,
    required this.status,
    this.expertNotes,
    this.declineReason,
    required this.createdAt,
    required this.updatedAt,
    required this.expert,
    this.farmer,
  });

  factory Consultation.fromJson(Map<String, dynamic> json) {
    try {
      print('Parsing consultation JSON: $json');
      
      // Handle potential null values
      final expertJson = json['expert'];
      final farmerJson = json['farmer'];
      
      User? expertUser;
      User? farmerUser;
      
      // Parse expert user
      if (expertJson != null) {
        try {
          expertUser = User.fromJson(expertJson);
        } catch (e) {
          print('Error parsing expert user: $e');
          throw Exception('Failed to parse expert user data: $e');
        }
      } else {
        // If expert data is missing, create a placeholder expert user
        // This happens when an expert is viewing their own consultations
        print('Expert data missing, creating placeholder expert user');
        expertUser = User(
          name: 'You',
          username: '@expert',
          email: '',
          imageUrl: '',
          favorites: [],
          location: '',
          savedTips: [],
          role: 'expert',
        );
      }
      
      if (farmerJson != null) {
        try {
          farmerUser = User.fromJson(farmerJson);
        } catch (e) {
          print('Error parsing farmer user: $e');
          // Don't throw here, just log the error and continue without farmer data
        }
      }
      
      return Consultation(
        id: json['id'] ?? 0,
        farmerId: json['farmer_id'] ?? 0,
        expertId: json['expert_id'] ?? 0,
        consultationDate: DateTime.parse(json['consultation_date'] ?? DateTime.now().toIso8601String()),
        description: json['description'] ?? '',
        status: json['status'] ?? 'pending',
        expertNotes: json['expert_notes'],
        declineReason: json['decline_reason'],
        createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
        updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
        expert: expertUser,
        farmer: farmerUser,
      );
    } catch (e) {
      print('Error parsing consultation JSON: $e');
      print('JSON data: $json');
      rethrow;
    }
  }

  String get formattedDate {
    return '${consultationDate.day}/${consultationDate.month}/${consultationDate.year}';
  }

  String get formattedTime {
    return '${consultationDate.hour}:${consultationDate.minute.toString().padLeft(2, '0')}';
  }

  Color get statusColor {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'declined':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
} 
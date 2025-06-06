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
  });

  factory Consultation.fromJson(Map<String, dynamic> json) {
    return Consultation(
      id: json['id'],
      farmerId: json['farmer_id'],
      expertId: json['expert_id'],
      consultationDate: DateTime.parse(json['consultation_date']),
      description: json['description'],
      status: json['status'],
      expertNotes: json['expert_notes'],
      declineReason: json['decline_reason'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      expert: User.fromJson(json['expert']),
    );
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
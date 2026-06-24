import 'package:flutter/material.dart';

class AiPlanItem {
  final String? id;
  final String title;
  final String description;
  final DateTime date;
  final TimeOfDay? time;
  final String type; // 'deadline', 'event', 'general'
  final String location;
  final bool isCompleted;
  final DateTime? createdAt;

  const AiPlanItem({
    this.id,
    required this.title,
    this.description = '',
    required this.date,
    this.time,
    this.type = 'general',
    this.location = '',
    this.isCompleted = false,
    this.createdAt,
  });

  AiPlanItem copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? date,
    TimeOfDay? time,
    String? type,
    String? location,
    bool? isCompleted,
    DateTime? createdAt,
  }) {
    return AiPlanItem(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      date: date ?? this.date,
      time: time ?? this.time,
      type: type ?? this.type,
      location: location ?? this.location,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'date': date.toIso8601String(),
      'time': time != null
          ? '${time!.hour.toString().padLeft(2, '0')}:${time!.minute.toString().padLeft(2, '0')}'
          : null,
      'type': type,
      'location': location,
      'isCompleted': isCompleted,
      'createdAt': createdAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
    };
  }

  factory AiPlanItem.fromMap(Map<String, dynamic> map, [String? docId]) {
    TimeOfDay? parsedTime;
    if (map['time'] != null) {
      final timeParts = (map['time'] as String).split(':');
      if (timeParts.length == 2) {
        parsedTime = TimeOfDay(
          hour: int.parse(timeParts[0]),
          minute: int.parse(timeParts[1]),
        );
      }
    }

    DateTime parsedDate = DateTime.now();
    if (map['date'] != null) {
      parsedDate = DateTime.parse(map['date'] as String);
    }

    DateTime? parsedCreatedAt;
    if (map['createdAt'] != null) {
      if (map['createdAt'] is String) {
        parsedCreatedAt = DateTime.parse(map['createdAt'] as String);
      } else {
        // Handle firestore Timestamp
        parsedCreatedAt = (map['createdAt'] as dynamic).toDate();
      }
    }

    return AiPlanItem(
      id: docId ?? map['id'],
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      date: parsedDate,
      time: parsedTime,
      type: map['type'] ?? 'general',
      location: map['location'] ?? '',
      isCompleted: map['isCompleted'] ?? false,
      createdAt: parsedCreatedAt,
    );
  }
}

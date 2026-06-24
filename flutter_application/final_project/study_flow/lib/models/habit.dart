import 'package:flutter/material.dart';

class Habit {
  String? id;
  String name = '';
  TimeOfDay? time;
  String repeatType = 'everyday'; // 'everyday' or 'specific_days'
  List<int> selectedDays = []; // 0-6 for Monday-Sunday
  String? description;

  Habit({
    this.id,
    required this.name,
    this.time,
    this.repeatType = 'everyday',
    this.selectedDays = const [],
    this.description,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'time': time != null ? '${time!.hour}:${time!.minute}' : null,
      'repeatType': repeatType,
      'selectedDays': selectedDays,
      'description': description,
    };
  }

  factory Habit.fromMap(Map<String, dynamic> map) {
    List<int> days = [];
    if (map['selectedDays'] != null) {
      days = List<int>.from(map['selectedDays']);
    }

    TimeOfDay? timeOfDay;
    if (map['time'] != null) {
      final timeParts = (map['time'] as String).split(':');
      timeOfDay = TimeOfDay(hour: int.parse(timeParts[0]), minute: int.parse(timeParts[1]));
    }

    return Habit(
      id: map['id'],
      name: map['name'] ?? '',
      time: timeOfDay,
      repeatType: map['repeatType'] ?? 'everyday',
      selectedDays: days,
      description: map['description'],
    );
  }
}

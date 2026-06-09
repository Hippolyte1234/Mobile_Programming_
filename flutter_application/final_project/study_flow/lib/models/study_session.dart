import 'package:isar/isar.dart';

@collection
class StudySession {
  Id id = Isar.autoIncrement;

  DateTime? startTime;
  DateTime? endTime;
  String? date;

  String? subject;
  String? duration;
  String? notes;

  StudySession({
    this.subject,
    this.duration,
    this.notes,
    this.date,
    this.startTime,
    this.endTime,
  });

  Map<String, dynamic> toMap() {
    return {
      'subject': subject,
      'duration': duration,
      'notes': notes,
      'date': date,
      'startTime': startTime?.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
    };
  }

  factory StudySession.fromMap(Map<String, dynamic> map) {
    return StudySession(
      subject: map['subject'],
      duration: map['duration'],
      notes: map['notes'],
      date: map['date'],
      startTime: map['startTime'] != null ? DateTime.parse(map['startTime']) : null,
      endTime: map['endTime'] != null ? DateTime.parse(map['endTime']) : null,
    );
  }
}
  


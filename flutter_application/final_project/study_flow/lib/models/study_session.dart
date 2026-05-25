import 'package:isar/isar.dart';

@collection
class StudySession {
  Id id = Isar.autoIncrement;

  late DateTime startTime;
  late DateTime endTime;
  late String date;

  late String subject;
  late String duration;
  late String notes;
  

}
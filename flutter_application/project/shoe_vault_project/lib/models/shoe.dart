import 'package:isar/isar.dart';

part 'shoe.g.dart';

@collection
class Shoe {
  Id id = Isar.autoIncrement;

  late String modelName;
  late double size;
  late String type;
  late DateTime createdAt;
  late double kilometers;
  String? localImagePath;
  String? imageData; // BAse64 Image
  
  @Index()
  String? firestoreId; // For cloud sync

  IsarLink<Brand> brand = IsarLink<Brand>();
}

@collection
class Brand {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String name;
}
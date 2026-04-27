import 'package:isar/isar.dart';
import '../models/shoe.dart';

class DatabaseService {
  final Isar isar;

  DatabaseService(this.isar);

  // --- CRUD OPERATIONS ---

  Future<Brand> findOrCreateBrand(String name) async {
    final existing = await isar.brands.filter().nameEqualTo(name).findFirst();
    if (existing != null) return existing;
  
    final newBrand = Brand()..name = name;
    await isar.writeTxn(() async {
      await isar.brands.put(newBrand);
    });
    return newBrand;
  }

  Future<void> saveBrandAndShoe(Brand brand, Shoe shoe) async {
    final existingBrand = await findOrCreateBrand(brand.name);
    shoe.brand.value = existingBrand;
    
    await isar.writeTxn(() async {
      await isar.shoes.put(shoe);
      await shoe.brand.save();
    });
  }

  Future<void> saveShoe(Shoe shoe) async {
    await isar.writeTxn(() async {
      await isar.shoes.put(shoe);
    });
  }

  Stream<List<Shoe>> listenToShoes() {
  return isar.shoes.where().sortByCreatedAtDesc().watch(fireImmediately: true).asyncMap((shoes) async {
    for (final shoe in shoes) {
      await shoe.brand.load(); // load the link for each shoe
    }
    return shoes;
  });
}


  Future<void> updateDistance(int id, double newKm) async {
    await isar.writeTxn(() async {
      final shoe = await isar.shoes.get(id);
      if (shoe != null) {
        shoe.kilometers = newKm;
        await isar.shoes.put(shoe);
      }
    });
  }

  Future<void> deleteShoe(int id) async {
    await isar.writeTxn(() async {
      await isar.shoes.delete(id);
    });
  }

  Future<bool> shoeExistsByFirestoreId(String firestoreId) async {
    final existing = await isar.shoes
        .filter()
        .firestoreIdEqualTo(firestoreId)
        .findFirst();
    return existing != null;
  }
}
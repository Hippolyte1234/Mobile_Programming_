import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/shoe.dart';

class CloudService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  

  Future<void> uploadShoeToCloud(Shoe shoe, String userId) async {
    await shoe.brand.load(); // ensure the link is loaded
    String? base64Image;


    
    if (shoe.localImagePath != null) {
      File file = File(shoe.localImagePath!);
      
      List<int> imageBytes = await file.readAsBytes();
      base64Image = base64Encode(imageBytes);
    }

    final docRef = await _firestore.collection('users').doc(userId).collection('shoes').add({
      'modelName': shoe.modelName,
      'size': shoe.size,
      'type': shoe.type,
      'kilometers': shoe.kilometers,
      'imageData': base64Image,
      'createdAt': shoe.createdAt.toIso8601String(),
      'brand': shoe.brand.value?.name,
    });

    shoe.firestoreId = docRef.id;
  }

  Future<void> deleteShoeFromCloud(String userID, String firestoreId) async {
    await _firestore.collection('users').doc(userID).collection('shoes').doc(firestoreId).delete();
  }

  Future<List<Map<String, dynamic>>> getShoesFromCloud(String userId) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('shoes')
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        return doc.data() as Map<String, dynamic>;
      }).toList();
    } catch (e) {
      print("Erreur lors de la récupération : $e");
      return [];
    }
  }

  Future<List<({Brand brand, Shoe shoe})>> syncShoesFromCloud(String userId) async {
    final cloudShoes = await getShoesFromCloud(userId);
    
    return cloudShoes.map((data) {
      final shoe = Shoe()
        ..modelName = data['modelName'] ?? 'Unknown Model'
        ..kilometers = (data['kilometers'] ?? 0).toDouble()
        ..size = (data['size'] ?? 0).toDouble()
        ..type = data['type'] ?? 'Unknown Type'
        ..imageData = data['imageData']
        ..createdAt = data['createdAt'] != null
            ? DateTime.parse(data['createdAt'])
            : DateTime.now();
      return (shoe: shoe, brand: Brand()..name = data['brand'] ?? 'Unknown Brand');
    }).toList();
  }

  Future<void> updateShoeInCloud(Shoe shoe, String userId) async {
    if (shoe.firestoreId == null) return;
    
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('shoes')
        .doc(shoe.firestoreId)
        .update({'kilometers': shoe.kilometers});
  }
}
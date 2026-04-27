import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shoe_vault_project/models/shoe.dart';
import 'package:shoe_vault_project/services/cloud_service.dart';
import 'package:shoe_vault_project/services/database_service.dart';
import 'package:shoe_vault_project/screens/shoe_homescreen.dart';

class ShoeDetailsScreen extends StatelessWidget{
  final DatabaseService dbService;
  final Shoe shoe;

  const ShoeDetailsScreen({super.key, required this.shoe, required this.dbService});

  Widget _buildShoeImage(Shoe shoe) {
    if (shoe.localImagePath != null && File(shoe.localImagePath!).existsSync()) {
      return Image.file(
        File(shoe.localImagePath!),
        fit: BoxFit.cover,
        width: double.infinity,
      );
    } else if (shoe.imageData != null && shoe.imageData!.isNotEmpty) {
      return Image.memory(
        base64Decode(shoe.imageData!),
        fit: BoxFit.cover,
        width: double.infinity,
      );
    } else {
      return Container(
        color: Colors.grey[300],
        child: const Icon(Icons.image, size: 50),
      );
    }
  }

  void _shoeUpdateDistance(BuildContext context, Shoe shoe) {
    final TextEditingController kmUpdateController = TextEditingController();
    final cloudService = CloudService();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Permet au clavier de ne pas cacher le champ
      backgroundColor: Colors.transparent, // Rend le fond du modal invisible
      builder: (context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom, // Ajuste selon le clavier
          left: 20,
          right: 20,
          top: 20,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95), // Fond semi-transparent
          borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min, // Le modal prend juste la place nécessaire
          children: [
            Text(
              'Update : ${shoe.modelName}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: kmUpdateController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Current Distance : ${shoe.kilometers} km',
                hintText: 'Enter the new distance',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
              onPressed: () async {
                double? newKm = double.tryParse(kmUpdateController.text);
                if (newKm != null) {
                  // 1. Isar update
                  shoe.kilometers = newKm;
                  await dbService.saveBrandAndShoe(shoe.brand.value!, shoe);

                  // 2. Firebase update
                  final user = FirebaseAuth.instance.currentUser;
                  if (user != null) {
                    await cloudService.updateShoeInCloud(shoe, user.uid);
                  }

                  if (context.mounted) Navigator.pop(context);
                }
              },
              child: const Text('Sauvegarder'),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  String _getFormattedDate(DateTime dateInput) {
    var string = dateInput.toLocal().toString().split(' ');
    String date = string[0];
    String time = string[1].substring(0, 8);
    return 'Added on: $date at $time';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(shoe.modelName),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Model: ${shoe.modelName}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Expanded(
              flex: 2,
              child: _buildShoeImage(shoe),
            ),
            SizedBox(height: 8),
            Text('Brand: ${shoe.brand.value?.name ?? "Unknown"}', style: TextStyle(fontSize: 16)),
            Text('Size: ${shoe.size}', style: TextStyle(fontSize: 16)),
            Text('Type: ${shoe.type}', style: TextStyle(fontSize: 16)),
            Text('Kilometers: ${shoe.kilometers}', style: TextStyle(fontSize: 16)),
            Text(_getFormattedDate(shoe.createdAt), style: TextStyle(fontSize: 16)),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: () => _shoeUpdateDistance(context, shoe),
                  child: const Text('Update') 
                ), 
                const SizedBox(width: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: () async {
                    await dbService.deleteShoe(shoe.id);
                    final user = FirebaseAuth.instance.currentUser;
                    if (user != null && shoe.firestoreId != null) {
                      final cloudService = CloudService();
                      await cloudService.deleteShoeFromCloud(user.uid, shoe.firestoreId!);
                    }
                  },
                  child: Icon(Icons.delete, color: Colors.white)
                ),
              ],
            )
          ],
        ),
      ),
    ); 
  }
}
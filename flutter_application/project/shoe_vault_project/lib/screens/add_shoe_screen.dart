import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shoe_vault_project/services/cloud_service.dart';
import 'package:shoe_vault_project/services/notification_service.dart';
import '../models/shoe.dart';
import '../services/database_service.dart';

class AddShoeScreen extends StatefulWidget{
  final DatabaseService dbService;

  const AddShoeScreen({super.key, required this.dbService});

  @override
  State<AddShoeScreen> createState() => _AddShoeScreenState();
}

class _AddShoeScreenState extends State<AddShoeScreen> {
  String? modelName;
  double? size;
  String? type;
  String? localImagePath;
  double kilometers = 0.0;
  File? _imageFile;
  String? brand;

  void _pickImage() async{
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera, maxWidth: 400, imageQuality: 50);


    if(pickedFile != null){
      setState(() {
        _imageFile = File(pickedFile.path);
        localImagePath = pickedFile.path;
      });
    }
  }

  void saveModel() {
    if (modelController.text.isNotEmpty) {
      modelName = modelController.text;
    } else {
      modelName = 'Unknown Model';
    }
  }
  void saveSize() {
    size = double.tryParse(sizeController.text) ?? 0.0;
  }
  void saveType() {
    if (typeController.text.isNotEmpty) {
      type = typeController.text;
    } else {
      type = 'Unknown Type';
    }
  }
  void saveDistance() {
    kilometers = double.tryParse(kmController.text) ?? 0.0;
  }
  

  TextEditingController modelController = TextEditingController();
  TextEditingController sizeController = TextEditingController();
  TextEditingController typeController = TextEditingController();
  TextEditingController kmController = TextEditingController();
  TextEditingController brandController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Add New Shoe')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton.icon(
              onPressed: _pickImage,
              label: Text('Take Shoe Picture'),
              icon: Icon(Icons.camera),
            ),
             SizedBox(height: 10),
             if(_imageFile != null)
              Image.file(_imageFile!, height: 200),
             SizedBox(height: 20
            ),
            SizedBox(height: 20),
            TextField(
              controller: brandController,
              decoration: InputDecoration(labelText: 'Brand'),
            ),
            SizedBox(height: 10),
            TextField(
              controller: modelController,
              decoration: InputDecoration(labelText: 'Model Name'),
            ),
            SizedBox(height: 10),
            TextField(
              controller: sizeController,
              decoration: InputDecoration(labelText: 'Size'),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 10),
            TextField(
              controller: typeController,
              decoration: InputDecoration(labelText: 'Type'),
            ),
            SizedBox(height: 10),
            TextField(
              controller: kmController,
              decoration: InputDecoration(labelText: 'Kilometers (nothing if new)', suffixText: ' km'),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                saveModel();
                saveSize();
                saveType();
                saveDistance();
                final brandObj = Brand()..name = brandController.text.isEmpty ? 'Unknown Brand' : brandController.text;

                final shoe = Shoe()
                  ..modelName = modelName!
                  ..size = size!
                  ..type = type!
                  ..kilometers = kilometers
                  ..createdAt = DateTime.now()
                  ..localImagePath = localImagePath;

                shoe.brand.value = brandObj;
                  
                final user = FirebaseAuth.instance.currentUser;
                if (user == null) return;

                await widget.dbService.saveBrandAndShoe(brandObj, shoe);

                //firebase save
                final cloudService = CloudService();
                await cloudService.uploadShoeToCloud(shoe, user.uid);

                //Isar save just to save firestoreId
                await widget.dbService.saveShoe(shoe); 

                await NotificationService.showShoeAddedNotification();
                 if (mounted) {
                  Navigator.pop(context);
                }
                
              },
              child:Text('Save Shoe')
            ),
            SizedBox(height: 20),
            
          ],
        ),
      ),
    );
  }
}

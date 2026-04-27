import 'dart:io';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shoe_vault_project/models/shoe.dart';
import 'package:shoe_vault_project/screens/add_shoe_screen.dart';
import 'package:shoe_vault_project/screens/shoe_details_screen.dart';
import 'package:shoe_vault_project/services/cloud_service.dart';
import 'package:shoe_vault_project/services/database_service.dart';

class ShoeHomeScreen extends StatefulWidget {
  final DatabaseService dbService;

  const ShoeHomeScreen({super.key, required this.dbService});

  @override
  State<ShoeHomeScreen> createState() => _ShoeHomeScreenState();
}

class _ShoeHomeScreenState extends State<ShoeHomeScreen> {
  double threshold = 500.0;
  

  @override
  void initState() {
    super.initState();
    _loadThreshold();
  }

  void _loadThreshold() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      threshold = prefs.getDouble('km_threshold') ?? 500.0;
    });
  }

  Future<double> getThreshold() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      threshold = prefs.getDouble('km_threshold') ?? 500.0;
    });
    return threshold;
  }

  Future<void> syncFromCloud() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final cloudService = CloudService();
    final results = await cloudService.syncShoesFromCloud(user.uid);
    
    for (final result in results) {
      if (result.shoe.firestoreId != null) {
        final exists = await widget.dbService.shoeExistsByFirestoreId(result.shoe.firestoreId!);
        if (!exists) { // only save if not already in Isar
          await widget.dbService.saveBrandAndShoe(result.brand, result.shoe);
        }
      }
    }
  }

  Text distanceprinting(Shoe shoe) {
    if (shoe.kilometers >= threshold) {
      return Text('Distance: ${shoe.kilometers} km (Needs replacement!)', style: TextStyle(color: Colors.red));
    } else {
      return Text('Distance: ${shoe.kilometers} km');
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
                  await widget.dbService.saveBrandAndShoe(shoe.brand.value!, shoe);

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

  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shoe Vault'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            onPressed: () async {
              await syncFromCloud();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Sync completed!')),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<List<Shoe>>(
        stream: widget.dbService.listenToShoes(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final shoes = snapshot.data ?? [];
          if (shoes.isEmpty) {
            return const Center(child: Text('No shoes added yet!'));
          }
          return GridView.builder(
            padding: const EdgeInsets.all(10),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.6,
              crossAxisCount: 2,
            ),
            itemCount: shoes.length,
            itemBuilder: (context, index) {
              final shoe = shoes[index];
              return InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ShoeDetailsScreen(dbService: widget.dbService, shoe: shoe),
                    ),
                  );
                },
                child: Card(
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      Expanded(
                        flex: 2,
                      child: _buildShoeImage(shoe),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        children: [
                          Text(shoe.modelName,
                              style: const TextStyle(fontWeight: FontWeight.bold)),
                          distanceprinting(shoe),
                          Row(
                            children: [
                              Expanded(
                                child: Text('Size: ${shoe.size}'),
                              ),
                              Expanded(
                                child: Text('Type: ${shoe.type}'),
                              ),
                              
                            ],
                          ),
                          Text('Added: ${shoe.createdAt.toLocal().toString().split(' ')[0]}'),
                          Text('Brand: ${shoe.brand.value?.name ?? 'Unknown'}'), 
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              ElevatedButton(
                                onPressed: () => _shoeUpdateDistance(context, shoe),
                                child: const Text('Update') 
                              ), 
                              const SizedBox(width: 10),
                            ],
                          )                      
                        ],
                      ),
                    ),
                  ],
                ),
              ));
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddShoeScreen(dbService: widget.dbService),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Text('Shoe Vault Menu', style: TextStyle(color: Colors.white, fontSize: 24)),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Home'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.sync),
              title: const Text('Sync with Cloud'),
              onTap: () async {
                await syncFromCloud();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Sync completed!')),
                );
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.logout),
              title: Text('Logout'),
              onTap: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.pushReplacementNamed(context, '/');
              },
            ),
            ListTile(
              leading: Icon(Icons.info),
              title: Text('About'),
              onTap: () {
                showAboutDialog(
                  context: context,
                  applicationName: 'Shoe Vault',
                  applicationVersion: '1.0.11',
                  applicationIcon: Icon(Icons.info),
                  children: [
                    Text('An app to track your running shoes and their distance.'),
                    Text('Sends you daily notifications to remind you to update your shoe\'s distance.'),
                    Text('Syncs your shoe data with the cloud for backup and multi-device access.'),
                    Text('Developed with Flutter, Isar, and Firebase.'),
                    Text('Created by Hippolyte Catteau-Verniers for Mobile Programming project.'),
                  ],
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.settings),
              title: Text('Settings'),
              onTap: () async {
                await Navigator.pushNamed(context, 'settings');
                _loadThreshold();
              },

            )
          ],
        ),
      ),
    );
  }
}
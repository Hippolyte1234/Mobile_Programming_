import 'package:flutter/material.dart';

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: true, 
    home: MyFirstApp(),
  ));
}

class MyFirstApp extends StatelessWidget {
  const MyFirstApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My first app'),
        backgroundColor: Colors.yellow, 
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            color: Colors.lightBlueAccent, 
            margin: const EdgeInsets.all(16.0),
            padding: const EdgeInsets.all(40.0), 
            child: Image.network(
              'https://picsum.photos/id/15/400/400', 
              fit: BoxFit.cover,
            ),
          ),
          
          Container(
            width: double.infinity,
            color: Colors.pinkAccent,
            margin: const EdgeInsets.symmetric(horizontal: 16.0),
            padding: const EdgeInsets.all(20.0),
            child: const Text(
              'What image is that?',
              style: TextStyle(fontSize: 16, color: Colors.black87),
            ),
          ),
          
          const SizedBox(height: 20), 

          Container(
            color: Colors.amberAccent,
            margin: const EdgeInsets.symmetric(horizontal: 16.0),
            padding: const EdgeInsets.symmetric(vertical: 10.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildElevatedMenuButton(Icons.restaurant, 'Food'),
                _buildElevatedMenuButton(Icons.umbrella, 'Scenery'),
                _buildElevatedMenuButton(Icons.person, 'People'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildElevatedMenuButton(IconData icon, String label) {
    return ElevatedButton(
      onPressed: () {
        print('Bouton $label cliqué');
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.amberAccent, 
        foregroundColor: Colors.black87, 
        elevation: 2, 
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8), 
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 24),
          const SizedBox(height: 4), 
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
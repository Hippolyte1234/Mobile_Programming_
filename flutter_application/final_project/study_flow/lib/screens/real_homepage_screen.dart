import 'package:flutter/material.dart';


class RealHomepageScreen extends StatefulWidget{
  const RealHomepageScreen({super.key});

  @override
  State<RealHomepageScreen> createState() => _RealHomepageScreenState();
}

class _RealHomepageScreenState extends State<RealHomepageScreen> {
  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:Text('Homepage'),
      ),
      body: Center(
        child: Text('Welcome to the Homepage!'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, 'logger');
        },
        child: Icon(Icons.add),
      ),
    );
  }
}
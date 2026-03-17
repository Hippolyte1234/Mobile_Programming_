import 'package:flutter/material.dart';

void main() {
  runApp( MaterialApp(
    home: Scaffold(
        appBar: AppBar(
          title: Text('Hello World'),
          centerTitle: true,
        ),
        body: Center(
          child: Text('Welcome to Flutter'),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            print('Floating Action Button Pressed');
          },
          child: Text('Click me'),
        )
  
  ),
  ));
}

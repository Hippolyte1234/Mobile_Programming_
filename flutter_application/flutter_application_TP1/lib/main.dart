import 'package:flutter/material.dart';
import 'dart:math';

void main() => runApp(const MaterialApp(home: RandomMixer()));

class RandomMixer extends StatefulWidget {
  const RandomMixer({super.key});
  @override
  State<RandomMixer> createState() => _RandomMixerState();
}

class _RandomMixerState extends State<RandomMixer> {
  final _rng = Random();
  int _num = 0;
  String _card = "Click now \"Mix everything\" to draw";
  Color _color = Colors.grey;

  void _update() => setState(() {
    _num = _rng.nextInt(101);
    _card = "${['A','2','3','4','5','6','7','8','9','10','J','Q','K'][_rng.nextInt(13)]} ${['♠️','♥️','♦️','♣️'][_rng.nextInt(4)]}";
    _color = Color.fromRGBO(_rng.nextInt(256), _rng.nextInt(256), _rng.nextInt(256), 1);
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Random Mixer')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Text("Number: $_num", style: const TextStyle(fontSize: 24)),
            Text("Card: $_card", style: const TextStyle(fontSize: 24)),
            Container(height: 50, color: _color),
            Text("Hex: #${_color.value.toRadixString(16).toUpperCase().substring(2)}", style: const TextStyle(fontSize: 20)),
            ElevatedButton(onPressed: _update, child: const Text("Mix Everything now")),
          ],
        ),
      ),
    );
  }
}
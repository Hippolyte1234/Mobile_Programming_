import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget{
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
} 


class _SettingsScreenState extends State<SettingsScreen> {
  double threshold = 500.0; // default
  
  void updateThresholdDistance(double value) async{
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('km_threshold', value);

  }


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

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          children: [
            Text('Warning threshold: ${threshold.toInt()} km'),
            Slider(
              value: threshold,
              min: 0.0,
              max: 1500,
              divisions: 300,
              label: '${threshold.toInt()} km',
              onChanged: (value) {
                setState(() {
                  threshold = value;
                });
                updateThresholdDistance(value);
              },
              
            ),
          ]
        )
      ),
    );
  }
}
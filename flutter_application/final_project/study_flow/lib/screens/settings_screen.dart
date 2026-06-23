import 'package:flutter/material.dart';
import 'package:study_flow/services/gemini_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String? _apiKey;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    final key = await GeminiService.instance.getApiKey();
    if (mounted) {
      setState(() {
        _apiKey = key;
        _isLoading = false;
      });
    }
  }

  void _showApiKeyDialog() {
    final controller = TextEditingController(text: _apiKey);
    
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Gemini API Key'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Add your Gemini API Key to enable the AI Chat Bot. You can generate a free key in Google AI Studio.',
              style: TextStyle(fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'API Key',
                border: OutlineInputBorder(),
                hintText: 'AIzaSy...',
              ),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          if (_apiKey != null && _apiKey!.isNotEmpty)
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              onPressed: () async {
                await GeminiService.instance.clearApiKey();
                await _loadSettings();
                if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Gemini API Key cleared')),
                  );
                }
              },
              child: const Text('Clear Key'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final newKey = controller.text.trim();
              if (newKey.isNotEmpty) {
                await GeminiService.instance.saveApiKey(newKey);
                await _loadSettings();
              }
              if (dialogCtx.mounted) Navigator.pop(dialogCtx);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Gemini API Key saved')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasKey = _apiKey != null && _apiKey!.isNotEmpty;

    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const SizedBox(height: 8),
                const Padding(
                  padding: EdgeInsets.only(left: 8, bottom: 8),
                  child: Text(
                    'Preferences',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
                  ),
                ),
                Card(
                  elevation: 0,
                  color: Colors.grey.shade50,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: CircleAvatar(
                      backgroundColor: hasKey ? Colors.green.shade50 : Colors.blue.shade50,
                      child: Icon(
                        Icons.vpn_key_outlined,
                        color: hasKey ? Colors.green.shade700 : Colors.blue.shade700,
                      ),
                    ),
                    title: const Text(
                      'Gemini API Credentials',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        hasKey ? 'Configured (Active)' : 'Not Configured (Tap to setup)',
                        style: TextStyle(
                          color: hasKey ? Colors.green.shade700 : Colors.grey.shade600,
                          fontWeight: hasKey ? FontWeight.w500 : FontWeight.normal,
                        ),
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _showApiKeyDialog,
                  ),
                ),
                const SizedBox(height: 16),
                const Padding(
                  padding: EdgeInsets.only(left: 8, bottom: 8),
                  child: Text(
                    'About',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
                  ),
                ),
                Card(
                  elevation: 0,
                  color: Colors.grey.shade50,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  child: const Column(
                    children: [
                      ListTile(
                        leading: Icon(Icons.info_outline),
                        title: Text('App Version'),
                        trailing: Text('1.0.0', style: TextStyle(color: Colors.grey)),
                      ),
                      Divider(height: 1),
                      ListTile(
                        leading: Icon(Icons.smart_toy_outlined),
                        title: Text('AI Capabilities'),
                        trailing: Text('Gemini 1.5 Flash', style: TextStyle(color: Colors.grey)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
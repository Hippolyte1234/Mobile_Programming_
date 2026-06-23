import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:study_flow/services/gemini_service.dart';
import 'package:url_launcher/url_launcher.dart';

class Message {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  Message({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final List<Message> _messages = [];
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  bool _isLoadingKey = true;
  bool _isApiKeyConfigured = false;
  bool _isTyping = false;
  
  ChatSession? _chatSession;
  String? _apiKey;

  /// Use Gemini 2.5 Flash Lite as the only model.
  static const _modelCandidates = [
    'gemini-2.5-flash-lite',
  ];
  int _currentModelIndex = 0;

  @override
  void initState() {
    super.initState();
    _checkApiKey();
  }

  List<Content> _systemHistory() => [
    Content.text(
      "You are a highly structured planning assistant. Whenever a user asks you to create a plan, suggest a schedule, or organize an event, you must strictly reply using the exact format and rules outlined below.\n\n"
      "First, provide a brief explanation of the overall strategy, approach, or theme for the plans. Then, provide exactly 3 specific plans.\n\n"
      "Strict Output Template:\n\n"
      "[Brief explanation of the overall strategy or theme]\n\n"
      "Date : [Insert appropriate upcoming date]\n"
      "Time : [Insert appropriate time]\n\n"
      "Title : [Insert subject title] (1/3)\n\n"
      "Description : [Insert a brief description of the specific tasks or activities to do]\n\n"
      "Date : [Insert appropriate upcoming date]\n"
      "Time : [Insert appropriate time]\n\n"
      "Title : [Insert the exact same subject title as above] (2/3)\n\n"
      "Description : [Insert a brief description of different tasks or activities to do]\n\n"
      "Date : [Insert appropriate upcoming date]\n"
      "Time : [Insert appropriate time]\n\n"
      "Title : [Insert the exact same subject title as above] (3/3)\n\n"
      "Description : [Insert a brief description of different tasks or activities to do]\n\n"
      "Rules to Follow:\n\n"
      "Quantity: You must always generate exactly three plans.\n\n"
      "Title: The core text of the Title must be identical across all three plans, but you must append the sequential numbering (1/3), (2/3), and (3/3) to the end of each respectively.\n\n"
      "Description: The Description must be unique for each plan, offering different actionable steps or variations of the activity.\n\n"
      "Formatting: Do not deviate from the bolded labels (Date :, Time :, Title :, Description :)."
    ),
    Content.model([
      TextPart("Understood! I am your structured planning assistant. I will strictly follow your output template, rules, and labels for all plans, schedules, or events you ask me to organize. How can I help you plan today?"),
    ]),
  ];

  void _initChatSession(String key, {int modelIndex = 0}) {
    _apiKey = key;
    _currentModelIndex = modelIndex;
    final model = GenerativeModel(
      model: _modelCandidates[_currentModelIndex],
      apiKey: key,
    );
    _chatSession = model.startChat(history: _systemHistory());
  }

  Future<void> _checkApiKey() async {
    setState(() => _isLoadingKey = true);
    final key = await GeminiService.instance.getApiKey();
    if (key != null && key.isNotEmpty) {
      _initChatSession(key);
      
      setState(() {
        _isApiKeyConfigured = true;
        _messages.clear();
        _messages.add(
          Message(
            text: "Hi! I am your structured planning assistant. Ask me to help organize your study timeline, suggest schedules, or plan events!",
            isUser: false,
            timestamp: DateTime.now(),
          ),
        );
      });
    } else {
      setState(() {
        _isApiKeyConfigured = false;
      });
    }
    setState(() => _isLoadingKey = false);
  }

  Future<bool> _saveKey(String key) async {
    final trimmedKey = key.trim();
    if (trimmedKey.isEmpty) return false;

    if (!GeminiService.isValidApiKey(trimmedKey)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid API Key format. It should start with AIza or AQ.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    }

    setState(() => _isLoadingKey = true);
    try {
      await GeminiService.instance.saveApiKey(trimmedKey);
      await _checkApiKey();
      return true;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save key: $e')),
        );
      }
      setState(() => _isLoadingKey = false);
      return false;
    }
  }

  Future<void> _clearKey() async {
    setState(() => _isLoadingKey = true);
    try {
      await GeminiService.instance.clearApiKey();
      _chatSession = null;
      _apiKey = null;
      setState(() {
        _isApiKeyConfigured = false;
        _messages.clear();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to clear key: $e')),
        );
      }
    }
    setState(() => _isLoadingKey = false);
  }

  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _chatSession == null) return;

    setState(() {
      _messages.add(Message(text: text, isUser: true, timestamp: DateTime.now()));
      _controller.clear();
      _isTyping = true;
    });

    _scrollToBottom();

    try {
      final response = await _chatSession!.sendMessage(Content.text(text));
      final replyText = response.text ?? "Sorry, I couldn't generate a reply.";
      
      setState(() {
        _messages.add(Message(text: replyText, isUser: false, timestamp: DateTime.now()));
      });
    } catch (e) {
      final errorStr = e.toString().toLowerCase();

      // On quota/model errors, automatically try the next model candidate.
      if (_apiKey != null &&
          (errorStr.contains('quota') || errorStr.contains('not found') || errorStr.contains('not supported')) &&
          _currentModelIndex + 1 < _modelCandidates.length) {
        final nextIndex = _currentModelIndex + 1;
        _initChatSession(_apiKey!, modelIndex: nextIndex);

        try {
          final retryResponse = await _chatSession!.sendMessage(Content.text(text));
          final replyText = retryResponse.text ?? "Sorry, I couldn't generate a reply.";
          setState(() {
            _messages.add(Message(text: replyText, isUser: false, timestamp: DateTime.now()));
          });
          return; // success on fallback
        } catch (_) {
          // Fall through to show original error
        }
      }

      setState(() {
        _messages.add(
          Message(
            text: "Error communicating with Gemini: $e\n\nPlease check if your API key is valid and you have an active internet connection.",
            isUser: false,
            timestamp: DateTime.now(),
          ),
        );
      });
    } finally {
      setState(() {
        _isTyping = false;
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showSetupDialog() {
    final keyController = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('API Credentials'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Input your Gemini API key from Google AI Studio. Your key will be securely saved to your private user profile.',
              style: TextStyle(fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: () async {
                final url = Uri.parse('https://aistudio.google.com/app/apikey');
                try {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                } catch (_) {}
              },
              child: Text(
                'Get key from Google AI Studio',
                style: TextStyle(
                  color: Colors.blue.shade700,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.underline,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: keyController,
              decoration: const InputDecoration(
                labelText: 'API Key',
                border: OutlineInputBorder(),
                hintText: 'AIzaSy... or AQ....',
              ),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          if (_isApiKeyConfigured)
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              onPressed: () async {
                Navigator.pop(dialogCtx);
                await _clearKey();
              },
              child: const Text('Disconnect Key'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final newKey = keyController.text.trim();
              if (newKey.isNotEmpty) {
                final success = await _saveKey(newKey);
                if (success && dialogCtx.mounted) {
                  Navigator.pop(dialogCtx);
                }
              } else {
                Navigator.pop(dialogCtx);
              }
            },
            child: const Text('Connect'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Chat'),
        centerTitle: true,
        actions: [
          if (!_isLoadingKey)
            IconButton(
              icon: Icon(
                _isApiKeyConfigured ? Icons.vpn_key : Icons.vpn_key_outlined,
                color: _isApiKeyConfigured ? Colors.green : Colors.grey,
              ),
              tooltip: 'Gemini Key Config',
              onPressed: _showSetupDialog,
            ),
        ],
      ),
      body: _isLoadingKey
          ? const Center(child: CircularProgressIndicator())
          : _isApiKeyConfigured
              ? _buildChatInterface()
              : _buildSetupInterface(),
    );
  }

  Widget _buildChatInterface() {
    return Column(
      children: [
        // Messages list
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: _messages.length,
            itemBuilder: (context, i) {
              final message = _messages[i];
              return _buildMessageBubble(message);
            },
          ),
        ),

        // Typing indicator
        if (_isTyping)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Row(
              children: [
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blue),
                ),
                const SizedBox(width: 8),
                Text(
                  'AI is thinking...',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),

        // Message Input Field
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Colors.grey.shade200)),
          ),
          child: SafeArea(
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: 'Ask study flow tips...',
                      hintStyle: TextStyle(color: Colors.grey.shade400),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _sendMessage,
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.blue.shade600,
                    child: const Icon(Icons.send, color: Colors.white, size: 18),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSetupInterface() {
    final setupController = TextEditingController();
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.blue.shade50,
              ),
              child: Icon(
                Icons.auto_awesome,
                size: 64,
                color: Colors.blue.shade600,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Gemini AI Assistant',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Connect your Gemini API Key from Google AI Studio to unlock personalized study recommendations, smart summaries, and chat help.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: () async {
                final url = Uri.parse('https://aistudio.google.com/app/apikey');
                try {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                } catch (_) {}
              },
              child: Text(
                'Get key from Google AI Studio',
                style: TextStyle(
                  color: Colors.blue.shade700,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.underline,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: setupController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Paste Gemini API Key',
                hintText: 'AIzaSy... or AQ....',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.vpn_key_outlined),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => _saveKey(setupController.text),
                child: const Text(
                  'Connect Assistant',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(Message message) {
    final alignRight = message.isUser;
    final bubbleColor = alignRight ? Colors.blue.shade600 : Colors.grey.shade100;
    final textColor = alignRight ? Colors.white : Colors.black87;

    return Align(
      alignment: alignRight ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: alignRight ? const Radius.circular(16) : Radius.zero,
            bottomRight: alignRight ? Radius.zero : const Radius.circular(16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Text(
          message.text,
          style: TextStyle(color: textColor, fontSize: 15),
        ),
      ),
    );
  }
}


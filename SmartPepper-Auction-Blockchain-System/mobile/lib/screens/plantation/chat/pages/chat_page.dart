import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../config/theme.dart';
import '../../../../localization/app_localizations.dart';
import '../../services/plantation_api_client.dart';
import '../../plantation/services/plantation_service.dart';
import '../models/chat_model.dart';
import '../widgets/conversation_sidebar.dart';
import '../providers/chat_provider.dart';

// Farm Logic
import '../../plantation/controllers/plantation_controller.dart';
import '../../../../widgets/language_picker_button.dart';
import '../../../../providers/language_provider.dart';
import '../../plantation/models/farm_record_model.dart';
import '../../../../services/voice_service.dart';


class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<FarmRecord> _farms = [];
  bool _isLoadingFarms = true;
  String? _selectedFarmId;
  late PlantationController _plantationController;
  
  final VoiceService _voiceService = VoiceService();
  bool _isRecording = false;
  bool _isVoiceLoading = false;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _plantationController =
        PlantationController(PlantationService(PlantationApiClient()));
    
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _loadFarms();
  }

  Future<void> _loadFarms() async {
    try {
      final farms = await _plantationController.fetchFarms();
      if (mounted) {
        setState(() {
          _farms = farms;
          _isLoadingFarms = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingFarms = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _voiceService.dispose();
    _pulseController.dispose();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
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

  /// ===============================
  /// SEND MESSAGE
  /// ===============================
  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    _controller.clear();
    _scrollToBottom();

    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    await chatProvider.sendMessage(text, _selectedFarmId, language: languageProvider.locale.languageCode);

    _scrollToBottom();
  }

  /// ===============================
  /// VOICE RECORDING
  /// ===============================
  Future<void> _startRecording() async {
    setState(() {
      _isRecording = true;
    });
    _pulseController.repeat(reverse: true);
    await _voiceService.startRecording();
  }

  Future<void> _stopRecording() async {
    setState(() {
      _isRecording = false;
      _isVoiceLoading = true;
    });
    _pulseController.stop();
    _pulseController.reset();

    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    final answer = await _voiceService.stopAndSend(languageCode: languageProvider.locale.languageCode);

    if (mounted) {
      setState(() {
        _isVoiceLoading = false;
      });

      if (answer != null) {
        final chatProvider = Provider.of<ChatProvider>(context, listen: false);
        // Add bot message
        chatProvider.addMessage(ChatMessage(text: answer, isUser: false, timestamp: DateTime.now()));
        _scrollToBottom();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('chat_error_voice'))),
        );
      }
    }
  }

  /// ===============================
  /// UI
  /// ===============================
  @override
  Widget build(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context);
    final messages = chatProvider.messages;

    return Scaffold(
      drawer: const ConversationSidebar(),
      appBar: AppBar(
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).pop(),
            ),
            Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            ),
          ],
        ),
        leadingWidth: 100, // Enough width for two icons
        title: Text(context.tr('chat_ai_assistant')),
        backgroundColor: AppTheme.forestGreen,
        foregroundColor: Colors.white,
        actions: [
          const LanguagePickerButton(),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          /// FARM SELECTOR (Moved from AppBar)
          if (!_isLoadingFarms && _farms.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              color: AppTheme.deepEmerald,
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String?>(
                  dropdownColor: AppTheme.deepEmerald,
                  isExpanded: true,
                  icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                  value: _selectedFarmId,
                  hint: Text(context.tr('chat_mode_guide'),
                      style: const TextStyle(color: Colors.white70)),
                  items: [
                    DropdownMenuItem<String?>(
                      value: null,
                      child: Text(
                        context.tr('chat_mode_guide_general'),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    ..._farms.map(
                      (f) => DropdownMenuItem<String?>(
                        value: f.id,
                        child: Text(
                          "${context.tr('chat_mode')} ${f.farmName}",
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    )
                  ],
                  onChanged: (value) {
                    setState(() => _selectedFarmId = value);
                  },
                ),
              ),
            ),

          /// MODE INDICATOR
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
            color: _selectedFarmId == null
                ? Colors.blueGrey[100]
                : Colors.green[100],
            child: Text(
              _selectedFarmId == null
                  ? context.tr('chat_guide_desc')
                  : context.tr('chat_farmer_desc'),
              style: TextStyle(
                fontSize: 12,
                color: _selectedFarmId == null
                    ? Colors.blueGrey[800]
                    : Colors.green[800],
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          /// CHAT LIST
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                return _buildMessageBubble(messages[index]);
              },
            ),
          ),

          _buildInputArea(),
        ],
      ),
    );
  }

  /// ===============================
  /// MESSAGE BUBBLE
  /// ===============================
  Widget _buildMessageBubble(ChatMessage msg) {
    final isUser = msg.isUser;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isUser ? AppTheme.pepperGold : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(14),
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              msg.text,
              style: TextStyle(
                color: isUser ? Colors.white : Colors.black87,
                height: 1.4,
              ),
            ),

            /// SOURCES
            if (!isUser && msg.sources != null && msg.sources!.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 10),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('chat_sources'),
                      style:
                          const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    ...msg.sources!.map(
                      (s) => Text(
                        "• $s",
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.black54,
                        ),
                      ),
                    )
                  ],
                ),
              ),

            /// SUGGESTIONS
            if (!isUser && msg.suggestions.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: msg.suggestions.map((s) {
                    return ActionChip(
                      label: Text(
                        s,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black87,
                        ),
                      ),
                      backgroundColor: Colors.white,
                      onPressed: () {
                        _controller.text = s;
                        _sendMessage();
                      },
                    );
                  }).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// ===============================
  /// INPUT AREA
  /// ===============================
  Widget _buildInputArea() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: _selectedFarmId == null
                    ? context.tr('chat_ask_general')
                    : context.tr('chat_ask_farm'),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          if (_isVoiceLoading)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.0),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else ...[
            GestureDetector(
              onLongPressStart: (_) => _startRecording(),
              onLongPressEnd: (_) => _stopRecording(),
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _isRecording ? 1.0 + (_pulseController.value * 0.2) : 1.0,
                    child: IconButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(context.tr('chat_hold_record'))),
                        );
                      },
                      icon: Icon(
                        _isRecording ? Icons.mic : Icons.mic_none,
                        color: _isRecording ? Colors.red : AppTheme.pepperGold,
                      ),
                    ),
                  );
                },
              ),
            ),
            IconButton(
              onPressed: _sendMessage,
              icon: const Icon(Icons.send),
              color: AppTheme.pepperGold,
            ),
          ],
        ],
      ),
    );
  }
}

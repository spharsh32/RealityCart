import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:reality_cart/l10n/app_localizations.dart';

class AIScreen extends StatefulWidget {
  const AIScreen({super.key});

  @override
  State<AIScreen> createState() => _AIScreenState();
}

class _AIScreenState extends State<AIScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _messages = [];

  void _initMessages() {
    // Cannot access AppLocalizations in initState, deferred to build or specific methods.
    _messages.clear();
  }

  @override
  void initState() {
    super.initState();
    _initMessages();
  }

  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _messages.add({
        "text": AppLocalizations.of(context)!.aiWelcomeMessage,
        "isUser": false,
        "time": DateTime.now(),
      });
      _initialized = true;
    }
  }

  void _sendMessage() {
    if (_controller.text.trim().isEmpty) return;

    final userMessage = _controller.text.trim();
    setState(() {
      _messages.add({
        "text": userMessage,
        "isUser": true,
        "time": DateTime.now(),
      });
      _controller.clear();
    });

    _scrollToBottom();

    // Simulate AI typing and response
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          _messages.add({
            "text": _getAIResponse(userMessage, context),
            "isUser": false,
            "time": DateTime.now(),
          });
        });
        _scrollToBottom();
      }
    });
  }

  String _getAIResponse(String message, BuildContext context) {
    message = message.toLowerCase();
    if (message.contains("hello") || message.contains("hi") || message.contains("नमस्ते") || message.contains("हेलो")) {
      return AppLocalizations.of(context)!.aiGreetingResponse;
    } else if (message.contains("price") || message.contains("cost") || message.contains("कीमत") || message.contains("मूल्य")) {
      return AppLocalizations.of(context)!.aiPriceResponse;
    } else if (message.contains("ar") || message.contains("reality") || message.contains("एआर") || message.contains("रियलिटी")) {
      return AppLocalizations.of(context)!.aiArResponse;
    } else if (message.contains("shipping") || message.contains("delivery") || message.contains("शिपिंग") || message.contains("डिलीवरी")) {
      return AppLocalizations.of(context)!.aiShippingResponse;
    } else {
      return AppLocalizations.of(context)!.aiFallbackResponse;
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const FaIcon(FontAwesomeIcons.wandMagicSparkles, size: 20, color: Color(0xFFFB8C00)),
            const SizedBox(width: 10),
            Text(
              AppLocalizations.of(context)!.realityAi,
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
          ],
        ),
        actions: [
            IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
                setState(() {
                _messages.clear();
                _messages.add({
                    "text": AppLocalizations.of(context)!.aiWelcomeMessage,
                    "isUser": false,
                    "time": DateTime.now(),
                });
                });
            },
            tooltip: AppLocalizations.of(context)!.clearChat,
            ),
        ],
        centerTitle: false,
        elevation: 1,
        shadowColor: Colors.black.withOpacity(0.1),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = msg['isUser'] as bool;
                return _buildMessageBubble(msg['text'], isUser, msg['time'], theme, isDark);
              },
            ),
          ),
          _buildInputArea(theme, isDark),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(String text, bool isUser, DateTime time, ThemeData theme, bool isDark) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isUser 
              ? const Color(0xFFFB8C00) 
              : isDark ? const Color(0xFF2C2C2C) : Colors.grey.shade200,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isUser ? const Radius.circular(16) : Radius.zero,
            bottomRight: isUser ? Radius.zero : const Radius.circular(16),
          ),
          boxShadow: [
             BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              text,
              style: TextStyle(
                color: isUser ? Colors.white : theme.textTheme.bodyMedium?.color,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatTime(time),
              style: TextStyle(
                color: isUser ? Colors.white.withOpacity(0.7) : theme.hintColor,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2C2C2C) : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
              ),
              child: TextField(
                controller: _controller,
                textCapitalization: TextCapitalization.sentences,
                onSubmitted: (_) => _sendMessage(),
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context)!.askAnything,
                  hintStyle: TextStyle(color: theme.hintColor),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Color(0xFFFB8C00),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    return "${time.hour}:${time.minute.toString().padLeft(2, '0')}";
  }
}

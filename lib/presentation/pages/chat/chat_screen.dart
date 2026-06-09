import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:ratnesh_gold_app/core/theme/app_colors.dart';
import 'package:ratnesh_gold_app/services/chat_service.dart';
import 'package:ratnesh_gold_app/utils/ContextExtensions.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String? _toolStatus;
  String _streamBuffer = '';
  bool _isStreaming = false;

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

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isStreaming) return;

    _controller.clear();
    setState(() {
      _isStreaming = true;
      _toolStatus = null;
      _streamBuffer = '';
    });
    _scrollToBottom();

    await for (final event in _chatService.sendMessageStream(text)) {
      if (!mounted) return;

      setState(() {
        switch (event.type) {
          case ChatEventType.toolCall:
            _toolStatus = event.label ?? event.tool;
            _scrollToBottom();
            break;
          case ChatEventType.textDelta:
            _toolStatus = null;
            _streamBuffer += event.content ?? '';
            _scrollToBottom();
            break;
          case ChatEventType.done:
          case ChatEventType.error:
            _toolStatus = null;
            break;
        }
      });
    }

    if (mounted) {
      setState(() {
        _isStreaming = false;
        _streamBuffer = '';
      });
      _scrollToBottom();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_chatService.isConfigured) {
      return Scaffold(
        backgroundColor: AppColors.pageBg,
        appBar: _buildAppBar(),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.settings_rounded, size: 64, color: AppColors.textMuted),
              SizedBox(height: context.getScreenHeight(2)),
              Text('Chat Not Configured', style: TextStyle(fontSize: context.getResponsiveSize(5), fontWeight: FontWeight.w700, color: AppColors.textDark)),
              SizedBox(height: context.getScreenHeight(1)),
              Text('Set AGENT_SERVER_URL in your .env file.', textAlign: TextAlign.center, style: TextStyle(fontSize: context.getResponsiveSize(3.5), color: AppColors.textMuted)),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.pageBg,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(
            child: _chatService.messages.isEmpty && !_isStreaming
                ? _buildWelcome()
                : _buildMessageList(),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: AppColors.pageBg,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_rounded, color: AppColors.textDark),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text('AI Assistant', style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w700, fontSize: context.getResponsiveSize(5))),
      actions: [
        IconButton(
          icon: Icon(Icons.delete_outline_rounded, color: AppColors.textMuted, size: context.getResponsiveSize(6)),
          onPressed: () => setState(() => _chatService.clearHistory()),
        ),
        SizedBox(width: context.getScreenWidth(2)),
      ],
    );
  }

  Widget _buildWelcome() {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(context.getScreenWidth(8)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(context.getScreenWidth(5)),
                decoration: BoxDecoration(color: AppColors.primaryGold.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: Icon(Icons.chat_bubble_outline_rounded, size: context.getResponsiveSize(12), color: AppColors.primaryGold),
              ),
              SizedBox(height: context.getScreenHeight(3)),
              Text('Arham Jewellers', style: TextStyle(fontSize: context.getResponsiveSize(6), fontWeight: FontWeight.w700, color: AppColors.textDark)),
              SizedBox(height: context.getScreenHeight(1)),
              Text('AI Shopping Assistant', style: TextStyle(fontSize: context.getResponsiveSize(4), color: AppColors.primaryGold, fontWeight: FontWeight.w600)),
              SizedBox(height: context.getScreenHeight(3)),
              _suggestionChip('Browse gold jewellery'),
              _suggestionChip('Check today\'s gold rate'),
              _suggestionChip('Track my orders'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _suggestionChip(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: context.getScreenHeight(1)),
      child: GestureDetector(
        onTap: () { _controller.text = text; _sendMessage(); },
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: context.getScreenWidth(4), vertical: context.getScreenHeight(1.2)),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.divider)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.auto_awesome_rounded, size: context.getResponsiveSize(4), color: AppColors.primaryGold),
              SizedBox(width: context.getScreenWidth(2)),
              Text(text, style: TextStyle(fontSize: context.getResponsiveSize(3.8), color: AppColors.textDark, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageList() {
    final messages = _chatService.messages;
    final msgCount = messages.length;
    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.symmetric(horizontal: context.getScreenWidth(4), vertical: context.getScreenHeight(1)),
      itemCount: msgCount + (_isStreaming ? 1 : 0) + (_toolStatus != null ? 1 : 0),
      itemBuilder: (context, index) {
        final totalMessages = msgCount;

        // Tool status line
        if (index == totalMessages) {
          if (_toolStatus != null) return _buildToolStatus(_toolStatus!);
          if (_isStreaming && _streamBuffer.isEmpty) return _buildTypingIndicator();
          if (_isStreaming && _streamBuffer.isNotEmpty) return _buildStreamBubble();
          return const SizedBox.shrink();
        }

        // Streaming bubble
        if (index == totalMessages + 1 && _isStreaming && _streamBuffer.isNotEmpty) {
          return _buildStreamBubble();
        }

        if (index >= msgCount) return const SizedBox.shrink();
        final msg = messages[index];
        return msg.role == 'user' ? _buildUserBubble(msg.content) : _buildAssistantBubble(msg.content);
      },
    );
  }

  Widget _buildToolStatus(String label) {
    return Padding(
      padding: EdgeInsets.only(bottom: context.getScreenHeight(0.8)),
      child: Row(
        children: [
          SizedBox(width: context.getScreenWidth(8)),
          SizedBox(
            width: context.getScreenWidth(3),
            height: context.getScreenWidth(3),
            child: CircularProgressIndicator(strokeWidth: 1.5, color: AppColors.primaryGold),
          ),
          SizedBox(width: context.getScreenWidth(2)),
          Text(label, style: TextStyle(fontSize: context.getResponsiveSize(3.2), color: AppColors.textMuted, fontStyle: FontStyle.italic)),
        ],
      ),
    );
  }

  Widget _buildStreamBubble() {
    return Padding(
      padding: EdgeInsets.only(bottom: context.getScreenHeight(1.5)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: AppColors.primaryGold.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(Icons.auto_awesome_rounded, size: context.getResponsiveSize(3.5), color: AppColors.primaryGold),
          ),
          SizedBox(width: context.getScreenWidth(2)),
          Flexible(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: context.getScreenWidth(4), vertical: context.getScreenHeight(1.5)),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(18), topRight: Radius.circular(18), bottomLeft: Radius.circular(4), bottomRight: Radius.circular(18)),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: MarkdownBody(
                data: _streamBuffer,
                selectable: true,
                styleSheet: MarkdownStyleSheet(
                  p: TextStyle(fontSize: context.getResponsiveSize(3.8), color: AppColors.textDark, height: 1.5),
                  code: TextStyle(fontSize: context.getResponsiveSize(3.5), color: AppColors.primaryGold, backgroundColor: AppColors.pageBg),
                  codeblockDecoration: BoxDecoration(color: AppColors.pageBg, borderRadius: BorderRadius.circular(8)),
                  tableHead: TextStyle(fontSize: context.getResponsiveSize(2.8), color: AppColors.textDark, fontWeight: FontWeight.w600, height: 1.4),
                  tableBody: TextStyle(fontSize: context.getResponsiveSize(2.8), color: AppColors.textDark, height: 1.4),
                  tableCellsPadding: EdgeInsets.symmetric(horizontal: context.getScreenWidth(1.5), vertical: context.getScreenHeight(0.4)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserBubble(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: context.getScreenHeight(1.5)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Flexible(
            child: GestureDetector(
              onLongPress: () => Clipboard.setData(ClipboardData(text: text)),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: context.getScreenWidth(4), vertical: context.getScreenHeight(1.5)),
                decoration: BoxDecoration(
                  color: AppColors.primaryGold,
                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(18), topRight: Radius.circular(18), bottomLeft: Radius.circular(18), bottomRight: Radius.circular(4)),
                ),
                child: Text(text, style: TextStyle(fontSize: context.getResponsiveSize(3.8), color: Colors.white, height: 1.5)),
              ),
            ),
          ),
          SizedBox(width: context.getScreenWidth(2)),
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: AppColors.primaryGold.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(Icons.person_rounded, size: context.getResponsiveSize(3.5), color: AppColors.primaryGold),
          ),
        ],
      ),
    );
  }

  Widget _buildAssistantBubble(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: context.getScreenHeight(1.5)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: AppColors.primaryGold.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(Icons.auto_awesome_rounded, size: context.getResponsiveSize(3.5), color: AppColors.primaryGold),
          ),
          SizedBox(width: context.getScreenWidth(2)),
          Flexible(
            child: GestureDetector(
              onLongPress: () {
                Clipboard.setData(ClipboardData(text: text));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Copied', style: TextStyle(fontSize: context.getResponsiveSize(3.2))), duration: const Duration(seconds: 1), behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                );
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: context.getScreenWidth(4), vertical: context.getScreenHeight(1.5)),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(18), topRight: Radius.circular(18), bottomLeft: Radius.circular(4), bottomRight: Radius.circular(18)),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
                ),
                child: MarkdownBody(
                  data: text,
                  selectable: true,
                  styleSheet: MarkdownStyleSheet(
                    p: TextStyle(fontSize: context.getResponsiveSize(3.8), color: AppColors.textDark, height: 1.5),
                    code: TextStyle(fontSize: context.getResponsiveSize(3.5), color: AppColors.primaryGold, backgroundColor: AppColors.pageBg),
                    codeblockDecoration: BoxDecoration(color: AppColors.pageBg, borderRadius: BorderRadius.circular(8)),
                    tableHead: TextStyle(fontSize: context.getResponsiveSize(2.8), color: AppColors.textDark, fontWeight: FontWeight.w600, height: 1.4),
                    tableBody: TextStyle(fontSize: context.getResponsiveSize(2.8), color: AppColors.textDark, height: 1.4),
                    tableCellsPadding: EdgeInsets.symmetric(horizontal: context.getScreenWidth(1.5), vertical: context.getScreenHeight(0.4)),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: EdgeInsets.only(bottom: context.getScreenHeight(1.5)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: AppColors.primaryGold.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(Icons.auto_awesome_rounded, size: context.getResponsiveSize(3.5), color: AppColors.primaryGold),
          ),
          SizedBox(width: context.getScreenWidth(2)),
          Container(
            padding: EdgeInsets.symmetric(horizontal: context.getScreenWidth(4), vertical: context.getScreenHeight(1.5)),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(18), topRight: Radius.circular(18), bottomLeft: Radius.circular(4), bottomRight: Radius.circular(18)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [_dot(0), SizedBox(width: 4), _dot(1), SizedBox(width: 4), _dot(2)]),
          ),
        ],
      ),
    );
  }

  Widget _dot(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 600 + (index * 200)),
      builder: (_, value, __) {
        return Container(width: 8, height: 8, decoration: BoxDecoration(color: AppColors.primaryGold.withValues(alpha: 0.3 + (value * 0.7)), shape: BoxShape.circle));
      },
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: context.getScreenWidth(4), vertical: context.getScreenHeight(1)),
      decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, -2))]),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(color: AppColors.pageBg, borderRadius: BorderRadius.circular(16)),
                child: TextField(
                  controller: _controller,
                  enabled: !_isStreaming,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendMessage(),
                  style: TextStyle(fontSize: context.getResponsiveSize(3.8), color: AppColors.textDark),
                  decoration: InputDecoration(
                    hintText: 'Ask about jewellery, gold rates...',
                    hintStyle: TextStyle(color: AppColors.textMuted, fontSize: context.getResponsiveSize(3.5)),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: context.getScreenWidth(4), vertical: context.getScreenHeight(1.5)),
                  ),
                ),
              ),
            ),
            SizedBox(width: context.getScreenWidth(2)),
            GestureDetector(
              onTap: _isStreaming ? null : _sendMessage,
              child: Container(
                padding: EdgeInsets.all(context.getScreenWidth(3)),
                decoration: BoxDecoration(color: _isStreaming ? AppColors.textMuted : AppColors.primaryGold, borderRadius: BorderRadius.circular(14)),
                child: Icon(Icons.send_rounded, color: Colors.white, size: context.getResponsiveSize(5)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

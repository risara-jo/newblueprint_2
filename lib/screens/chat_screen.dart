import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/project_provider.dart';
import '../models/project_model.dart';

class ChatScreen extends StatefulWidget {
  final String projectId;
  final String projectName;

  const ChatScreen({
    super.key,
    required this.projectId,
    required this.projectName,
  });

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Provider.of<ProjectProvider>(
        context,
        listen: false,
      ).loadProjectChat(widget.projectId);
      _scrollToBottom();
    });
  }

  Future<void> _sendMessage(String userInput) async {
    if (userInput.trim().isEmpty) return;

    final projectProvider = Provider.of<ProjectProvider>(
      context,
      listen: false,
    );

    setState(() => _isProcessing = true);

    await projectProvider.addMessage(
      projectId: widget.projectId,
      text: userInput,
      sender: "user",
    );

    _controller.clear();
    _scrollToBottom();

    try {
      String imageUrl = await projectProvider.generateFloorPlan(
        widget.projectId,
        userInput,
      );
    } catch (e) {
      await projectProvider.addMessage(
        projectId: widget.projectId,
        text: "❌ Error generating floor plan. Try again.",
        sender: "bot",
      );
    } finally {
      setState(() => _isProcessing = false);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF202123),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text.rich(
          TextSpan(
            text: 'Blue',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            children: [
              TextSpan(
                text: 'Print',
                style: TextStyle(color: Color(0xFF3E80D8)),
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Consumer<ProjectProvider>(
              builder: (context, projectProvider, _) {
                final project = projectProvider.projects.firstWhere(
                  (p) => p.id == widget.projectId,
                  orElse: () => ProjectModel.empty(),
                );

                if (project.messages.isEmpty) {
                  return const Center(
                    child: Text(
                      "No messages found.",
                      style: TextStyle(color: Colors.white70),
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  itemCount: project.messages.length,
                  itemBuilder: (context, index) {
                    var message = project.messages[index];
                    return _chatBubble(
                      sender: message["sender"] ?? "Unknown",
                      text: message["text"] ?? "",
                      imageUrl: message["image"] ?? "",
                    );
                  },
                );
              },
            ),
          ),
          _chatInputField(),
        ],
      ),
    );
  }

  Widget _chatBubble({
    required String sender,
    required String text,
    String? imageUrl,
  }) {
    bool isUser = sender == "user";
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment:
            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isUser ? Color(0xFF3E80D8) : Color(0xFF2A2B2E),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Text(
              text,
              style: TextStyle(fontSize: 16, color: Colors.white),
            ),
          ),
          if (imageUrl != null && imageUrl.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(child: CircularProgressIndicator());
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Icon(Icons.broken_image, color: Colors.red),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _chatInputField() {
    return Container(
      color: const Color(0xFF2A2B2E),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Describe your floor plan...",
                hintStyle: const TextStyle(color: Colors.white54),
                filled: true,
                fillColor: const Color(0xFF202123),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon:
                _isProcessing
                    ? const CircularProgressIndicator(
                      color: Color(0xFF3E80D8),
                      strokeWidth: 2,
                    )
                    : const Icon(Icons.send, color: Color(0xFF3E80D8)),
            onPressed:
                _isProcessing ? null : () => _sendMessage(_controller.text),
          ),
        ],
      ),
    );
  }
}

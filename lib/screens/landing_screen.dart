import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:siri_wave/siri_wave.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../widgets/drawer_menu.dart';
import '../screens/chat_screen.dart';
import '../providers/project_provider.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  final TextEditingController _textController = TextEditingController();
  bool _hasText = false;

  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  final IOS9SiriWaveformController _siriWaveController =
      IOS9SiriWaveformController();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final projectProvider = Provider.of<ProjectProvider>(
        context,
        listen: false,
      );
      if (projectProvider.projects.isEmpty) {
        projectProvider.fetchUserProjects();
      }
    });

    _textController.addListener(() {
      setState(() {
        _hasText = _textController.text.isNotEmpty;
      });
    });
  }

  void _startChat() async {
    String userInput = _textController.text.trim();
    if (userInput.isEmpty) return;

    final projectProvider = Provider.of<ProjectProvider>(
      context,
      listen: false,
    );

    String projectName = "Project \${projectProvider.projects.length + 1}";
    await projectProvider.addProjectAndMessage(projectName, userInput, null);

    var existingProject = await projectProvider.getProjectByName(projectName);

    if (existingProject != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => ChatScreen(
                projectId: existingProject.id,
                projectName: existingProject.name,
              ),
        ),
      );
    } else {
      print("❌ Error: Project not found after creation.");
    }
  }

  void _startVoiceInput() async {
    bool available = await _speech.initialize(
      onStatus: (status) {
        if (status == 'done') {
          setState(() {
            _isListening = false;
            _siriWaveController.amplitude = 0.0;
          });
        }
      },
      onError: (error) {
        print("Speech Error: \$error");
        setState(() {
          _isListening = false;
          _siriWaveController.amplitude = 0.0;
        });
      },
    );

    if (available) {
      setState(() {
        _isListening = true;
        _siriWaveController.amplitude = 1.0;
      });

      _speech.listen(
        onResult: (result) {
          setState(() {
            _textController.text = result.recognizedWords;
            _hasText = _textController.text.isNotEmpty;
          });
        },
      );
    } else {
      print("❌ Microphone not available");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF202123),
      drawer: DrawerMenu(
        onProjectSelected: (projectId) {
          final projectProvider = Provider.of<ProjectProvider>(
            context,
            listen: false,
          );
          final selectedProject = projectProvider.projects.firstWhere(
            (p) => p.id == projectId,
          );

          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => ChatScreen(
                    projectId: selectedProject.id,
                    projectName: selectedProject.name,
                  ),
            ),
          );
        },
      ),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Builder(
          builder:
              (context) => IconButton(
                icon: const Icon(Icons.menu, color: Colors.white),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
        ),
        title: const Text.rich(
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
        centerTitle: true,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 200),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.0),
            child: Text(
              "Hi there human, I’m Blu.\nYour personal house planing assistant.\n\nHow can I help you today?",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 22,
                color: Colors.white,
              ),
            ),
          ),
          const Spacer(),
          // Show Siri waveform only if _isListening is true
          if (_isListening)
            SiriWaveform.ios9(
              controller: _siriWaveController,
              options: const IOS9SiriWaveformOptions(
                height: 80,
                width: 500,
                showSupportBar: true,
              ),
            ),
          const SizedBox(height: 10),
          _chatInputField(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _chatInputField() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              style: const TextStyle(
                fontFamily: 'Poppins',
                color: Color.fromARGB(255, 255, 255, 255),
              ),
              controller: _textController,
              decoration: InputDecoration(
                hintText: "",
                filled: true,
                fillColor: const Color.fromARGB(255, 59, 59, 59),
                border: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(30)),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF0056A4), Color(0xFF3E80D8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  offset: const Offset(0, 3),
                  blurRadius: 6,
                ),
              ],
            ),
            child: IconButton(
              icon: Icon(
                _hasText ? Icons.send : Icons.mic,
                color: Colors.white,
              ),
              onPressed: _hasText ? _startChat : _startVoiceInput,
            ),
          ),
        ],
      ),
    );
  }
}

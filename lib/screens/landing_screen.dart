import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:siri_wave/siri_wave.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../widgets/gradient_background.dart';
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

  // 👇 New additions
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

  /// ✅ Start new chat
  void _startChat() async {
    String userInput = _textController.text.trim();
    if (userInput.isEmpty) return;

    final projectProvider = Provider.of<ProjectProvider>(
      context,
      listen: false,
    );

    String projectName = "Project ${projectProvider.projects.length + 1}";
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

  /// 🎤 Start voice input
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
        print("Speech Error: $error");
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
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
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
          title: const Text(
            "BluePrint",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          centerTitle: true,
        ),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 150),
            const Text(
              "Hi there! I'm Blu, your house planning assistant.\nHow can I help you today?",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, color: Colors.white),
            ),

            const Spacer(),

            // 🎙️ Siri Wave
            SiriWaveform.ios9(
              controller: _siriWaveController,
              options: const IOS9SiriWaveformOptions(
                height: 50,
                width: 300,
                showSupportBar: true,
              ),
            ),

            const SizedBox(height: 10),

            _chatInputField(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  /// 💬 Chat Input + Mic Button
  Widget _chatInputField() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              decoration: InputDecoration(
                hintText: "Describe your floor plan...",
                filled: true,
                fillColor: Colors.white,
                border: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(30)),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),

          FloatingActionButton(
            backgroundColor: Colors.blue.shade900,
            onPressed: _hasText ? _startChat : _startVoiceInput,
            child: Icon(_hasText ? Icons.send : Icons.mic, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

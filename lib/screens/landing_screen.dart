import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import '../widgets/voice_input_bar.dart';
import '../widgets/drawer_menu.dart';
import '../screens/chat_screen.dart';
import '../providers/project_provider.dart';
import '../theme.dart'; // ✅ Make sure AppColors is available

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
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
  }

  void _startChat(String userInput) async {
    if (userInput.trim().isEmpty) return;

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
              (_) => ChatScreen(
                projectId: existingProject.id,
                projectName: existingProject.name,
              ),
        ),
      );
    } else {
      print("❌ Error: Project not found after creation.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
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
                  (_) => ChatScreen(
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
                style: TextStyle(color: AppColors.primary),
              ),
            ],
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // ✅ Recolored Lottie Animation
          Lottie.asset(
            'assets/animations/landingscreenanimation.json',
            width: 300,
            height: 200,
            repeat: true,
            fit: BoxFit.contain,
            delegates: LottieDelegates(
              values: [
                ValueDelegate.color(
                  const ['**'], // Target all fills/strokes
                  value: AppColors.primary, // Replace orange with themed blue
                ),
                ValueDelegate.opacity(
                  const ['**'],
                  value: 255, // ensure full visibility for lines
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.0),
            child: Text(
              "Hi there human, I’m Blu.\nYour personal house planning assistant.\n\nHow can I help you today?",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 22,
                color: Colors.white,
              ),
            ),
          ),
          const Spacer(),
          VoiceInputBar(onSubmit: (userInput) => _startChat(userInput)),
        ],
      ),
    );
  }
}

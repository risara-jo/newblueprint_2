import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart'; // Import for SVG images
import '../providers/project_provider.dart';
import '../screens/user_settings.dart';
import '../screens/vendor_list_screen.dart';
import '../services/auth_service.dart';
import '../screens/chat_screen.dart';

class DrawerMenu extends StatelessWidget {
  final Function(String projectId)? onProjectSelected;

  const DrawerMenu({super.key, this.onProjectSelected});

  @override
  Widget build(BuildContext context) {
    return Consumer<ProjectProvider>(
      builder: (context, projectProvider, _) {
        final authService = Provider.of<AuthService>(context);
        final user = authService.currentUser;

        return Drawer(
          backgroundColor: const Color(
            0xFF202123,
          ), // Dark background color to match LandingScreen
          child: Column(
            children: [
              const SizedBox(height: 40),

              // Grouped New Project and Professionals Buttons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // New Project Button with SVG icon
                    _drawerItem(
                      null, // No Icon
                      "New Project",
                      const Color(
                        0xFF3E80D8,
                      ), // Adjust blue color to match the screen
                      () async {
                        String projectName =
                            "Project ${projectProvider.projects.length + 1}";

                        await projectProvider.addProjectAndMessage(
                          projectName,
                          "New project created",
                          null,
                        );

                        if (onProjectSelected != null) {
                          final newProject = await projectProvider
                              .getProjectByName(projectName);
                          if (newProject != null) {
                            onProjectSelected!(newProject.id);
                          }
                        }
                      },
                      svgAsset:
                          'assets/icons/newproject.svg', // SVG asset for the button
                      iconSize: 25, // Size for the New Project icon
                      buttonHeight: 50, // Adjustable button height
                    ),

                    // Professionals Button with SVG icon
                    _drawerItem(
                      null, // No default Icon
                      "Professionals",
                      const Color(0xFF3E80D8),
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => VendorListScreen(),
                          ),
                        );
                      },
                      svgAsset:
                          'assets/icons/professionals.svg', // Updated SVG asset
                      iconSize: 20, // Size for the Professionals icon
                      buttonHeight: 50, // Adjustable button height
                    ),
                  ],
                ),
              ),

              const Divider(),

              Expanded(
                child:
                    projectProvider.projects.isEmpty
                        ? const Center(child: Text("No projects found."))
                        : ListView.builder(
                          itemCount: projectProvider.projects.length,
                          itemBuilder: (context, index) {
                            final project = projectProvider.projects[index];
                            return Card(
                              color: const Color(
                                0xFF2C2C2E,
                              ), // Card color to match
                              margin: const EdgeInsets.symmetric(
                                vertical: 5,
                                horizontal: 10,
                              ),
                              elevation: 5,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                ),
                                title: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        project.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'Poppins',
                                          color: Colors.white, // White text
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        PopupMenuButton<String>(
                                          onSelected: (value) {
                                            if (value == 'rename') {
                                              _showRenameDialog(
                                                context,
                                                project.id,
                                                project.name,
                                              );
                                            }
                                          },
                                          itemBuilder:
                                              (context) => [
                                                const PopupMenuItem(
                                                  value: 'rename',
                                                  child: Text("Rename"),
                                                ),
                                              ],
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.delete,
                                            color: Colors.red,
                                            size:
                                                18, // Adjustable delete button icon size
                                          ),
                                          onPressed: () async {
                                            // TODO: Implement delete functionality
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                onTap: () async {
                                  Navigator.pop(context); // Close drawer
                                  await projectProvider.loadProjectChat(
                                    project.id,
                                  );
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) => ChatScreen(
                                            projectId: project.id,
                                            projectName: project.name,
                                          ),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
              ),

              const Divider(),

              ListTile(
                leading: CircleAvatar(
                  radius: 22,
                  backgroundColor: Colors.blue.shade100,
                  child: const Icon(Icons.person, color: Colors.blue, size: 28),
                ),
                title: Text(
                  user?.email ?? "Guest",
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'Poppins',
                  ),
                ),
                trailing: const Icon(Icons.more_horiz, color: Colors.white),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const UserSettingsScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  // Updated drawerItem to allow for SVG asset, icon size, and button height customization
  Widget _drawerItem(
    IconData? icon,
    String title,
    Color color,
    VoidCallback onTap, {
    String? svgAsset,
    double? iconSize, // New parameter for icon size
    double? buttonHeight, // New parameter for button height
  }) {
    return ListTile(
      leading:
          svgAsset != null
              ? SvgPicture.asset(
                svgAsset,
                width:
                    iconSize ?? 24, // Use provided icon size or default to 24
                height: iconSize ?? 24, // Same height for the icon
                color: color,
              )
              : Icon(icon, color: color),
      title: Text(
        title,
        style: const TextStyle(color: Colors.white, fontFamily: 'Poppins'),
      ),
      onTap: onTap,
    );
  }

  void _showRenameDialog(
    BuildContext context,
    String projectId,
    String currentName,
  ) {
    final TextEditingController _controller = TextEditingController(
      text: currentName,
    );

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Rename Project"),
            content: TextField(
              controller: _controller,
              decoration: const InputDecoration(labelText: "New project name"),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () async {
                  final newName = _controller.text.trim();
                  if (newName.isNotEmpty) {
                    await Provider.of<ProjectProvider>(
                      context,
                      listen: false,
                    ).renameProject(projectId, newName);
                    Navigator.pop(context);
                  }
                },
                child: const Text("Rename"),
              ),
            ],
          ),
    );
  }
}

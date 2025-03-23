import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../providers/project_provider.dart';
import '../screens/user_settings.dart'; // ✅ Uses UserSettingsScreen now
import '../screens/vendor_list_screen.dart';
import '../screens/community_gallery_screen.dart';
import '../screens/chat_screen.dart';
import '../services/auth_service.dart';
import '../theme.dart';

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
          backgroundColor: AppColors.background,
          child: Column(
            children: [
              const SizedBox(height: 40),

              // 🔹 Action Buttons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  children: [
                    _drawerItem(
                      null,
                      "New Project",
                      AppColors.primary,
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
                          if (newProject != null)
                            onProjectSelected!(newProject.id);
                        }
                      },
                      svgAsset: 'assets/icons/newproject.svg',
                      iconSize: 24,
                    ),
                    _drawerItem(
                      null,
                      "Professionals",
                      AppColors.primary,
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const VendorListScreen(),
                          ),
                        );
                      },
                      svgAsset: 'assets/icons/professionals.svg',
                      iconSize: 22,
                    ),
                    _drawerItem(
                      null,
                      "Community Gallery",
                      AppColors.primary,
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CommunityGalleryScreen(),
                          ),
                        );
                      },
                      svgAsset: 'assets/icons/gallery.svg',
                      iconSize: 22,
                    ),
                  ],
                ),
              ),

              const Divider(),

              // 🔹 Project List
              Expanded(
                child:
                    projectProvider.projects.isEmpty
                        ? const Center(
                          child: Text(
                            "No projects found.",
                            style: TextStyle(color: AppColors.white70),
                          ),
                        )
                        : ListView.builder(
                          itemCount: projectProvider.projects.length,
                          itemBuilder: (context, index) {
                            final project = projectProvider.projects[index];
                            return Card(
                              color: const Color(0xFF2C2C2E),
                              margin: const EdgeInsets.symmetric(
                                vertical: 5,
                                horizontal: 10,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                title: Text(
                                  project.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontFamily: 'Poppins',
                                    color: Colors.white,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.edit,
                                        size: 20,
                                        color: Colors.white70,
                                      ),
                                      onPressed:
                                          () => _showRenameDialog(
                                            context,
                                            project.id,
                                            project.name,
                                          ),
                                      tooltip: "Rename Project",
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete_forever,
                                        color: Colors.red,
                                        size: 20,
                                      ),
                                      onPressed:
                                          () => _confirmDelete(
                                            context,
                                            projectProvider,
                                            project.id,
                                          ),
                                      tooltip: "Delete Project",
                                    ),
                                  ],
                                ),
                                onTap: () async {
                                  Navigator.pop(context);
                                  await projectProvider.loadProjectChat(
                                    project.id,
                                  );
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (_) => ChatScreen(
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

              // 🔹 Footer - User Info
              ListTile(
                leading: CircleAvatar(
                  radius: 22,
                  backgroundColor: AppColors.primary.withOpacity(0.2),
                  child: const Icon(Icons.person, color: AppColors.primary),
                ),
                title: Text(
                  user?.email ?? "Guest",
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'Poppins',
                  ),
                ),
                trailing: const Icon(Icons.settings, color: Colors.white),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const UserSettingsScreen(),
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

  Widget _drawerItem(
    IconData? icon,
    String title,
    Color color,
    VoidCallback onTap, {
    String? svgAsset,
    double? iconSize,
  }) {
    return ListTile(
      leading:
          svgAsset != null
              ? SvgPicture.asset(
                svgAsset,
                width: iconSize ?? 24,
                height: iconSize ?? 24,
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

  void _confirmDelete(
    BuildContext context,
    ProjectProvider provider,
    String projectId,
  ) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text("Delete Project"),
            content: const Text(
              "Are you sure you want to delete this project? This action cannot be undone.",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () async {
                  await provider.deleteProject(projectId);
                  Navigator.pop(context);
                },
                child: const Text("Delete"),
              ),
            ],
          ),
    );
  }
}

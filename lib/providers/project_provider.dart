import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/project_model.dart';

class ProjectProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  List<ProjectModel> _projects = [];
  ProjectModel? _currentProject;

  List<ProjectModel> get projects => _projects;
  ProjectModel? get currentProject => _currentProject;

  Future<void> fetchUserProjects() async {
    String? userId = _auth.currentUser?.uid;
    if (userId == null) {
      print("❌ [fetchUserProjects] No user found!");
      return;
    }

    try {
      final snapshot =
          await _firestore
              .collection("users")
              .doc(userId)
              .collection("projects")
              .orderBy("timestamp", descending: true)
              .get();

      _projects =
          snapshot.docs.map((doc) => ProjectModel.fromFirestore(doc)).toList();
      notifyListeners();
    } catch (e) {
      print("❌ [fetchUserProjects] Error: $e");
    }
  }

  Future<ProjectModel?> getProjectByName(String projectName) async {
    String? userId = _auth.currentUser?.uid;
    if (userId == null) return null;

    final querySnapshot =
        await _firestore
            .collection("users")
            .doc(userId)
            .collection("projects")
            .where("name", isEqualTo: projectName)
            .limit(1)
            .get();

    if (querySnapshot.docs.isNotEmpty) {
      return ProjectModel.fromFirestore(querySnapshot.docs.first);
    } else {
      return null;
    }
  }

  Future<String> generateFloorPlan(String projectId, String prompt) async {
    try {
      final response = await http.post(
        Uri.parse("http://10.0.2.2:8000/generate-plan"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"prompt": prompt}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String localUrl = "http://10.0.2.2:8000" + data["image_url"];

        final tempDir = Directory.systemTemp;
        final filePath =
            "${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.png";
        final imageFile = File(filePath);
        final imageBytes = await http.readBytes(Uri.parse(localUrl));
        await imageFile.writeAsBytes(imageBytes);

        String firebaseUrl = await uploadImageToFirebase(projectId, imageFile);

        await addMessage(
          projectId: projectId,
          text: "Here is your generated floor plan.",
          sender: "bot",
          imageUrl: firebaseUrl,
        );

        return firebaseUrl;
      } else {
        throw Exception("❌ Backend error: ${response.body}");
      }
    } catch (e) {
      print("❌ [generateFloorPlan] Error: $e");
      throw Exception("Failed to generate floor plan");
    }
  }

  Future<void> addMessage({
    required String projectId,
    required String text,
    required String sender,
    String? imageUrl,
  }) async {
    String? userId = _auth.currentUser?.uid;
    if (userId == null) return;

    final projectRef = _firestore
        .collection("users")
        .doc(userId)
        .collection("projects")
        .doc(projectId);

    try {
      await projectRef.collection("messages").add({
        "text": text,
        "sender": sender,
        "image": imageUrl ?? "",
        "timestamp": FieldValue.serverTimestamp(),
      });

      await loadProjectChat(projectId);
    } catch (e) {
      print("❌ [addMessage] Error: $e");
    }
  }

  Future<void> loadProjectChat(String projectId) async {
    String? userId = _auth.currentUser?.uid;
    if (userId == null) return;

    final projectRef = _firestore
        .collection("users")
        .doc(userId)
        .collection("projects")
        .doc(projectId)
        .collection("messages");

    try {
      final snapshot = await projectRef.orderBy("timestamp").get();

      final project = _projects.firstWhere(
        (p) => p.id == projectId,
        orElse: () => ProjectModel.empty(),
      );

      if (project.id.isNotEmpty) {
        project.messages =
            snapshot.docs
                .map(
                  (doc) => {
                    "text": doc["text"] ?? "",
                    "sender": doc["sender"] ?? "Unknown",
                    "image":
                        doc.data().containsKey("image") ? doc["image"] : "",
                    "timestamp":
                        doc["timestamp"] ?? FieldValue.serverTimestamp(),
                  },
                )
                .toList();

        notifyListeners();
      }
    } catch (e) {
      print("❌ [loadProjectChat] Error: $e");
    }
  }

  Future<String> uploadImageToFirebase(String projectId, File imageFile) async {
    String? userId = _auth.currentUser?.uid;
    if (userId == null || !imageFile.existsSync()) return "";

    try {
      String filePath =
          "users/$userId/projects/$projectId/${DateTime.now().millisecondsSinceEpoch}.png";
      UploadTask uploadTask = _storage.ref(filePath).putFile(imageFile);
      TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print("❌ [uploadImageToFirebase] Error: $e");
      return "";
    }
  }

  Future<void> addProjectAndMessage(
    String projectName,
    String promptText,
    File? imageFile,
  ) async {
    String? userId = _auth.currentUser?.uid;
    if (userId == null) return;

    await fetchUserProjects();
    ProjectModel? existingProject = await getProjectByName(projectName);

    String projectId;
    if (existingProject != null) {
      projectId = existingProject.id;
    } else {
      final projectRef =
          _firestore
              .collection("users")
              .doc(userId)
              .collection("projects")
              .doc();
      projectId = projectRef.id;

      await projectRef.set({
        "id": projectId,
        "userId": userId,
        "name": projectName,
        "messages": [],
        "images": [],
        "timestamp": FieldValue.serverTimestamp(),
      });

      await fetchUserProjects();
    }

    await addMessage(projectId: projectId, text: promptText, sender: "user");
  }

  Future<void> renameProject(String projectId, String newName) async {
    String? userId = _auth.currentUser?.uid;
    if (userId == null) return;

    final projectRef = _firestore
        .collection("users")
        .doc(userId)
        .collection("projects")
        .doc(projectId);

    try {
      await projectRef.update({"name": newName});
      await fetchUserProjects();
    } catch (e) {
      print("❌ [renameProject] Error: $e");
    }
  }

  Future<void> deleteProject(String projectId) async {
    String? userId = _auth.currentUser?.uid;
    if (userId == null) return;

    try {
      // Delete messages
      final messagesSnapshot =
          await _firestore
              .collection("users")
              .doc(userId)
              .collection("projects")
              .doc(projectId)
              .collection("messages")
              .get();

      for (var doc in messagesSnapshot.docs) {
        await doc.reference.delete();
      }

      // Delete project
      await _firestore
          .collection("users")
          .doc(userId)
          .collection("projects")
          .doc(projectId)
          .delete();

      _projects.removeWhere((p) => p.id == projectId);
      notifyListeners();
    } catch (e) {
      print("❌ [deleteProject] Error: $e");
    }
  }

  Future<void> shareToGallery({
    required String projectId,
    required String imageUrl,
    required String prompt,
    required String userName,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .get();

        String firstName = userDoc.data()?['first_name'] ?? 'Anonymous';
        String lastName = userDoc.data()?['last_name'] ?? '';
        String finalUserName = '$firstName $lastName';

        String userImage = user.photoURL ?? "https://default-image-url";

        await FirebaseFirestore.instance.collection('community_gallery').add({
          'userName': finalUserName,
          'imageUrl': imageUrl,
          'prompt': prompt,
          'userImage': userImage,
          'timestamp': FieldValue.serverTimestamp(),
        });

        print("✅ [shareToGallery] Shared to community gallery");
      }
    } catch (e) {
      print("❌ [shareToGallery] Error: $e");
    }
  }

  Future<String?> createProjectFromCommunityPrompt(String prompt) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    final newProjectRef =
        FirebaseFirestore.instance
            .collection("users")
            .doc(user.uid)
            .collection("projects")
            .doc();

    final projectId = newProjectRef.id;

    await newProjectRef.set({
      "id": projectId,
      "userId": user.uid,
      "name": "Community Prompt",
      "messages": [],
      "images": [],
      "timestamp": FieldValue.serverTimestamp(),
    });

    await fetchUserProjects();

    return projectId;
  }
}

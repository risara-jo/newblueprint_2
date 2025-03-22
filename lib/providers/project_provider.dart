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

  /// ✅ **Fetch all projects for the logged-in user**
  Future<void> fetchUserProjects() async {
    String? userId = _auth.currentUser?.uid;

    print("🔄 [fetchUserProjects] Fetching projects for user: $userId");

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

  /// ✅ **Get project by name**
  Future<ProjectModel?> getProjectByName(String projectName) async {
    String? userId = _auth.currentUser?.uid;

    print("🔍 [getProjectByName] Searching for project: $projectName");

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
      print("⚠️ [getProjectByName] No project found with name '$projectName'.");
      return null;
    }
  }

  /// ✅ **Generate a Floor Plan (Fixed API Call)**

  Future<String> generateFloorPlan(String projectId, String prompt) async {
    try {
      print("🔄 [generateFloorPlan] Sending request to backend for: $prompt");

      final response = await http.post(
        Uri.parse("http://10.0.2.2:8000/generate-plan"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"prompt": prompt}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String localUrl = "http://10.0.2.2:8000" + data["image_url"];
        print("✅ [generateFloorPlan] Image URL received: $localUrl");

        // Download the image to a temp file
        final tempDir = Directory.systemTemp;
        final filePath =
            "${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.png";
        final imageFile = File(filePath);
        final imageBytes = await http.readBytes(Uri.parse(localUrl));
        await imageFile.writeAsBytes(imageBytes);

        // Upload to Firebase
        String firebaseUrl = await uploadImageToFirebase(projectId, imageFile);

        // Save bot message with Firebase image URL
        await addMessage(
          projectId: projectId,
          text: "Here is your generated floor plan.",
          sender: "bot",
          imageUrl: firebaseUrl,
        );

        return firebaseUrl;
      } else {
        throw Exception("❌ Backend returned an error: ${response.body}");
      }
    } catch (e) {
      print("❌ [generateFloorPlan] Error: $e");
      throw Exception("Failed to generate floor plan");
    }
  }

  /// ✅ **Add Message to Firestore**
  Future<void> addMessage({
    required String projectId,
    required String text,
    required String sender,
    String? imageUrl,
  }) async {
    String? userId = _auth.currentUser?.uid;

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

      print("✅ [addMessage] Message saved!");
      await loadProjectChat(projectId);
    } catch (e) {
      print("❌ [addMessage] Error: $e");
    }
  }

  /// ✅ **Load Project Chat Messages**
  Future<void> loadProjectChat(String projectId) async {
    String? userId = _auth.currentUser?.uid;

    final projectRef = _firestore
        .collection("users")
        .doc(userId)
        .collection("projects")
        .doc(projectId)
        .collection("messages");

    try {
      final snapshot =
          await projectRef
              .orderBy("timestamp", descending: false) // ✅ Ensure correct order
              .get();

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
        print(
          "✅ [loadProjectChat] Loaded ${project.messages.length} messages.",
        );
      } else {
        print("⚠️ [loadProjectChat] No valid project found!");
      }
    } catch (e) {
      print("❌ [loadProjectChat] Error: $e");
    }
  }

  /// ✅ **Upload Image to Firebase Storage**
  Future<String> uploadImageToFirebase(String projectId, File imageFile) async {
    String? userId = _auth.currentUser?.uid;

    if (!imageFile.existsSync()) {
      print("❌ [uploadImageToFirebase] Error: File does not exist.");
      return "";
    }

    try {
      String filePath =
          "users/$userId/projects/$projectId/${DateTime.now().millisecondsSinceEpoch}.png";
      UploadTask uploadTask = _storage.ref(filePath).putFile(imageFile);
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();
      print("✅ [uploadImageToFirebase] Image uploaded: $downloadUrl");
      return downloadUrl;
    } catch (e) {
      print("❌ [uploadImageToFirebase] Error: $e");
      return "";
    }
  }

  /// ✅ **Create Project if Not Exists & Add Message**
  Future<void> addProjectAndMessage(
    String projectName,
    String promptText,
    File? imageFile,
  ) async {
    String? userId = _auth.currentUser?.uid;

    print(
      "✅ [addProject] Checking if project '$projectName' exists for user: $userId",
    );

    await fetchUserProjects();
    ProjectModel? existingProject = await getProjectByName(projectName);

    String projectId;
    if (existingProject != null) {
      projectId = existingProject.id;
      print("✅ [addProject] Project '$projectName' already exists.");
    } else {
      print("🆕 [addProject] Creating new project: '$projectName'");

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

      print("✅ [addProject] Project '$projectName' created.");
      await fetchUserProjects();
    }

    await addMessage(projectId: projectId, text: promptText, sender: "user");
  }

  // ... [previous content assumed to be unchanged]

  /// ✅ Rename an existing project
  Future<void> renameProject(String projectId, String newName) async {
    String? userId = _auth.currentUser?.uid;

    final projectRef = _firestore
        .collection("users")
        .doc(userId)
        .collection("projects")
        .doc(projectId);

    try {
      await projectRef.update({"name": newName});
      print("✅ [renameProject] Renamed to \$newName");
      await fetchUserProjects(); // refresh the list
    } catch (e) {
      print("❌ [renameProject] Error: \$e");
    }
  }
}

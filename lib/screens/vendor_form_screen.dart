import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import '../theme.dart';

class VendorFormScreen extends StatefulWidget {
  const VendorFormScreen({super.key});

  @override
  _VendorFormScreenState createState() => _VendorFormScreenState();
}

class _VendorFormScreenState extends State<VendorFormScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _specializationController = TextEditingController();
  final _service1Controller = TextEditingController();
  final _service2Controller = TextEditingController();
  final _service3Controller = TextEditingController();

  bool _locationEnabled = false;
  Position? _currentPosition;
  File? _image;
  bool _isSubmitting = false;

  Future<void> _getLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      if (permission == LocationPermission.deniedForever) return;

      _currentPosition = await Geolocator.getCurrentPosition();
      setState(() {});
    } catch (e) {
      print("🔥 Location Error: $e");
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<String> _uploadImage(File imageFile, String vendorId) async {
    try {
      Reference ref = FirebaseStorage.instance.ref().child(
        "vendors/$vendorId.jpg",
      );
      await ref.putFile(imageFile);
      return await ref.getDownloadURL();
    } catch (e) {
      print("🔥 Error uploading image: $e");
      return "";
    }
  }

  Future<String> _getNewVendorId() async {
    try {
      QuerySnapshot snapshot =
          await FirebaseFirestore.instance.collection("vendors").get();
      int nextId = snapshot.docs.length + 1;
      return "vendorId$nextId";
    } catch (e) {
      print("🔥 Error generating Vendor ID: $e");
      return "vendorId999";
    }
  }

  Future<void> _submitForm() async {
    if (_nameController.text.isEmpty || _phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Vendor Name and Phone are required."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    String? userId = FirebaseAuth.instance.currentUser?.uid;
    String vendorId = await _getNewVendorId();
    String imageUrl =
        _image != null ? await _uploadImage(_image!, vendorId) : "";

    List<String> services =
        [
          _service1Controller.text,
          _service2Controller.text,
          _service3Controller.text,
        ].where((s) => s.isNotEmpty).toList();

    Map<String, dynamic> vendorData = {
      "name": _nameController.text,
      "phone": _phoneController.text,
      "whatsapp": _whatsappController.text,
      "specialization": _specializationController.text,
      "description": _descriptionController.text,
      "services": services,
      "latitude":
          _locationEnabled && _currentPosition != null
              ? _currentPosition!.latitude
              : null,
      "longitude":
          _locationEnabled && _currentPosition != null
              ? _currentPosition!.longitude
              : null,
      "imageUrl": imageUrl,
      "ownerId": userId,
    };

    try {
      await FirebaseFirestore.instance
          .collection("vendors")
          .doc(vendorId)
          .set(vendorData);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Advertisement Submitted Successfully!"),
          backgroundColor: Colors.green,
        ),
      );
      _resetForm();
    } catch (e) {
      print("🔥 Firestore Write Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Error submitting advertisement."),
          backgroundColor: Colors.red,
        ),
      );
    }

    setState(() => _isSubmitting = false);
  }

  void _resetForm() {
    _nameController.clear();
    _phoneController.clear();
    _whatsappController.clear();
    _specializationController.clear();
    _descriptionController.clear();
    _service1Controller.clear();
    _service2Controller.clear();
    _service3Controller.clear();
    setState(() {
      _image = null;
      _currentPosition = null;
      _locationEnabled = false;
    });
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: AppColors.textHint),
      filled: true,
      fillColor: AppColors.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          "Vendor Registration",
          style: TextStyle(color: AppColors.white),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _image != null
                ? CircleAvatar(backgroundImage: FileImage(_image!), radius: 50)
                : const CircleAvatar(radius: 50, child: Icon(Icons.camera_alt)),
            TextButton(onPressed: _pickImage, child: const Text("Pick Image")),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration("Vendor Name"),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _phoneController,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration("Phone"),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _whatsappController,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration("WhatsApp"),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _specializationController,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration("Specialization"),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descriptionController,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration("Description"),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _service1Controller,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration("Service 1 (Optional)"),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _service2Controller,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration("Service 2 (Optional)"),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _service3Controller,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration("Service 3 (Optional)"),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Checkbox(
                  value: _locationEnabled,
                  onChanged:
                      (value) => setState(() => _locationEnabled = value!),
                ),
                const Text(
                  "Allow Location",
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
            ElevatedButton(
              onPressed: _getLocation,
              child: const Text("Get Location"),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submitForm,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child:
                  _isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                        "Submit Advertisement",
                        style: TextStyle(color: Colors.white),
                      ),
            ),
          ],
        ),
      ),
    );
  }
}

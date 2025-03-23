import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'vendor_details_screen.dart';
import 'vendor_form_screen.dart';
import '../theme.dart';

class VendorListScreen extends StatefulWidget {
  const VendorListScreen({super.key});

  @override
  _VendorListScreenState createState() => _VendorListScreenState();
}

class _VendorListScreenState extends State<VendorListScreen> {
  String searchQuery = "";
  bool showFavorites = false;
  List<DocumentSnapshot> vendors = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text.rich(
          TextSpan(
            text: 'Blue',
            style: TextStyle(
              color: AppColors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
            children: [
              TextSpan(
                text: 'Print',
                style: TextStyle(color: AppColors.primary),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppColors.primary),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const VendorFormScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search, color: AppColors.textHint),
                hintText: "Search...",
                hintStyle: const TextStyle(color: AppColors.textHint),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (query) {
                setState(() {
                  searchQuery = query.toLowerCase();
                });
              },
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              "Connect with trusted architects, skilled contractors, and premium material suppliers.",
              style: TextStyle(fontSize: 14, color: AppColors.white70),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Row(
              children: [
                _buildTab("All", !showFavorites),
                _buildTab("Favorites", showFavorites),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance.collection('vendors').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return const Center(child: CircularProgressIndicator());

                vendors =
                    snapshot.data!.docs.where((doc) {
                      var data = doc.data() as Map<String, dynamic>;
                      return data['name'].toString().toLowerCase().contains(
                        searchQuery,
                      );
                    }).toList();

                return ListView.builder(
                  itemCount: vendors.length,
                  itemBuilder: (context, index) {
                    return _buildVendorCard(vendors[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(String title, bool isSelected) {
    return GestureDetector(
      onTap: () => setState(() => showFavorites = title == "Favorites"),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? AppColors.white : AppColors.textHint,
          ),
        ),
      ),
    );
  }

  Widget _buildVendorCard(DocumentSnapshot vendor) {
    var data = vendor.data() as Map<String, dynamic>;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              data['imageUrl'] ?? "https://via.placeholder.com/100",
              width: 80,
              height: 80,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data['name'],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppColors.white,
                  ),
                ),
                Text(
                  data['specialization'],
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.white70,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (_) => VendorDetailsScreen(
                        name: data['name'],
                        specialization: data['specialization'],
                        phone: data['phone'],
                        whatsapp: data['whatsapp'],
                        description: data['description'],
                        services: List<String>.from(data['services']),
                        imageUrl: data['imageUrl'],
                      ),
                ),
              );
            },
            child: const Text("Contact"),
          ),
        ],
      ),
    );
  }
}

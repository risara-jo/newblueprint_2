import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme.dart';

class VendorDetailsScreen extends StatelessWidget {
  final String name;
  final String specialization;
  final String phone;
  final String whatsapp;
  final String description;
  final List<String> services;
  final String imageUrl;

  const VendorDetailsScreen({
    super.key,
    required this.name,
    required this.specialization,
    required this.phone,
    required this.whatsapp,
    required this.description,
    required this.services,
    required this.imageUrl,
  });

  void _contactVendor() async {
    final Uri phoneUri = Uri.parse('tel:$phone');
    final Uri whatsappUri = Uri.parse('https://wa.me/$whatsapp');

    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else if (await canLaunchUrl(whatsappUri)) {
      await launchUrl(whatsappUri);
    } else {
      print("❌ Could not launch contact methods.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 50),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: AppColors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Text.rich(
                    TextSpan(
                      text: 'Blue',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.white,
                      ),
                      children: [
                        TextSpan(
                          text: 'Print',
                          style: TextStyle(color: AppColors.primary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundImage: NetworkImage(imageUrl),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.white,
                          ),
                        ),
                        Text(
                          specialization,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(
                      Icons.favorite_border,
                      color: AppColors.primary,
                    ),
                    label: const Text(
                      "Add to favourite",
                      style: TextStyle(color: AppColors.primary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                "About the Architect",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.white,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                description,
                style: const TextStyle(fontSize: 14, color: AppColors.white70),
              ),
              const SizedBox(height: 15),
              const Text(
                "Services provide",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.white,
                ),
              ),
              const SizedBox(height: 5),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children:
                    services
                        .map(
                          (service) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.check,
                                  color: AppColors.primary,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  service,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: AppColors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _contactVendor,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    "Contact",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

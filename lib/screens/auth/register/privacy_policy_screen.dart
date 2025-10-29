import 'package:flutter/material.dart';
import 'package:pipze/constants/color.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.whiteColor,
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        backgroundColor: AppColors.whiteColor,
      ),
      body: const Padding(
        padding: EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Privacy Policy',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              Text(
                'This is a placeholder for the privacy policy content. You can replace this with your actual privacy policy text.',
                style: TextStyle(fontSize: 16),
              ),
              // Add more privacy policy content here
            ],
          ),
        ),
      ),
    );
  }
}
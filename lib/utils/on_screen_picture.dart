import 'package:flutter/material.dart';

class OnScreenPicture extends StatelessWidget {
  final String profilePicUrl;

  const OnScreenPicture({super.key, required this.profilePicUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Picture'),
      ),
      body: Center(
        child: profilePicUrl.isNotEmpty
            ? Image.network(profilePicUrl) // Display the image if URL is available
            : const Icon(Icons.person, size: 100), // Default icon if no image
      ),
    );
  }
}

import 'package:flutter/material.dart';

class HeaderWidget extends StatelessWidget {
  final String schoolName;
  final String schoolAddress;
  final String email;
  final String website;
  final String badgePath;
  final String profilePhotoPath;

  const HeaderWidget({
    super.key,
    required this.schoolName,
    required this.schoolAddress,
    required this.email,
    required this.website,
    required this.badgePath,
    required this.profilePhotoPath,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset(badgePath, height: 50, width: 50),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                schoolName,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Text(
                schoolAddress,
                textAlign: TextAlign.center,
              ),
              Text(email),
              Text(website),
            ],
          ),
        ),
        const SizedBox(width: 20),
        Image.asset(profilePhotoPath, height: 50, width: 50),
      ],
    );
  }
}

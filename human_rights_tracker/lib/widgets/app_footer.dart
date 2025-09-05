import 'package:flutter/material.dart';

class AppFooter extends StatelessWidget {
  const AppFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 28), // ✅ adds 28px space below
      child: Container(
        padding: const EdgeInsets.all(16),
        color: const Color(0xFF0A1628),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '© 2025 RightsTrack. All rights reserved.',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            Row(
              children: [
                Text(
                  'Privacy Policy',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
                SizedBox(width: 16),
                Text(
                  'Terms of Service',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

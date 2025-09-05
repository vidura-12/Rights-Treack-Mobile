import 'package:flutter/material.dart';

class MediaPage extends StatefulWidget {
  const MediaPage({Key? key}) : super(key: key);

  @override
  State<MediaPage> createState() => _MediaPageState();
}

class _MediaPageState extends State<MediaPage> {
  // TODO: Add controllers and Firebase logic for uploading media and comments

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Media'),
        backgroundColor: theme.colorScheme.primary,
      ),
      body: Column(
        children: [
          // Upload section
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // TODO: Add image/video picker
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Description',
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () {
                      // TODO: Upload media logic
                    },
                    child: const Text('Upload'),
                  ),
                ],
              ),
            ),
          ),
          // Media feed section
          Expanded(
            child: ListView(
              children: [
                // TODO: Display uploaded media and comments
                ListTile(
                  leading: Icon(Icons.image, color: theme.colorScheme.primary),
                  title: const Text('Sample Media'),
                  subtitle: const Text('Description here'),
                  onTap: () {
                    // TODO: Show media details and comments
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        ListTile(
          leading: Icon(Icons.dark_mode),
          title: Text('Dark mode (coming soon)'),
        ),
        ListTile(
          leading: Icon(Icons.lock),
          title: Text('Change password (coming soon)'),
        ),
        ListTile(
          leading: Icon(Icons.info),
          title: Text('About SnapDiet'),
          subtitle: Text('Uni prototype'),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import '../tabs/camera_tab.dart';
import '../tabs/upload_tab.dart';
import '../tabs/profile_tab.dart';
import '../tabs/settings_tab.dart';
import 'login_page.dart';

class HomePage extends StatefulWidget {
  final String email;
  const HomePage({super.key, required this.email});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      const CameraTab(),
      const UploadTab(),
      ProfileTab(email: widget.email),
      const SettingsTab(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('SnapDiet'),
        actions: [
          IconButton(
            tooltip: 'Logout',
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
                (_) => false,
              );
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.camera_alt), label: 'Camera'),
          NavigationDestination(
            icon: Icon(Icons.photo_library),
            label: 'Upload',
          ),
          NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
          NavigationDestination(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}

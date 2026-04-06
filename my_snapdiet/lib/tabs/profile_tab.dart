import 'package:flutter/material.dart';
import '../pages/profile_info_page.dart';
import '../pages/meal_log_page.dart';
import '../pages/progress_page.dart';

class ProfileTab extends StatefulWidget {
  final String email;
  const ProfileTab({super.key, required this.email});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          color: const Color.fromARGB(255, 229, 238, 231),
          child: TabBar(
            controller: _tabController,
            labelColor: Colors.black,
            indicatorColor: Colors.green,
            tabs: const [
              Tab(text: "Profile"),
              Tab(text: "Meal Log"),
              Tab(text: "Progress"),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              ProfileInfoPage(email: widget.email),
              const MealLogPage(),
              const ProgressPage(),
            ],
          ),
        ),
      ],
    );
  }
}

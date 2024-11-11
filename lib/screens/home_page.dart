import 'package:flutter/material.dart';

import '../components/custom_bottom_nav_bar.dart';

class HomePage extends StatefulWidget {
  static const String id = 'home_page';

  const HomePage({super.key});
  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  void _onTabSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });

    // Add navigation logic here based on the selected index
    // For example:
    switch (index) {
      case 0:
        // Navigate to Home
        break;
      case 1:
        // Navigate to Transaction
        break;
      case 2:
        // Navigate to Budget
        break;
      case 3:
        // Navigate to Profile
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text('Selected Page Index: $_selectedIndex'),
      ),
      bottomNavigationBar: CustomBottomNavBar(
        initialIndex: _selectedIndex,
        onTabSelected: _onTabSelected,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Handle FAB action
        },
        backgroundColor: Colors.purple,
        child: const Icon(Icons.add),
      ),
    );
  }
}

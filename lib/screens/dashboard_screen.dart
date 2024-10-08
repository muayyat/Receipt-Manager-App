import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../components/custom_drawer.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import 'profile_screen.dart';
import 'scan_screen.dart';

class DashboardScreen extends StatefulWidget {
  static const String id = 'dashboard_screen';

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  User? loggedInUser;

  String? userName = '';
  String? phoneNumber = '';
  String? city = '';
  String? country = '';
  File? profileImage;

  // Instantiate the UserService
  UserService userService = UserService();

  @override
  void initState() {
    super.initState();
    getCurrentUser();
  }

  void getCurrentUser() async {
    try {
      loggedInUser = await AuthService.getCurrentUser();
      if (loggedInUser != null) {
        loadProfileData();
      }
    } catch (e) {
      print(e);
    }
  }

  Future<void> loadProfileData() async {
    setState(() {
      // Optionally set a loading state if necessary
    });

    // Use the UserService to fetch the user profile
    userService.fetchUserProfile().listen((snapshot) {
      if (snapshot.exists) {
        setState(() {
          userName = snapshot.data()?['userName'] ?? 'No Name';
          phoneNumber = snapshot.data()?['phoneNumber'] ?? '';
          city = snapshot.data()?['city'] ?? '';
          country = snapshot.data()?['country'] ?? '';
          String? profileImagePath = snapshot.data()?['profileImagePath'];
          if (profileImagePath != null) {
            profileImage = File(profileImagePath);
          }
        });
      }
    });
  }

  Future<void> _navigateAndReloadSettings(BuildContext context) async {
    final result = await Navigator.pushNamed(context, ProfileScreen.id);
    if (result == true) {
      loadProfileData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('HOME'),
        backgroundColor: Colors.lightBlueAccent,
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
              icon: Icon(Icons.menu),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            );
          },
        ),
      ),
      drawer: CustomDrawer(),
      body: Center(
        child: Text(
          'Welcome to your dashboard, $userName!',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, ScanScreen.id);
        },
        child: Icon(Icons.camera_alt),
        backgroundColor: Colors.lightBlueAccent,
      ),
    );
  }
}

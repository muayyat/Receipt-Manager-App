import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../components/custom_drawer.dart';
import 'profile_screen.dart';
import 'scan_screen.dart';

class DashboardScreen extends StatefulWidget {
  static const String id = 'dashboard_screen';

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _auth = FirebaseAuth.instance;
  User? loggedInUser;
  String? userName = '';
  String? city = '';
  String? country = '';
  File? profileImage;

  @override
  void initState() {
    super.initState();
    getCurrentUser();
  }

  void getCurrentUser() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        loggedInUser = user;
        loadProfileData();
      }
    } catch (e) {
      print(e);
    }
  }

  Future<void> loadProfileData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userName =
          prefs.getString('userName') ?? loggedInUser?.displayName ?? 'No Name';
      city = prefs.getString('city') ?? 'No City';
      country = prefs.getString('country') ?? 'No Country';
      String? profileImagePath = prefs.getString('profileImagePath');
      if (profileImagePath != null) {
        profileImage = File(profileImagePath);
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

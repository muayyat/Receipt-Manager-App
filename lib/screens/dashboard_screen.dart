import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'profile_screen.dart';
import 'receipt_list_screen.dart';
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
      drawer: Drawer(
        child: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              UserAccountsDrawerHeader(
                margin: EdgeInsets.zero,
                decoration: BoxDecoration(
                  color: Colors.lightBlueAccent,
                ),
                currentAccountPicture: Padding(
                  padding: const EdgeInsets.only(
                      bottom: 10.0), // Adjust padding as needed
                  child: CircleAvatar(
                    radius:
                        50.0, // Increase this value to make the picture larger
                    backgroundColor: Colors.white,
                    backgroundImage:
                        profileImage != null ? FileImage(profileImage!) : null,
                    child: profileImage == null
                        ? Icon(
                            Icons.person,
                            size:
                                30.0, // Set a reasonable size for the icon inside the larger CircleAvatar
                            color: Colors.grey,
                          )
                        : null,
                  ),
                ),
                accountName: Row(
                  children: [
                    Expanded(
                      child: Text(
                        userName ?? 'No Name',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                          height: 1.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                accountEmail: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$city, $country',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black,
                        height: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4),
                    Text(
                      loggedInUser?.email ?? 'No Email',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black,
                        height: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              ListTile(
                leading: Icon(Icons.home),
                title: Text('Home'),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Icon(Icons.receipt),
                title: Text('Receipts'),
                onTap: () {
                  Navigator.pushNamed(context, ReceiptListScreen.id);
                },
              ),
              ListTile(
                leading: Icon(Icons.settings),
                title: Text('Profile'),
                onTap: () {
                  _navigateAndReloadSettings(context);
                },
              ),
              ListTile(
                leading: Icon(Icons.logout),
                title: Text('Logout'),
                onTap: () {
                  _auth.signOut();
                  Navigator.pushReplacementNamed(context, 'login_screen');
                },
              ),
            ],
          ),
        ),
      ),
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

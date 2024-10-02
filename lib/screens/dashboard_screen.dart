import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'scan_screen.dart';
import 'receipt_list_screen.dart';
import 'settings_screen.dart';

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
      userName = prefs.getString('userName') ?? loggedInUser?.displayName ?? 'No Name';
      city = prefs.getString('city') ?? 'No City';
      country = prefs.getString('country') ?? 'No Country';
      String? profileImagePath = prefs.getString('profileImagePath');
      if (profileImagePath != null) {
        profileImage = File(profileImagePath);
      }
    });
  }

  Future<void> _navigateAndReloadSettings(BuildContext context) async {
    final result = await Navigator.pushNamed(context, SettingsScreen.id);
    if (result == true) {
      loadProfileData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard'),
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
              Container(
                child: UserAccountsDrawerHeader(
                  margin: EdgeInsets.zero,
                  accountName: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 8),
                      Text(
                        userName ?? 'No Name',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 5),
                      Flexible(
                        child: Text(
                          '$city, $country',
                          style: TextStyle(fontSize: 14, color: Colors.white),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  accountEmail: Padding(
                    padding: const EdgeInsets.only(top: 5.0),
                    child: Text(
                      loggedInUser?.email ?? 'No Email',
                      style: TextStyle(fontSize: 14, color: Colors.white),
                    ),
                  ),
                  currentAccountPicture: CircleAvatar(
                    backgroundColor: Colors.white,
                    backgroundImage:
                    profileImage != null ? FileImage(profileImage!) : null,
                    child: profileImage == null
                        ? Icon(
                      Icons.person,
                      size: 50,
                    )
                        : null,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.lightBlueAccent,
                  ),
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
                title: Text('Settings'),
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

import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:receipt_manager/screens/dashboard_screen.dart';
import 'package:receipt_manager/screens/expense_chart_screen.dart';
import 'package:receipt_manager/screens/profile_screen.dart';

import '../screens/budget_screen.dart';
import '../screens/category_screen.dart';
import '../screens/receipt_list_screen.dart';
import '../screens/setting_screen.dart';
import '../screens/summary_screen.dart';
import '../screens/welcome_page.dart';
import '../services/user_service.dart';

class CustomDrawer extends StatefulWidget {
  const CustomDrawer({super.key});

  @override
  CustomDrawerState createState() => CustomDrawerState();
}

class CustomDrawerState extends State<CustomDrawer> {
  final UserService _userService = UserService();
  String? userName;
  String? city;
  String? country;
  File? profileImage;

  @override
  void initState() {
    super.initState();
    _userService.getCurrentUser();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _userService.fetchUserProfile(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        }

        if (snapshot.hasError) {
          return Text('Error fetching user data');
        }

        if (snapshot.hasData && snapshot.data!.data() != null) {
          final userData = snapshot.data!.data();
          userName = userData?['userName'] ?? '';
          city = userData?['city'] ?? '';
          country = userData?['country'] ?? '';
          final profileImagePath = userData?['profileImagePath'];
          if (profileImagePath != null) {
            profileImage = File(profileImagePath);
          }
        }

        return Drawer(
          child: SingleChildScrollView(
            child: Column(
              children: <Widget>[
                UserAccountsDrawerHeader(
                  margin: EdgeInsets.zero,
                  decoration: BoxDecoration(
                    color: Colors.lightBlueAccent,
                  ),
                  currentAccountPicture: Padding(
                    padding: const EdgeInsets.only(bottom: 10.0),
                    child: CircleAvatar(
                      radius: 50.0,
                      backgroundColor: Colors.white,
                      backgroundImage: profileImage != null
                          ? FileImage(profileImage!)
                          : null,
                      child: profileImage == null
                          ? Icon(
                              Icons.person,
                              size: 30.0,
                              color: Colors.grey,
                            )
                          : null,
                    ),
                  ),
                  accountName: Row(
                    children: [
                      Expanded(
                        child: Text(
                          (userName?.isNotEmpty == true
                                  ? userName
                                  : 'Your Name') ??
                              'Your Name',
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
                        '${city?.isNotEmpty == true ? city : 'Your City'}, ${country?.isNotEmpty == true ? country : 'Your Country'}',
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
                        _userService.loggedInUser?.email ?? 'No Email',
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
                  title: Text('Dashboard'),
                  onTap: () {
                    Navigator.pushNamed(context, DashboardScreen.id);
                  },
                ),
                ListTile(
                  leading: Icon(Icons.receipt),
                  title: Text('My Receipts'),
                  onTap: () {
                    Navigator.pushNamed(context, ReceiptListScreen.id);
                  },
                ),
                ListTile(
                  leading: Icon(Icons.category),
                  title: Text('Manage Categories'),
                  onTap: () {
                    Navigator.pushNamed(context, CategoryScreen.id);
                  },
                ),
                ListTile(
                  leading: Icon(Icons.savings),
                  title: Text('Budget Planner'),
                  onTap: () {
                    Navigator.pushNamed(context, BudgetScreen.id);
                  },
                ),
                ListTile(
                  leading: Icon(Icons.analytics),
                  title: Text('Monthly Overview'),
                  onTap: () {
                    Navigator.pushNamed(context, SummaryScreen.id);
                  },
                ),
                ListTile(
                  leading: Icon(Icons.bar_chart),
                  title: Text('Expense Analytics'),
                  onTap: () {
                    Navigator.pushNamed(context, ExpenseChartScreen.id);
                  },
                ),
                ListTile(
                  leading: Icon(Icons.person),
                  title: Text('My Profile'),
                  onTap: () {
                    Navigator.pushNamed(context, ProfileScreen.id);
                  },
                ),
                ListTile(
                  leading: Icon(Icons.settings),
                  title: Text('Settings'),
                  onTap: () {
                    Navigator.pushNamed(context, SettingScreen.id);
                  },
                ),
                ListTile(
                  leading: Icon(Icons.logout),
                  title: Text('Sign Out'),
                  onTap: () {
                    FirebaseAuth.instance.signOut();
                    Navigator.pushReplacementNamed(context, WelcomePage.id);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../components/custom_drawer.dart';
import '../logger.dart';
import '../services/auth_service.dart';
import '../services/receipt_service.dart';
import '../services/user_service.dart';
import 'scan_screen.dart';

class DashboardScreen extends StatefulWidget {
  static const String id = 'dashboard_screen';

  const DashboardScreen({super.key});

  @override
  DashboardScreenState createState() => DashboardScreenState();
}

class DashboardScreenState extends State<DashboardScreen> {
  User? loggedInUser;

  String? userName = '';
  String? phoneNumber = '';
  String? city = '';
  String? country = '';
  File? profileImage;

  // Variables to store receipt date range
  DateTime? _oldestDate;
  DateTime? _newestDate;

  UserService userService = UserService();
  ReceiptService receiptService = ReceiptService();

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
        fetchReceiptDates(); // Fetch receipt date range
      }
    } catch (e) {
      logger.e(e);
    }
  }

  Future<void> fetchReceiptDates() async {
    try {
      Map<String, DateTime> dateRange =
          await receiptService.getOldestAndNewestDates();
      setState(() {
        _oldestDate = dateRange['oldest'];
        _newestDate = dateRange['newest'];
      });
    } catch (e) {
      logger.e('Error fetching oldest and newest dates: $e');
    }
  }

  Future<void> loadProfileData() async {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home'),
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              userName != null && userName!.isNotEmpty
                  ? 'Welcome 🥳, $userName!'
                  : 'Welcome 🥳',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            _oldestDate != null && _newestDate != null
                ? Text(
                    'Your receipts span from ${DateFormat('yyyy-MM-dd').format(_oldestDate!)} to ${DateFormat('yyyy-MM-dd').format(_newestDate!)}.',
                    style: TextStyle(fontSize: 16),
                  )
                : CircularProgressIndicator(), // Show loading while fetching dates
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, ScanScreen.id);
        },
        backgroundColor: Colors.lightBlueAccent,
        child: Icon(Icons.camera_alt),
      ),
    );
  }
}

import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../components/custom_drawer.dart';
import '../services/user_service.dart';

class ProfileScreen extends StatefulWidget {
  static const String id = 'profile_screen';

  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? userName = '';
  String? phoneNumber = '';
  String? city = '';
  String? country = '';
  File? profileImage;
  bool isEditing = false;
  bool isSaving = false; // To indicate that saving is in progress

  final ImagePicker _picker = ImagePicker();
  final UserService _userService = UserService();

  // Controllers for text fields
  late TextEditingController _userNameController;
  late TextEditingController _phoneController;
  late TextEditingController _cityController;
  late TextEditingController _countryController;

  @override
  void initState() {
    super.initState();
    _userNameController = TextEditingController();
    _phoneController = TextEditingController();
    _cityController = TextEditingController();
    _countryController = TextEditingController();
    loadProfileData(); // Load the profile data using the service
  }

  @override
  void dispose() {
    _userNameController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  Future<void> loadProfileData() async {
    // Subscribe to the Firestore stream to get the latest profile data
    _userService
        .fetchUserProfile()
        .listen((DocumentSnapshot<Map<String, dynamic>> snapshot) {
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

          // Initialize controllers with the loaded data
          _userNameController.text = userName!;
          _phoneController.text = phoneNumber!;
          _cityController.text = city!;
          _countryController.text = country!;
        });
      }
    });
  }

  Future<void> saveProfileData() async {
    try {
      setState(() {
        isSaving = true; // Start saving
      });

      // Save the profile data using the UserService
      await _userService.updateUserProfile(
        userName: _userNameController.text,
        phoneNumber: _phoneController.text,
        city: _cityController.text,
        country: _countryController.text,
        profileImagePath: profileImage?.path,
      );

      // Simulate a delay to show saving process for feedback
      await Future.delayed(Duration(seconds: 1));

      setState(() {
        isSaving = false; // Stop spinner
        isEditing = false; // Disable editing after saving
      });

      // Display a message or some feedback
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profile updated successfully!')),
      );

      // Return to Dashboard and reload data
      Navigator.pop(context, true); // Return true to indicate changes were made
    } catch (e) {
      setState(() {
        isSaving = false; // Stop spinner if there was an error
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving profile: $e')),
      );
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        profileImage = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
        backgroundColor: Colors.lightBlueAccent,
      ),
      drawer: CustomDrawer(),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Center(
                  child: GestureDetector(
                    onTap: isEditing ? _pickImage : null,
                    child: CircleAvatar(
                      backgroundColor: Colors.grey,
                      backgroundImage: profileImage != null
                          ? FileImage(profileImage!)
                          : null,
                      radius: 50.0,
                      child: profileImage == null
                          ? Icon(Icons.person, size: 50, color: Colors.white)
                          : null,
                    ),
                  ),
                ),
                SizedBox(height: 20),
                // Form fields
                TextField(
                  enabled: isEditing, // Only enabled in edit mode
                  controller: _userNameController,
                  decoration: InputDecoration(labelText: 'Name'),
                ),
                SizedBox(height: 10),
                TextField(
                  enabled: isEditing,
                  controller: _phoneController,
                  decoration: InputDecoration(labelText: 'Phone Number'),
                  keyboardType: TextInputType.phone,
                ),
                SizedBox(height: 10),
                TextField(
                  enabled: isEditing,
                  controller: _cityController,
                  decoration: InputDecoration(labelText: 'City'),
                ),
                SizedBox(height: 10),
                TextField(
                  enabled: isEditing,
                  controller: _countryController,
                  decoration: InputDecoration(labelText: 'Country'),
                ),
                SizedBox(height: 30),
                // Save/Cancel button
                isEditing
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ElevatedButton(
                            onPressed: isSaving
                                ? null
                                : saveProfileData, // Disable if saving
                            child: isSaving
                                ? Row(
                                    children: [
                                      CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                      SizedBox(width: 8),
                                      Text('Saving...'),
                                    ],
                                  )
                                : Text('Save'),
                          ),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                isEditing = false; // Cancel edit
                              });
                            },
                            child: Text('Cancel'),
                          ),
                        ],
                      )
                    : ElevatedButton(
                        onPressed: () {
                          setState(() {
                            isEditing = true; // Enable editing
                          });
                        },
                        child: Text('Edit'),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

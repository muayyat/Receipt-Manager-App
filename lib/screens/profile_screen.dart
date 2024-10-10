import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../components/custom_drawer.dart';
import '../components/rounded_button.dart'; // Import the RoundedButton widget
import '../services/user_service.dart';

class ProfileScreen extends StatefulWidget {
  static const String id = 'profile_screen';

  const ProfileScreen({super.key});

  @override
  ProfileScreenState createState() => ProfileScreenState();
}

class ProfileScreenState extends State<ProfileScreen> {
  String? userName = '';
  String? phoneNumber = '';
  String? city = '';
  String? country = '';
  File? profileImage;
  bool isEditing = false;
  bool isSaving = false;

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
    loadProfileData();
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
    _userService.fetchUserProfile().listen((snapshot) {
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

          _userNameController.text = userName!;
          _phoneController.text = phoneNumber!;
          _cityController.text = city!;
          _countryController.text = country!;
        });
      }
    });
  }

  Future<void> saveProfileData() async {
    setState(() {
      isSaving = true;
    });

    try {
      await _userService.updateUserProfile(
        userName: _userNameController.text,
        phoneNumber: _phoneController.text,
        city: _cityController.text,
        country: _countryController.text,
        profileImagePath: profileImage?.path,
      );

      await Future.delayed(Duration(seconds: 1));

      setState(() {
        isSaving = false;
        isEditing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profile updated successfully!')),
      );

      Navigator.pop(context, true);
    } catch (e) {
      setState(() {
        isSaving = false;
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
        title: Text('Your Profile'),
        backgroundColor: Colors.lightBlueAccent,
      ),
      drawer: CustomDrawer(),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: <Widget>[
            Center(
              child: GestureDetector(
                onTap: isEditing ? _pickImage : null,
                child: CircleAvatar(
                  backgroundColor: Colors.grey,
                  backgroundImage:
                      profileImage != null ? FileImage(profileImage!) : null,
                  radius: 50.0,
                  child: profileImage == null
                      ? Icon(Icons.person, size: 50, color: Colors.white)
                      : null,
                ),
              ),
            ),
            SizedBox(height: 20),
            TextField(
              enabled: isEditing,
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
            isEditing
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: RoundedButton(
                          color: Colors.blueAccent,
                          title: 'Save',
                          onPressed: saveProfileData,
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: RoundedButton(
                          color: Colors.grey,
                          title: 'Cancel',
                          onPressed: () {
                            setState(() {
                              isEditing = false;
                            });
                          },
                        ),
                      ),
                    ],
                  )
                : Expanded(
                    child: RoundedButton(
                      color: Colors.blueAccent,
                      title: 'Edit',
                      onPressed: () {
                        setState(() {
                          isEditing = true;
                        });
                      },
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

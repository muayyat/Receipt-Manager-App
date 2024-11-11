import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:receipt_manager/screens/verification_link_page.dart';

import '../components/custom_button.dart';
import '../components/underline_text.dart';
import '../constants/app_colors.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart'; // Add UserService import
import 'login_page.dart';

class SignUpPage extends StatefulWidget {
  static const String id = 'sign_up_page';

  const SignUpPage({super.key});

  @override
  SignUpPageState createState() => SignUpPageState();
}

class SignUpPageState extends State<SignUpPage> {
  bool _isChecked = false;
  bool _isPasswordVisible = false; // Track password visibility
  String email = '';
  String password = '';
  String userName = '';
  String errorMessage = ''; // To display errors

  final TapGestureRecognizer _loginRecognizer = TapGestureRecognizer();
  final TextEditingController _userNameController = TextEditingController();

  // Create an instance of UserService
  final UserService _userService = UserService();

  // Function to extract error message from FirebaseAuthException
  String extractErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'weak-password':
        return 'The password is too weak. Please choose a stronger password.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      default:
        return 'An unexpected error occurred. Please try again.';
    }
  }

  @override
  void dispose() {
    _loginRecognizer.dispose();
    _userNameController.dispose();
    super.dispose();
  }

  Future<void> _registerUser() async {
    if (!_isChecked) return;

    try {
      setState(() {
        errorMessage = ''; // Clear previous errors
      });

      // Register the user using AuthService
      final newUser = await AuthService.registerWithEmail(email, password);

      if (newUser != null) {
        // Send email verification
        await newUser.sendEmailVerification();

        // Save username to the profile using UserService
        await _userService.addUserProfile(
          userEmail: email,
          userName: userName,
        );

        // Navigate to verification link page
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VerificationLinkPage(
              user: newUser,
            ),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        errorMessage = extractErrorMessage(e);
      });
    } catch (e) {
      setState(() {
        errorMessage = 'An error occurred. Please try again later.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundBaseColor,
      appBar: AppBar(
        backgroundColor: backgroundBaseColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textPrimaryColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          "Sign Up",
          style: TextStyle(
            color: textPrimaryColor,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 20),
              TextFormField(
                controller: _userNameController,
                onChanged: (value) {
                  userName = value;
                },
                decoration: InputDecoration(
                  labelText: "Name",
                  labelStyle: TextStyle(color: textSecondaryColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16.0),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16.0),
                    borderSide: BorderSide(color: mainPurpleColor),
                  ),
                ),
              ),
              SizedBox(height: 16),
              TextFormField(
                onChanged: (value) {
                  email = value;
                },
                decoration: InputDecoration(
                  labelText: "Email",
                  labelStyle: TextStyle(color: textSecondaryColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16.0),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16.0),
                    borderSide: BorderSide(color: mainPurpleColor),
                  ),
                ),
              ),
              SizedBox(height: 16),
              TextFormField(
                onChanged: (value) {
                  password = value;
                },
                obscureText: !_isPasswordVisible, // Toggle password visibility
                decoration: InputDecoration(
                  labelText: "Password",
                  labelStyle: TextStyle(color: textSecondaryColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16.0),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16.0),
                    borderSide: BorderSide(color: mainPurpleColor),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: Colors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  ),
                ),
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Checkbox(
                    value: _isChecked,
                    onChanged: (value) {
                      setState(() {
                        _isChecked = value ?? false;
                      });
                    },
                    activeColor: mainPurpleColor,
                  ),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        text: "By signing up, you agree to the ",
                        style: TextStyle(color: Colors.black, fontSize: 14),
                        children: [
                          TextSpan(
                            text: "Terms of Service",
                            style: TextStyle(color: mainPurpleColor),
                          ),
                          TextSpan(
                            text: " and ",
                            style: TextStyle(color: Colors.black),
                          ),
                          TextSpan(
                            text: "Privacy Policy",
                            style: TextStyle(color: mainPurpleColor),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              if (errorMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text(
                    errorMessage,
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              SizedBox(height: 20),
              CustomButton(
                text: "Sign Up",
                backgroundColor: _isChecked ? mainPurpleColor : Colors.grey,
                textColor: _isChecked ? backgroundBaseColor : Colors.black54,
                onPressed: _isChecked
                    ? () async {
                        await _registerUser();
                      }
                    : () {}, // No-op function when unchecked
              ),
              SizedBox(height: 16),
              Center(
                child: Text(
                  "Or with",
                  style: TextStyle(
                    color: textSecondaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              SizedBox(height: 16),
              Center(
                child: Text.rich(
                  TextSpan(
                    text: "Already have an account? ",
                    style: TextStyle(color: textSecondaryColor, fontSize: 16),
                    children: [
                      underlineTextSpan(
                        text: "Login",
                        onTap: () {
                          Navigator.pushNamed(context, LogInPage.id);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

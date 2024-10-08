import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:receipt_manager/screens/welcome_screen.dart';
import 'package:receipt_manager/services/auth_service.dart';

import '../components/rounded_button.dart';
import '../constants.dart';

class RegistrationScreen extends StatefulWidget {
  static const String id = 'registration_screen';

  const RegistrationScreen({super.key});
  @override
  _RegistrationScreenState createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  late String email;
  late String password;
  bool showPassword = false; // State to toggle password visibility
  String errorMessage = ''; // Variable to store error messages

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Container(
                height: 200.0,
                child: Image.asset('images/logo.png'),
              ),
              SizedBox(height: 48.0),
              TextField(
                onChanged: (value) {
                  email = value;
                },
                decoration: kTextFieldDecoration(hintText: 'Enter your email'),
              ),
              SizedBox(height: 8.0),
              TextField(
                onChanged: (value) {
                  password = value;
                },
                obscureText: !showPassword, // Toggle password visibility
                decoration: kTextFieldDecoration(
                  hintText: 'Enter your password',
                  suffixIcon: IconButton(
                    icon: Icon(
                      showPassword ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        showPassword = !showPassword;
                      });
                    },
                  ),
                ),
              ),
              SizedBox(height: 24.0),
              // Error message display
              if (errorMessage.isNotEmpty)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    errorMessage,
                    style: TextStyle(color: Colors.red, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ),
              RoundedButton(
                color: Colors.blueAccent,
                title: 'Register',
                onPressed: () async {
                  setState(() {
                    errorMessage = ''; // Clear the error message
                  });

                  try {
                    final newUser = await AuthService.registerWithEmail(
                      email,
                      password,
                    );

                    if (newUser != null) {
                      // Send verification email
                      await newUser.sendEmailVerification();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              'Verification email sent! Please check your inbox.'),
                        ),
                      );

                      // Sign out the user after registration
                      await AuthService.signOut();

                      // Navigate to the welcome screen
                      Navigator.pushNamed(context, WelcomeScreen.id);
                    }
                  } on FirebaseAuthException catch (e) {
                    setState(() {
                      errorMessage = extractErrorMessage(e);
                    });
                  } catch (e) {
                    setState(() {
                      errorMessage =
                          'An error occurred. Please try again later.';
                    });
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

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
}

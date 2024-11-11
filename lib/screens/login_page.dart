import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:receipt_manager/constants/app_colors.dart'; // Replace with your color definitions file
import 'package:receipt_manager/screens/receipt_list_screen.dart'; // Replace with actual receipt list screen file
import 'package:receipt_manager/screens/signup_page.dart';
import 'package:receipt_manager/services/auth_service.dart';

class LogInPage extends StatefulWidget {
  static const String id = 'login_page';

  const LogInPage({super.key});

  @override
  LogInPageState createState() => LogInPageState();
}

class LogInPageState extends State<LogInPage> {
  bool _isPasswordVisible = false;
  String email = '';
  String password = '';
  String errorMessage = '';

  // Method to extract error message from FirebaseAuthException
  String extractErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      default:
        return 'An unexpected error occurred. Please try again later.';
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
          "Login",
          style: TextStyle(
            color: textPrimaryColor,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 20),
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
            if (errorMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  errorMessage,
                  style: TextStyle(color: Colors.red, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                setState(() {
                  errorMessage = ''; // Clear the error message
                });

                try {
                  final user =
                      await AuthService.signInWithEmail(email, password);

                  if (user != null) {
                    // Check if the email is verified
                    if (user.emailVerified) {
                      // Use a post-frame callback to handle navigation outside of async context
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) {
                          Navigator.pushNamed(context, ReceiptListScreen.id);
                        }
                      });
                    } else {
                      // Sign out if email is not verified
                      await AuthService.signOut();
                      if (mounted) {
                        setState(() {
                          errorMessage =
                              'Please verify your email before logging in.';
                        });
                      }
                    }
                  }
                } on FirebaseAuthException catch (e) {
                  if (mounted) {
                    setState(() {
                      errorMessage = extractErrorMessage(e);
                    });
                  }
                } catch (e) {
                  if (mounted) {
                    setState(() {
                      errorMessage =
                          'An error occurred. Please try again later.';
                    });
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: mainPurpleColor,
                minimumSize: Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                "Login",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(height: 16),
            Center(
              child: TextButton(
                onPressed: () {
                  // Implement password reset functionality
                  if (email.isEmpty) {
                    setState(() {
                      errorMessage =
                          'Please enter your email to reset the password.';
                    });
                  } else {
                    try {
                      AuthService.sendPasswordResetEmail(email: email);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              'Password reset email sent! Please check your inbox.'),
                        ),
                      );
                    } catch (e) {
                      setState(() {
                        errorMessage =
                            'An error occurred. Please try again later.';
                      });
                    }
                  }
                },
                child: Text(
                  "Forgot Password?",
                  style: TextStyle(
                    color: mainPurpleColor,
                    fontSize: 16,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
            SizedBox(height: 8),
            Center(
              child: Text.rich(
                TextSpan(
                  text: "Don’t have an account yet? ",
                  style: TextStyle(color: textSecondaryColor, fontSize: 16),
                  children: [
                    TextSpan(
                      text: "Sign Up",
                      style: TextStyle(
                        color: mainPurpleColor,
                        fontSize: 16,
                        decoration: TextDecoration.underline,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () {
                          Navigator.pushNamed(context, SignUpPage.id);
                        },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

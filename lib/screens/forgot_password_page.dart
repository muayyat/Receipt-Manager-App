import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:receipt_manager/constants/app_colors.dart'; // Replace with your color definitions file

class ForgotPasswordPage extends StatefulWidget {
  static const String id = 'forgot_password_page';

  const ForgotPasswordPage({super.key});

  @override
  ForgotPasswordPageState createState() => ForgotPasswordPageState();
}

class ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final TextEditingController _emailController = TextEditingController();
  String errorMessage = '';

  // Method to handle password reset
  Future<void> _resetPassword() async {
    setState(() {
      errorMessage = ''; // Clear any previous error message
    });

    try {
      await FirebaseAuth.instance
          .sendPasswordResetEmail(email: _emailController.text.trim());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Password reset email sent! Please check your inbox.'),
        ),
      );
    } catch (e) {
      setState(() {
        errorMessage = 'Error: ${e.toString()}';
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
          "Forgot Password",
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
            SizedBox(height: 40),
            Text(
              "Don’t worry.",
              style: TextStyle(
                color: textPrimaryColor,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              "Enter your email and we’ll send you a link to reset your password.",
              style: TextStyle(
                color: textSecondaryColor,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 24),
            TextFormField(
              controller: _emailController,
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
              onPressed: () {
                if (_emailController.text.isEmpty) {
                  setState(() {
                    errorMessage = 'Please enter your email address.';
                  });
                } else {
                  _resetPassword();
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
                "Continue",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:receipt_manager/screens/receipt_list_screen.dart';
import 'package:receipt_manager/services/auth_service.dart';

import '../components/rounded_button.dart';
import '../constants/decorations.dart';

class LoginScreen extends StatefulWidget {
  static const String id = 'login_screen';

  const LoginScreen({super.key});

  @override
  LoginScreenState createState() => LoginScreenState();
}

class LoginScreenState extends State<LoginScreen> {
  late String email;
  late String password;
  bool showPassword = false;
  String errorMessage = ''; // Variable to store error messages

  void _resetPassword() async {
    try {
      await AuthService.sendPasswordResetEmail(email: email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Password reset email sent! Please check your inbox.'),
          ),
        );
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error: ${e.toString()}';
      });
    }
  }

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
              SizedBox(
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
                color: Colors.lightBlueAccent,
                title: 'Log In',
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
              ),
              SizedBox(height: 20),
              // Forgot Password Row
              GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text('Reset Password'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextField(
                              onChanged: (value) {
                                email = value;
                              },
                              decoration: InputDecoration(
                                  labelText: 'Enter your email'),
                            ),
                            SizedBox(height: 20),
                            if (errorMessage.isNotEmpty)
                              Text(
                                errorMessage,
                                style: TextStyle(color: Colors.red),
                              ),
                          ],
                        ),
                        actions: <Widget>[
                          TextButton(
                            onPressed: () {
                              _resetPassword();
                              Navigator.of(context).pop();
                            },
                            child: Text('Send Reset Link'),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: Text('Cancel'),
                          ),
                        ],
                      );
                    },
                  );
                },
                child: Text(
                  'Forgot Password?',
                  style: TextStyle(
                    color: Colors.blue,
                    fontSize: 16.0,
                    decoration: TextDecoration.underline,
                  ),
                  textAlign: TextAlign.center,
                ),
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
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'user-not-found':
        return 'No user found with this email. Please sign up first.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-credential':
        return 'Invalid credentials. Please check your details.';
      default:
        return 'An unexpected error occurred. Please try again.';
    }
  }
}

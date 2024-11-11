import 'package:flutter/material.dart';
import 'package:receipt_manager/screens/login_page.dart';

import '../components/custom_button.dart';
import '../constants/app_colors.dart';

class VerificationLinkPage extends StatelessWidget {
  static const String id = 'verification_link_page';
  final String email;

  const VerificationLinkPage({super.key, required this.email});

  String getMaskedEmail(String email) {
    // Mask part of the email for display
    final emailParts = email.split('@');
    final maskedName = '${emailParts[0].substring(0, 5)}*****';
    return '$maskedName@${emailParts[1]}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Verification',
          style: TextStyle(color: Colors.black),
        ),
        centerTitle: true,
      ),
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 32),
            // Title Text
            Text(
              'Get your\nVerification Link',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 40),
            // Countdown Timer Text
            Text(
              '04:59',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: lightPurpleColor,
              ),
            ),
            const SizedBox(height: 8),
            // Instructions and masked email
            RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: 14,
                  color: textPrimaryColor,
                ),
                children: [
                  TextSpan(text: 'We send verification link to your email '),
                  TextSpan(
                    text: getMaskedEmail(email),
                    style: TextStyle(color: lightPurpleColor),
                  ),
                  TextSpan(text: '. You can check your inbox.'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Resend link text
            GestureDetector(
              onTap: () {
                // Add logic to resend the link
              },
              child: Text(
                "I didn’t receive the link? Send again",
                style: TextStyle(
                  fontSize: 14,
                  color: lightPurpleColor,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
            Spacer(),
            // Continue Button
            CustomButton(
              text: "Continue",
              backgroundColor: mainPurpleColor,
              textColor: backgroundBaseColor,
              onPressed: () {
                // Navigate to the Log in page
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LogInPage(),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

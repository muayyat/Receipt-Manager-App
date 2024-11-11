import 'package:flutter/material.dart';
import 'package:receipt_manager/constants/app_colors.dart';
import 'package:receipt_manager/screens/login_page.dart';
import 'package:receipt_manager/screens/signup_page.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../components/custom_button.dart';

class WelcomePage extends StatefulWidget {
  static const String id = 'welcome_page';

  const WelcomePage({super.key});

  @override
  WelcomePageState createState() => WelcomePageState();
}

class WelcomePageState extends State<WelcomePage> {
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: PageView(
              controller: _pageController,
              children: [
                buildPage(
                  image: "assets/images/control.png",
                  title: "Gain total control of your money",
                  subtitle:
                      "Become your own money manager and make every cent count",
                ),
                buildPage(
                  image: "assets/images/track.png",
                  title: "Know where your money goes",
                  subtitle:
                      "Track your transaction easily, with categories and financial report",
                ),
                buildPage(
                  image: "assets/images/plan.png",
                  title: "Planning ahead",
                  subtitle:
                      "Setup your budget for each category so you stay in control",
                ),
              ],
            ),
          ),
          SmoothPageIndicator(
            controller: _pageController,
            count: 3,
            effect: WormEffect(
              dotColor: lightPurpleColor, // Inactive dot color
              activeDotColor: mainPurpleColor, // Active dot color
              dotHeight: 8,
              dotWidth: 8,
            ),
          ),
          SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              children: [
                CustomButton(
                  text: "Sign Up",
                  backgroundColor: mainPurpleColor,
                  textColor: backgroundBaseColor,
                  onPressed: () {
                    // Navigate to Sign Up page
                    Navigator.pushNamed(context, SignUpPage.id);
                  },
                ),
                SizedBox(height: 12),
                CustomButton(
                  text: "Login",
                  backgroundColor: lightPurpleColor,
                  textColor: mainPurpleColor,
                  onPressed: () {
                    // Navigate to Login page
                    Navigator.pushNamed(context, LogInPage.id);
                  },
                ),
              ],
            ),
          ),
          SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget buildPage(
      {required String image,
      required String title,
      required String subtitle}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(image, height: 250), // Image widget for the page's image
          SizedBox(height: 24),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 32,
                fontWeight: FontWeight.w700, // Use Bold
                color: textPrimaryColor),
          ),
          SizedBox(height: 16),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 16,
                fontWeight: FontWeight.w200, // Use ExtraLight
                color: textSecondaryColor),
          ),
        ],
      ),
    );
  }
}

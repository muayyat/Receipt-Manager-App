import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:receipt_manager/screens/login_screen.dart';
import 'package:receipt_manager/screens/registration_screen.dart';
import 'package:receipt_manager/screens/scan_screen.dart';
import 'package:receipt_manager/screens/welcome_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
      options: FirebaseOptions(
    apiKey: 'AIzaSyAi5hsdFqREf12wZTwadnVN3lK47we7tYU',
    appId: '1:770302644204:android:4e8a4cfa0c7cd7dc747ac9',
    messagingSenderId: '770302644204',
    projectId: 'receipt-manager-b3afe',
    storageBucket: 'receipt-manager-b3afe.appspot.com',
  ));
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      initialRoute: WelcomeScreen.id,
      routes: {
        WelcomeScreen.id: (context) => WelcomeScreen(),
        LoginScreen.id: (context) => LoginScreen(),
        RegistrationScreen.id: (context) => RegistrationScreen(),
        ScanScreen.id: (context) => ScanScreen(),
      },
    );
  }
}

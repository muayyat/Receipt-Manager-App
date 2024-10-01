import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:receipt_manager/screens/add_receipt_screen.dart';
import 'package:receipt_manager/screens/login_screen.dart';
import 'package:receipt_manager/screens/receipt_list_screen.dart';
import 'package:receipt_manager/screens/registration_screen.dart';
import 'package:receipt_manager/screens/scan_screen.dart';
import 'package:receipt_manager/screens/welcome_screen.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
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
        AddReceiptScreen.id: (context) => AddReceiptScreen(),
        ReceiptListScreen.id: (context) => ReceiptListScreen(),
      },
    );
  }
}

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:receipt_manager/screens/add_update_receipt_screen.dart';
import 'package:receipt_manager/screens/budget_screen.dart';
import 'package:receipt_manager/screens/category_screen.dart';
import 'package:receipt_manager/screens/dashboard_screen.dart';
import 'package:receipt_manager/screens/expense_chart_screen.dart';
import 'package:receipt_manager/screens/login_screen.dart';
import 'package:receipt_manager/screens/profile_screen.dart';
import 'package:receipt_manager/screens/receipt_list_screen.dart';
import 'package:receipt_manager/screens/registration_screen.dart';
import 'package:receipt_manager/screens/scan_screen.dart';
import 'package:receipt_manager/screens/set_budget_page.dart';
import 'package:receipt_manager/screens/setting_screen.dart';
import 'package:receipt_manager/screens/summary_screen.dart';
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
        AddOrUpdateReceiptScreen.id: (context) => AddOrUpdateReceiptScreen(),
        ReceiptListScreen.id: (context) => ReceiptListScreen(),
        CategoryScreen.id: (context) => CategoryScreen(),
        BudgetScreen.id: (context) => BudgetScreen(),
        SummaryScreen.id: (context) => SummaryScreen(),
        ExpenseChartScreen.id: (context) => ExpenseChartScreen(),
        DashboardScreen.id: (context) => DashboardScreen(),
        ProfileScreen.id: (context) => ProfileScreen(),
        SettingScreen.id: (context) => SettingScreen(),
        SetBudgetPage.id: (context) => SetBudgetPage(),
      },
    );
  }
}

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:receipt_manager/screens/add_update_receipt_screen.dart';
import 'package:receipt_manager/screens/budget_screen.dart';
import 'package:receipt_manager/screens/category_screen.dart';
import 'package:receipt_manager/screens/dashboard_screen.dart';
import 'package:receipt_manager/screens/expense_chart_screen.dart';
import 'package:receipt_manager/screens/forgot_password_page.dart';
import 'package:receipt_manager/screens/login_page.dart';
import 'package:receipt_manager/screens/profile_screen.dart';
import 'package:receipt_manager/screens/receipt_list_screen.dart';
import 'package:receipt_manager/screens/scan_screen.dart';
import 'package:receipt_manager/screens/set_budget_page.dart';
import 'package:receipt_manager/screens/setting_screen.dart';
import 'package:receipt_manager/screens/signup_page.dart';
import 'package:receipt_manager/screens/summary_screen.dart';
import 'package:receipt_manager/screens/welcome_page.dart';

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
      initialRoute: WelcomePage.id,
      routes: {
        WelcomePage.id: (context) => WelcomePage(),
        SignUpPage.id: (context) => SignUpPage(),
        LogInPage.id: (context) => LogInPage(),
        ForgotPasswordPage.id: (context) => ForgotPasswordPage(),
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
        // In development
        SetBudgetPage.id: (context) => SetBudgetPage(),
      },
    );
  }
}
